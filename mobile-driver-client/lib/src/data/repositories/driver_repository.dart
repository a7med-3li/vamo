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

  /// Live stream of ride-request events (server-sent events).
  ///
  /// Expected SSE payloads from the backend:
  ///  - `event: rides-snapshot` → `data: {"rides":[{DriverRideRequestItem}]}`
  ///    sent once when the connection is opened.
  ///  - `event: ride-new`       → `data: {DriverRideRequestItem}`
  ///  - `event: ride-accepted`  → `data: {"rideId":"..."}`
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
    if (decoded is! Map<String, dynamic>) return null;

    switch (name) {
      case 'rides-snapshot':
        final rides = (decoded['rides'] as List? ?? const [])
            .map((e) => RideRequest.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
        return RideStreamEvent(RideStreamEventType.snapshot, rides: rides);

      case 'ride-new':
        final ride = RideRequest.fromJson(decoded);
        if (ride.id.isEmpty) return null;
        return RideStreamEvent(RideStreamEventType.newRide, ride: ride);

      case 'ride-accepted':
        final rideId = decoded['rideId']?.toString();
        if (rideId == null || rideId.isEmpty) return null;
        return RideStreamEvent(
          RideStreamEventType.rideAccepted,
          rideId: rideId,
        );

      default:
        return null;
    }
  }
}