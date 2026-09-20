import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/active_ride.dart';
import '../data/models/address_result.dart';
import '../data/models/passenger_ride_stream.dart';
import '../data/models/ride_option.dart';
import '../data/repositories/address_repository.dart';
import '../data/repositories/ride_repository.dart';

/// Encapsulates the result of resolving the passenger's current location.
class PickupLocation {
  const PickupLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Search state for a single address lane (pickup or dropoff): query results
/// from autocomplete / full search, plus the address the user pinned.
class AddressSearchState {
  int _token = 0;
  bool _isSearching = false;
  bool _resultsFromSearch = false;
  String? _searchError;
  List<AddressResult> _results = const [];
  AddressResult? _selected;

  int get token => _token;
  bool get isSearching => _isSearching;
  bool get resultsFromSearch => _resultsFromSearch;
  String? get searchError => _searchError;
  List<AddressResult> get results => _results;
  AddressResult? get selected => _selected;
  bool get hasResults => _results.isNotEmpty;
  bool get hasSelection => _selected != null;

  /// Marks the start of a new query and invalidates older in-flight replies.
  void beginSearch() {
    _token++;
    _isSearching = true;
    _resultsFromSearch = false;
    _searchError = null;
  }

  void finishSearch() {
    _isSearching = false;
  }

  void setResults(List<AddressResult> list, {required bool fromFullSearch}) {
    _results = list;
    _resultsFromSearch = fromFullSearch;
  }

  void setError(String message) {
    _results = const [];
    _resultsFromSearch = false;
    _searchError = message;
  }

  void select(AddressResult address) {
    _selected = address;
    _results = const [];
    _resultsFromSearch = false;
    _searchError = null;
    _isSearching = false;
    _token++;
  }

  void clearSelection() {
    _selected = null;
  }

  void clearResults() {
    _token++;
    _results = const [];
    _resultsFromSearch = false;
    _searchError = null;
    _isSearching = false;
  }
}

/// Manages the Book-a-Ride flow: two independent search lanes (pickup and
/// dropoff), each backed by autocomplete + full-search fallback, with the
/// device's current location offered as the pickup default when available.
class RideBookProvider extends ChangeNotifier {
  RideBookProvider({
    required AddressRepository addressRepository,
    RideRepository? rideRepository,
  })  : _addressRepo = addressRepository,
        _rideRepo = rideRepository ?? RideRepository(apiClient: ApiClient());

  final AddressRepository _addressRepo;
  final RideRepository _rideRepo;

  // ── Device location state (pickup default) ──────────────────────────
  bool _isLocating = false;
  PickupLocation? _deviceLocation;
  String? _locationError;

  // ── Search lanes ────────────────────────────────────────────────────
  final AddressSearchState _pickup = AddressSearchState();
  final AddressSearchState _dropoff = AddressSearchState();

  // ── Ride request state ──────────────────────────────────────────────
  List<RideOption>? _rideOptions;
  bool _isRequestingRide = false;
  String? _rideRequestError;
  RideOption? _selectedOption;
  bool _isPublishing = false;
  String? _publishError;
  bool _published = false;

  // ── Active ride tracking (post-publish) ─────────────────────────────
  // Live updates arrive over the passenger SSE stream: `ride_accepted`
  // when a driver accepts the request, `driver_arrived` when they reach
  // the pickup point.
  PassengerActiveRide? _activeRide;
  bool _isCheckingActiveRide = false;
  String? _activeRideError;
  bool _rideFinished = false;
  StreamSubscription<PassengerRideStreamEvent>? _rideStreamSub;
  Timer? _reconnectTimer;

  // ── Ride cancellation (post-publish) ────────────────────────────────
  bool _isCancelling = false;
  String? _cancelError;
  bool _rideCancelled = false;

  bool get isLocating => _isLocating;
  bool get isRequestingRide => _isRequestingRide;
  bool get hasRideOptions => _rideOptions != null && _rideOptions!.isNotEmpty;
  List<RideOption>? get rideOptions => _rideOptions;
  String? get rideRequestError => _rideRequestError;
  RideOption? get selectedOption => _selectedOption;
  bool get isPublishing => _isPublishing;
  String? get publishError => _publishError;
  bool get hasPublished => _published;
  PassengerActiveRide? get activeRide => _activeRide;
  bool get isCheckingActiveRide => _isCheckingActiveRide;
  String? get activeRideError => _activeRideError;
  bool get isCancelling => _isCancelling;
  String? get cancelError => _cancelError;

