import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/driver_profile.dart';
import '../data/models/ride_request.dart';
import '../data/repositories/driver_repository.dart';

/// Manages driver profile state, shift toggle, and live ride requests.
class DriverProvider extends ChangeNotifier {
  DriverProvider({required DriverRepository driverRepository})
      : _driverRepo = driverRepository;

  final DriverRepository _driverRepo;

  // ── Profile state ──────────────────────────────────────────────────

  DriverProfile? _profile;
  bool _isLoadingProfile = false;
  String? _profileError;

  DriverProfile? get profile => _profile;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  /// Whether the driver is currently on shift (active).
  bool get isOnShift => _profile?.onShift ?? false;

  /// Whether the driver can toggle shift (approved + not toggling).
  bool get canToggle => _profile?.isApproved == true && !_isToggling;

  // ── Toggle shift state ─────────────────────────────────────────────

  bool _isToggling = false;
  String? _toggleError;

  bool get isToggling => _isToggling;
  String? get toggleError => _toggleError;

  // ── Ride requests state ────────────────────────────────────────────

  List<RideRequest> _rideRequests = [];
  bool _isLoadingRideRequests = false;
  String? _rideRequestsError;
  String? _acceptingId;
  String? _acceptError;
  final Set<String> _dismissed = {};
  StreamSubscription<RideStreamEvent>? _streamSub;
  Timer? _reconnectTimer;

  // ── Active ride state ──────────────────────────────────────────────

  RideRequest? _activeRide;
  bool _isLoadingActiveRide = false;
  String? _activeRideError;
  bool _isStartingTrip = false;
  bool _isCompletingTrip = false;

  List<RideRequest> get rideRequests => _rideRequests;
  bool get isLoadingRideRequests => _isLoadingRideRequests;
  String? get rideRequestsError => _rideRequestsError;
  String? get acceptError => _acceptError;
  bool get isStreaming => _streamSub != null;

  RideRequest? get activeRide => _activeRide;
  bool get hasActiveRide => _activeRide != null;
  bool get isLoadingActiveRide => _isLoadingActiveRide;
  String? get activeRideError => _activeRideError;
  bool get isStartingTrip => _isStartingTrip;
  bool get isCompletingTrip => _isCompletingTrip;

  bool isAccepting(String rideId) => _acceptingId == rideId;

  // ── Profile ────────────────────────────────────────────────────────

