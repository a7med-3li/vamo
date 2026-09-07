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

  List<RideRequest> get rideRequests => _rideRequests;
  bool get isLoadingRideRequests => _isLoadingRideRequests;
  String? get rideRequestsError => _rideRequestsError;
  String? get acceptError => _acceptError;
  bool get isStreaming => _streamSub != null;

  bool isAccepting(String rideId) => _acceptingId == rideId;

  // ── Profile ────────────────────────────────────────────────────────

  /// Fetches the driver profile from the backend. When already on shift,
  /// (re)opens the live stream and refreshes the pending requests.
  Future<void> loadProfile() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      _profile = await _driverRepo.getProfile();
      if (_profile?.onShift ?? false) {
        _startStream();
        await loadRideRequests();
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
        await loadRideRequests();
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

  /// Loads the current pending ride requests (snapshot / pull-to-refresh).
  Future<void> loadRideRequests() async {
    if (!isOnShift) {
      _rideRequests = [];
      notifyListeners();
      return;
    }

    _isLoadingRideRequests = true;
    _rideRequestsError = null;
    notifyListeners();

    try {
      final list = await _driverRepo.getPendingRideRequests();
      _rideRequests = list.where((r) => !_dismissed.contains(r.id)).toList();
    } on ApiException catch (e) {
      _rideRequestsError = e.message;
    } catch (_) {
      _rideRequestsError = 'تعذر تحميل طلبات الركوب.';
    }

    _isLoadingRideRequests = false;
    notifyListeners();
  }

  /// Accepts a ride request, binding it to the current driver.
  /// Returns `true` when accepted successfully.
  Future<bool> acceptRideRequest(String rideRequestId) async {
    if (_acceptingId != null) return false;

    _acceptingId = rideRequestId;
    _acceptError = null;
    notifyListeners();

    try {
      await _driverRepo.acceptRideRequest(rideRequestId);
      _rideRequests.removeWhere((r) => r.id == rideRequestId);
      return true;
    } on ApiException catch (e) {
      // The request may have already been accepted by another driver.
      _rideRequests.removeWhere((r) => r.id == rideRequestId);
      _acceptError = e.message;
      return false;
    } catch (_) {
      _rideRequests.removeWhere((r) => r.id == rideRequestId);
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

  // ── Live stream (SSE) ──────────────────────────────────────────────

  void _startStream() {
    if (_streamSub != null) return;
    _streamSub = _driverRepo.streamRideRequests().listen(
          _handleStreamEvent,
          onError: (Object _) {
            _streamSub = null;
            notifyListeners();
          },
          onDone: () {
            _streamSub = null;
            notifyListeners();
          },
          cancelOnError: true,
        );
  }

  void _stopStream() {
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

      case RideStreamEventType.rideAccepted:
        final rideId = event.rideId;
        if (rideId != null && _acceptingId != rideId) {
          _rideRequests.removeWhere((r) => r.id == rideId);
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