  /// Whether the published ride was cancelled by the passenger.
  bool get rideCancelled => _rideCancelled;

  /// Whether the published ride has completed (was active, now gone).
  bool get rideFinished => _rideFinished;
  PickupLocation? get deviceLocation => _deviceLocation;
  String? get locationError => _locationError;
  bool get hasDeviceLocation => _deviceLocation != null;

  /// Whether the passenger currently has an in-progress ride to show.
  bool get hasActiveTrip =>
      _activeRide != null && (_activeRide!.isMatched || _activeRide!.isStarted);

  AddressSearchState get pickupSearch => _pickup;
  AddressSearchState get dropoffSearch => _dropoff;
  AddressResult? get pickupSelected => _pickup.selected;
  AddressResult? get dropoffSelected => _dropoff.selected;

  bool get hasPickup => _pickup.hasSelection || hasDeviceLocation;
  bool get hasDropoff => _dropoff.hasSelection;
  bool get canRequestRide => hasPickup && hasDropoff;

  /// Coordinates to use as the ride pickup: the pinned address when the user
  /// searched for one, otherwise the device's current location.
  PickupLocation? get pickupCoordinates {
    final addr = _pickup.selected;
    if (addr != null && addr.lat != null && addr.lng != null) {
      return PickupLocation(latitude: addr.lat!, longitude: addr.lng!);
    }
    return _deviceLocation;
  }

  /// Display title for the ride pickup: the pinned address title, or a static
  /// label for the raw device GPS position.
  String get pickupTitle {
    final addr = _pickup.selected;
    final title = addr?.title ?? '';
    if (title.isNotEmpty) return title;
    final description = addr?.description ?? '';
    if (description.isNotEmpty) return description;
    return 'Your Current Location';
  }

  /// Display title for the ride drop-off (always a pinned address).
  String get dropoffTitle {
    final address = _dropoff.selected;
    if (address == null) return '';
    if (address.title.isNotEmpty) return address.title;
    return address.description;
  }