  /// Fetches the driver profile from the backend. When already on shift,
  /// (re)opens the live ride-request stream.
  Future<void> loadProfile() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      _profile = await _driverRepo.getProfile();
      if (_profile?.onShift ?? false) {
        _startStream();
      } else if (_streamSub != null || _reconnectTimer != null) {
        _stopStream();
        _rideRequests = [];
      }
    } on ApiException catch (e) {
      _profileError = e.message;
    } catch (_) {
      _profileError = 'تعذر تحميل بيانات السائق.';
    }

    _isLoadingProfile = false;
    notifyListeners();
  }

  // ── Toggle shift ───────────────────────────────────────────────────

  /// Toggles the driver's active/inactive (on-shift) state.
  Future<void> toggleShift() async {
    if (_profile == null || !canToggle) return;

    _isToggling = true;
    _toggleError = null;
    notifyListeners();

    try {
      final newOnShift = !_profile!.onShift;
      await _driverRepo.toggleShift(onShift: newOnShift);
      _profile = _profile!.copyWith(onShift: newOnShift);

      if (newOnShift) {
        _startStream();
      } else {
        _stopStream();
        _rideRequests = [];
        _isLoadingRideRequests = false;
      }
    } on ApiException catch (e) {
      _toggleError = e.message;
    } catch (_) {
      _toggleError = 'تعذر تغيير الحالة.';
    }

    _isToggling = false;
    notifyListeners();
  }

  // ── Ride requests ──────────────────────────────────────────────────

  /// Accepts a ride request, binding it to the current driver.
  /// Returns `true` when accepted successfully.
  Future<bool> acceptRideRequest(String rideRequestId) async {
    if (_acceptingId != null) return false;

    RideRequest? acceptedRide;
    for (final ride in _rideRequests) {
      if (ride.id == rideRequestId) {
        acceptedRide = ride;
        break;
      }
    }

    _acceptingId = rideRequestId;
    _acceptError = null;
    notifyListeners();

    try {
      await _driverRepo.acceptRideRequest(rideRequestId);
      _rideRequests.removeWhere((r) => r.id == rideRequestId);
      // The ride is now matched to this driver → become the active trip.
      if (acceptedRide != null) {
        _activeRide = acceptedRide;
        _activeRideError = null;
      }
      return true;
    } on ApiException catch (e) {
      // Only drop the request when it was genuinely lost to another driver
      // (410 GONE = RideAlreadyTaken). On transient errors keep it so the
      // driver can retry instead of silently losing a still-valid offer.
      if (e.isRideAlreadyTaken) {
        _rideRequests.removeWhere((r) => r.id == rideRequestId);
      }
      _acceptError = e.message;
      return false;
    } catch (_) {
      _acceptError = 'تعذر قبول الطلب.';
      return false;
    } finally {
      _acceptingId = null;
      notifyListeners();
    }
  }

  /// Removes a request from the driver's list (local only — the request
  /// stays available to other drivers on the server).
  void dismissRideRequest(String rideRequestId) {
    _dismissed.add(rideRequestId);
    _rideRequests.removeWhere((r) => r.id == rideRequestId);
    notifyListeners();
  }

  // ── Active ride ─────────────────────────────────────────────────────

  /// Fetches the driver's current active ride from the backend. A 404/410
  /// (no active ride) is treated as `null`.
  Future<void> loadActiveRide() async {
    if (_isLoadingActiveRide) return;
    _isLoadingActiveRide = true;
    _activeRideError = null;
    notifyListeners();

    try {
      _activeRide = await _driverRepo.getActiveRide();
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 410) {
        _activeRide = null;
      } else {
        _activeRideError = e.message;
      }
    } catch (_) {
      _activeRideError = 'تعذر تحميل الرحلة الحالية.';
    }

    _isLoadingActiveRide = false;
    notifyListeners();
  }

  /// Starts the current ride, notifying the passenger that the driver arrived.
  /// Returns `true` when the backend accepted the action.
  ///
  /// The MVP wires the "start trip" action to the driver-arrival report
  /// (`POST /api/v1/drivers/ride/{id}/arrived`): the backend broadcasts the
  /// live `driver_arrived` event to the passenger, and the ride is marked
  /// started locally. The dedicated `/start` endpoint is planned for later.
  Future<bool> startCurrentTrip() async {
    final ride = _activeRide;
    if (ride == null || _isStartingTrip) return false;

    _isStartingTrip = true;
    _activeRideError = null;
    notifyListeners();

    try {
      await _driverRepo.reportArrived(
        ride.id,
        pickupLatitude: ride.pickUpLat,
        pickupLongitude: ride.pickUpLng,
      );
      _activeRide = ride.copyWith(status: 'STARTED');
      return true;
    } on ApiException catch (e) {
      _activeRideError = _isPendingFeature(e)
          ? 'بدء الرحلة غير متاح حالياً.'
          : e.message;
      return false;
    } catch (_) {
      _activeRideError = 'تعذر بدء الرحلة.';
      return false;
    } finally {
      _isStartingTrip = false;
      notifyListeners();
    }
  }

  /// Completes the current ride, clearing it from the driver's screen.
  /// Returns `true` when the backend accepted the transition.
  Future<bool> completeCurrentTrip() async {
    final ride = _activeRide;
    if (ride == null || _isCompletingTrip) return false;

    _isCompletingTrip = true;
    _activeRideError = null;
    notifyListeners();

    try {
      await _driverRepo.completeRide(ride.id);
      _activeRide = null;
      return true;
    } on ApiException catch (e) {
      _activeRideError = _isPendingFeature(e)
          ? 'إنهاء الرحلة غير متاح حالياً.'
          : e.message;
      return false;
    } catch (_) {
      _activeRideError = 'تعذر إنهاء الرحلة.';
      return false;
    } finally {
      _isCompletingTrip = false;
      notifyListeners();
    }
  }

  /// Whether the failure is caused by a backend endpoint that has not been
  /// implemented yet (404/405/501). Those features are planned for later, so
  /// a neutral placeholder is shown instead of a confusing server error.
  bool _isPendingFeature(ApiException e) =>
      e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 501;

  void clearActiveRideError() {
    _activeRideError = null;
    notifyListeners();
  }

  // ── Live stream (SSE) ──────────────────────────────────────────────

  void _startStream() {
    if (_streamSub != null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Any in-progress trip should be restored when the stream (re)opens.
    unawaited(loadActiveRide());

    _streamSub = _driverRepo.streamRideRequests().listen(
          _handleStreamEvent,
          onError: (Object _) {
            _streamSub = null;
            notifyListeners();
            _scheduleReconnect();
          },
          onDone: () {
            _streamSub = null;
            notifyListeners();
            _scheduleReconnect();
          },
          cancelOnError: true,
        );
  }

  void _scheduleReconnect() {
    if (!isOnShift || _reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      if (!isOnShift) return;
      _startStream();
    });
  }

  void _stopStream() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _streamSub?.cancel();
    _streamSub = null;
  }

  void _handleStreamEvent(RideStreamEvent event) {
    switch (event.type) {
      case RideStreamEventType.snapshot:
        _rideRequests = (event.rides ?? const [])
            .where((r) => !_dismissed.contains(r.id))
            .toList();
        break;

      case RideStreamEventType.newRide:
        final ride = event.ride;
        if (ride != null &&
            !_dismissed.contains(ride.id) &&
            !_rideRequests.any((r) => r.id == ride.id)) {
          _rideRequests = [ride, ..._rideRequests];
        }
        break;

      case RideStreamEventType.rideTaken:
        final rideId = event.rideId;
        if (rideId != null) {
          _rideRequests.removeWhere((r) => r.id == rideId);
        }
        break;

      case RideStreamEventType.rideCancelled:
        final rideId = event.rideId;
        if (rideId != null) {
          _rideRequests.removeWhere((r) => r.id == rideId);
          if (_activeRide?.id == rideId) {
            _activeRide = null;
            _activeRideError = null;
          }
        }
        break;
    }
    notifyListeners();
  }

  // ── Error management ───────────────────────────────────────────────

  void clearToggleError() {
    _toggleError = null;
    notifyListeners();
  }

  void clearProfileError() {
    _profileError = null;
    notifyListeners();
  }

  void clearRideRequestsError() {
    _rideRequestsError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }
}