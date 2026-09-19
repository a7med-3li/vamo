import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/driver_profile.dart';
import '../models/ride_request.dart';

/// Handles driver-specific API calls.
class DriverRepository {
  DriverRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Fetches the current driver's operational profile.
  Future<DriverProfile> getProfile() async {
    final data = await _api.get(ApiConstants.driverProfile);
    return DriverProfile.fromJson(data as Map<String, dynamic>);
  }

  /// Toggles the driver's shift (active / inactive) state.
  Future<void> toggleShift({required bool onShift}) async {
    await _api.post(
      ApiConstants.toggleShift,
      queryParams: {'onShift': '$onShift'},
    );
  }

  /// Fetches pending ride requests offered to the driver (initial snapshot).
  Future<List<RideRequest>> getPendingRideRequests() async {
    final data = await _api.get(ApiConstants.pendingRideRequests);

    if (data is List) {
      return data
          .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    return const [];
  }

  /// Accepts a ride request, binding it to the current driver.
  Future<void> acceptRideRequest(String rideRequestId) async {
    await _api.post(ApiConstants.acceptRideRequest(rideRequestId));
  }

  /// Fetches the driver's current active ride (MATCHED / STARTED), if any.
  ///
  /// The backend answers 404 when the driver has no active ride.
  Future<RideRequest?> getActiveRide() async {
    final data = await _api.get(ApiConstants.driverActiveRide);
    if (data is Map<String, dynamic>) {
      final rideJson = (data['ride'] as Map<String, dynamic>?) ?? data;
      return RideRequest.fromJson(rideJson);
    }
    return null;
  }

  /// Marks the current ride as started (driver arrived and began the trip).
  Future<void> startRide(String rideId) async {
    await _api.post(ApiConstants.startRide(rideId));
  }

  /// Reports the driver's arrival at the pickup point.
  ///
  /// Hits `POST /api/v1/drivers/ride/{id}/arrived`, which makes the backend
  /// broadcast the `driver_arrived` live event to the passenger.
  Future<void> reportArrived(
    String rideId, {
    required double pickupLatitude,
    required double pickupLongitude,
  }) async {
    await _api.post(
      ApiConstants.driverArrived(rideId),
      body: {
        'latitude': pickupLatitude,
        'longitude': pickupLongitude,
      },
    );
  }

  /// Completes the current ride.
  Future<void> completeRide(String rideId) async {
    await _api.post(ApiConstants.completeRide(rideId));
  }

  /// Live stream of ride-request events (server-sent events).
  ///
  /// Expected SSE payloads from the backend:
  ///  - `event: ride_request` → `data: {"ride":{DriverRideRequestItem}}`
  ///    sent for every newly requested ride.
  ///  - `event: rides-snapshot` → `data: {"rides":[{DriverRideRequestItem}]}`
  ///    sent once when the connection is opened.
  ///  - `event: ride_taken`    → `data: {"rideId":"..."}`
  ///    sent when a ride request is accepted by a driver, so every other
  ///    connected driver can remove it from their offered list.
  ///  - `event: ride_Not_available` → `data: {"rideId":"..."}`
  ///    broadcast when a request is taken or cancelled, so drivers can remove
  ///    it from their offered list.
  ///  - `event: ride_cancelled` → `data: "<rideId>"`
  ///    sent to the matched driver when the passenger cancels, so the active
  ///    ride can be cleared.
  Stream<RideStreamEvent> streamRideRequests() async* {
    final http.StreamedResponse response;
    try {
      response = await _api.streamGet(ApiConstants.rideRequestStream);
    } catch (e) {
      throw ApiException('تعذر فتح التحديث المباشر للطلبات.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      throw ApiException(
        'تعذر فتح التحديث المباشر للطلبات (${response.statusCode}).',
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String eventName = '';
    final dataParts = <String>[];

    await for (final line in lines) {
      if (line.isEmpty) {
        if (dataParts.isNotEmpty) {
          final event = _mapSseEvent(eventName, dataParts.join('\n'));
          if (event != null) yield event;
        }
        eventName = '';
        dataParts.clear();
        continue;
      }

      if (line.startsWith(':')) continue; // SSE comment
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataParts.add(line.substring(5).trimLeft());
      }
    }
  }

  RideStreamEvent? _mapSseEvent(String name, String rawData) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawData);
    } catch (_) {
      return null;
    }
    // `ride_cancelled` can arrive as a raw JSON string (the ride id), all
    // other events arrive as JSON objects.
    if (decoded is! Map<String, dynamic> && decoded is! String) return null;

    switch (name) {
      case 'rides-snapshot':
        final rides = (decoded['rides'] as List? ?? const [])
            .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
        return RideStreamEvent(RideStreamEventType.snapshot, rides: rides);

      case 'ride-new':
      case 'ride_request':
        final rideJson =
            decoded['ride'] as Map<String, dynamic>? ?? decoded;
        final ride = RideRequest.fromJson(rideJson);
        if (ride.id.isEmpty) return null;
        return RideStreamEvent(RideStreamEventType.newRide, ride: ride);

      case 'ride_not_available':
      case 'ride_taken':
      case 'ride-taken':
        final rideId = decoded['rideId']?.toString();
        if (rideId == null || rideId.isEmpty) return null;
        return RideStreamEvent(
          RideStreamEventType.rideTaken,
          rideId: rideId,
        );

      case 'ride_cancelled':
      case 'ride-cancelled':
        // The matched driver receives the raw ride id (a JSON string) as the
        // payload, not a JSON object.
        final Object? rawRideId;
        if (decoded is String) {
          rawRideId = decoded;
        } else if (decoded is Map<String, dynamic>) {
          rawRideId = decoded['rideId'];
        } else {
          return null;
        }
        final rideId = rawRideId?.toString();
        if (rideId == null || rideId.isEmpty) return null;
        return RideStreamEvent(
          RideStreamEventType.rideCancelled,
          rideId: rideId,
        );

      default:
        return null;
    }
  }
}