  /// Fetches the device's current location as the pickup default.
  Future<void> loadCurrentLocation() async {
    _isLocating = true;
    _locationError = null;
    notifyListeners();

    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const PickupLocationException('خدمة الموقع غير مفعلة على الجهاز.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const PickupLocationException('تم رفض الإذن بالوصول إلى الموقع.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw const PickupLocationException(
            'إذن الموقع مرفوض بشكل دائم. فعّله من إعدادات الجهاز.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _deviceLocation = PickupLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on PickupLocationException catch (e) {
      _locationError = e.message;
    } on ApiException catch (e) {
      _locationError = e.message;
    } catch (e) {
      debugPrint('⚠️ [RideBookProvider] location error: $e');
      _locationError = 'تعذر تحديد موقعك الحالي. حاول مرة أخرى.';
    }

    _isLocating = false;
    notifyListeners();
  }

  Future<void> autoCompletePickup(String query) =>
      _autoComplete(_pickup, query);
  Future<void> autoCompleteDropoff(String query) =>
      _autoComplete(_dropoff, query);
  Future<void> searchPickup(String query) => _fullSearch(_pickup, query);
  Future<void> searchDropoff(String query) => _fullSearch(_dropoff, query);

  /// Runs autocomplete for [query]. Cheap, fast — used while typing.
  Future<void> _autoComplete(AddressSearchState search, String query) async {
    _clearRideRequest();
    search.beginSearch();
    final token = search.token;
    notifyListeners();

    try {
      final list = await _addressRepo.autoComplete(query);
      if (token != search.token) return; // stale response
      search.setResults(list, fromFullSearch: false);
    } on ApiException catch (e) {
      if (token != search.token) return;
      search.setError(e.message);
    } catch (e) {
      if (token != search.token) return;
      debugPrint('⚠️ [RideBookProvider] autoComplete error: $e');
      search.setError('حدث خطأ أثناء البحث.');
    }

    search.finishSearch();
    notifyListeners();
  }

  /// Runs the full search for [query] (maps API). Called explicitly when
  /// autocomplete returned no results and the user taps the fallback button.
  Future<void> _fullSearch(AddressSearchState search, String query) async {
    _clearRideRequest();
    search.beginSearch();
    final token = search.token;
    notifyListeners();

    try {
      final list = await _addressRepo.search(query);
      if (token != search.token) return;
      search.setResults(list, fromFullSearch: true);
    } on ApiException catch (e) {
      if (token != search.token) return;
      search.setError(e.message);
    } catch (e) {
      if (token != search.token) return;
      debugPrint('⚠️ [RideBookProvider] search error: $e');
      search.setError('حدث خطأ أثناء البحث.');
    }

    search.finishSearch();
    notifyListeners();
  }

  void selectPickup(AddressResult address) {
    _pickup.select(address);
    _clearRideRequest();
    notifyListeners();
  }

  void selectDropoff(AddressResult address) {
    _dropoff.select(address);
    _clearRideRequest();
    notifyListeners();
  }

  void clearPickupSelection() {
    _pickup.clearSelection();
    _clearRideRequest();
    notifyListeners();
  }

  void clearDropoffSelection() {
    _dropoff.clearSelection();
    _clearRideRequest();
    notifyListeners();
  }

  void clearPickupSearch() {
    _pickup.clearResults();
    _clearRideRequest();
    notifyListeners();
  }

  void clearDropoffSearch() {
    _dropoff.clearResults();
    _clearRideRequest();
    notifyListeners();
  }

  void clear() {
    _pickup.clearResults();
    _pickup.clearSelection();
    _dropoff.clearResults();
    _dropoff.clearSelection();
    _deviceLocation = null;
    _locationError = null;
    _clearRideRequest();
    notifyListeners();
  }

  /// Requests ride options for the currently pinned pick-up and drop-off
  /// locations. No-op until both are fully pinned.
  Future<void> requestRide() async {
    final pickup = pickupCoordinates;
    final dropoff = _dropoff.selected;
    if (pickup == null ||
        dropoff == null ||
        dropoff.lat == null ||
        dropoff.lng == null) {
      return;
    }

    _isRequestingRide = true;
    _rideRequestError = null;
    _rideOptions = null;
    notifyListeners();

    try {
      final options = await _rideRepo.requestRide(
        pickupLatitude: pickup.latitude,
        pickupLongitude: pickup.longitude,
        pickupTitle: pickupTitle,
        dropoffLatitude: dropoff.lat!,
        dropoffLongitude: dropoff.lng!,
        dropoffTitle: dropoffTitle,
      );
      if (!_isRequestingRide) return; // cleared while the request was in flight
      // Drop empty stubs returned by the backend when a transport mode fails.
      _rideOptions = options
          .where((o) => o.duration > 0 || o.distance > 0)
          .toList(growable: false);
    } on ApiException catch (e) {
      if (!_isRequestingRide) return;
      _rideRequestError = e.message;
    } catch (e) {
      if (!_isRequestingRide) return;
      debugPrint('⚠️ [RideBookProvider] requestRide error: $e');
      _rideRequestError = 'تعذر الحصول على خيارات الرحلة. حاول مرة أخرى.';
    }

    _isRequestingRide = false;
    notifyListeners();
  }

  /// Selects the ride option the passenger wants to publish.
  void selectOption(RideOption option) {
    _selectedOption = option;
    _publishError = null;
    notifyListeners();
  }

  /// Publishes the selected ride option so drivers receive it in real time.
  /// No-op until an option has been selected and both locations are pinned.
  Future<void> publishRequest() async {
    final pickup = pickupCoordinates;
    final dropoff = _dropoff.selected;
    final option = _selectedOption;
    if (pickup == null ||
        dropoff == null ||
        dropoff.lat == null ||
        dropoff.lng == null ||
        option == null) {
      return;
    }

    _isPublishing = true;
    _publishError = null;
    notifyListeners();

    try {
      await _rideRepo.publishRideRequest(
        pickupLatitude: pickup.latitude,
        pickupLongitude: pickup.longitude,
        pickupTitle: pickupTitle,
        dropoffLatitude: dropoff.lat!,
        dropoffLongitude: dropoff.lng!,
        dropoffTitle: dropoffTitle,
        durationSeconds: option.duration,
        distanceInKm: option.distance / 1000,
        vehicleType: option.vehicleType,
        price: option.price,
      );
      if (!_isPublishing) return; // cleared while the request was in flight
      _published = true;
      _activeRide = null;
      _activeRideError = null;
      _rideFinished = false;
      _startSseTracking();
    } on ApiException catch (e) {
      if (!_isPublishing) return;
      _publishError = e.message;
    } catch (e) {
      if (!_isPublishing) return;
      debugPrint('⚠️ [RideBookProvider] publishRequest error: $e');
      _publishError = 'تعذر إرسال طلب الرحلة. حاول مرة أخرى.';
    }

    _isPublishing = false;
    notifyListeners();
  }

  /// Cancels the currently matched ride on the backend, then stops tracking.
  /// Returns `true` when the backend accepted the cancellation.
  Future<bool> cancelActiveRide() async {
    final ride = _activeRide;
    if (ride == null || _isCancelling) return false;

    _isCancelling = true;
    _cancelError = null;
    notifyListeners();

    try {
      await _rideRepo.cancelRideRequest(ride.id);
      _rideCancelled = true;
      stopTrackingActiveRide();
      return true;
    } on ApiException catch (e) {
      _cancelError = e.message;
    } catch (e) {
      debugPrint('⚠️ [RideBookProvider] cancelActiveRide error: $e');
      _cancelError = 'تعذر إلغاء الطلب. حاول مرة أخرى.';
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
    return false;
  }

  /// Starts listening on the passenger SSE stream for live ride updates.
  /// Reconnects on failure while the ride is still being tracked.
  void _startSseTracking() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _rideStreamSub?.cancel();

    _rideStreamSub = _rideRepo.streamPassengerEvents().listen(
          _handleRideStreamEvent,
          onError: (Object _) {
            _rideStreamSub = null;
            notifyListeners();
            _scheduleReconnect();
          },
          onDone: () {
            _rideStreamSub = null;
            notifyListeners();
            _scheduleReconnect();
          },
          cancelOnError: true,
        );
  }

  void _scheduleReconnect() {
    if (!_published || _rideCancelled || _rideFinished) return;
    if (_reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      if (!_published || _rideCancelled || _rideFinished) return;
      if (_rideStreamSub == null) _startSseTracking();
    });
  }

  void _handleRideStreamEvent(PassengerRideStreamEvent event) {
    switch (event.type) {
      case PassengerRideStreamType.rideAccepted:
        final accepted = event.accepted;
        if (accepted == null) return;
        _activeRide = PassengerActiveRide(
          id: accepted.rideId,
          status: accepted.status.isNotEmpty ? accepted.status : 'MATCHED',
          driverName: accepted.driverName,
          driverPhone: accepted.driverPhone,
          vehicleNumber: accepted.vehicleNumber,
          vehicleType: accepted.vehicleType,
          pickUpTitle: accepted.pickUpTitle,
          dropOffTitle: accepted.dropOffTitle,
        );
        _activeRideError = null;
        break;

      case PassengerRideStreamType.driverArrived:
        final active = _activeRide;
        if (active == null) return;
        // The backend marks the ride as STARTED when the driver arrives
        // (DriverArrivedListener), so the passenger is told the ride began.
        _activeRide = active.copyWith(driverArrived: true, status: 'STARTED');
        _activeRideError = null;
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _rideStreamSub?.cancel();
    super.dispose();
  }

  /// Stops the live stream and clears the tracked active ride.
  void stopTrackingActiveRide() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _rideStreamSub?.cancel();
    _rideStreamSub = null;
    _activeRide = null;
    _activeRideError = null;
    _isCheckingActiveRide = false;
  }

  /// Returns the caller to the option list to book another ride while
  /// keeping the pinned pick-up / drop-off locations.
  void resetBooking() {
    stopTrackingActiveRide();
    _rideFinished = false;
    _rideCancelled = false;
    _cancelError = null;
    _selectedOption = null;
    _published = false;
    _publishError = null;
    _isPublishing = false;
    _rideOptions = null;
    _rideRequestError = null;
    _isRequestingRide = false;
    notifyListeners();
  }

  /// Clears any fetched/rendered ride options without notifying (the caller
  /// is expected to notifyListeners afterwards).
  void _clearRideRequest() {
    if (_rideOptions == null &&
        _rideRequestError == null &&
        _selectedOption == null &&
        _publishError == null &&
        _cancelError == null &&
        !_isRequestingRide &&
        !_isPublishing &&
        !_published &&
        !_rideCancelled) {
      return;
    }
    _rideOptions = null;
    _rideRequestError = null;
    _isRequestingRide = false;
    _selectedOption = null;
    _publishError = null;
    _isPublishing = false;
    _published = false;
    _rideCancelled = false;
    _cancelError = null;
  }
}

/// A domain error used to surface user-friendly location failures.
class PickupLocationException implements Exception {
  const PickupLocationException(this.message);

  final String message;
}