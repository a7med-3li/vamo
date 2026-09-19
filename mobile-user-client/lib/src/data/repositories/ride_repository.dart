import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/active_ride.dart';
import '../models/passenger_ride_stream.dart';
import '../models/ride_option.dart';

/// Handles ride-request API calls.
///
/// [requestRide] hits `GET /api/v3/ride/request` (GET with a JSON body),
/// which returns a list of `RoutingResponse` ride options for the given
/// pick-up / drop-off coordinates.
///
/// [publishRideRequest] hits `POST /api/v3/ride/request/publish`, which
/// creates the ride and pushes it live to nearby drivers.
class RideRepository {
  RideRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<RideOption>> requestRide({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
  }) async {
    final data = await _api.getWithBody(
      ApiConstants.rideRequest,
      body: {
        'pickUp': {
          'latitude': pickupLatitude,
          'longitude': pickupLongitude,
        },
        'dropOff': {
          'latitude': dropoffLatitude,
          'longitude': dropoffLongitude,
        },
      },
    );

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(RideOption.fromJson)
          .toList(growable: false);
    }

    return const [];
  }

  /// Publishes a ride request for the selected option so drivers receive it
  /// in real time. Backend stores `distance` in km and `duration` in seconds.
  Future<void> publishRideRequest({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required int durationSeconds,
    required double distanceInKm,
    required String vehicleType,
    required double price,
  }) async {
    await _api.post(
      ApiConstants.rideRequestPublish,
      body: {
        'pickUp': {
          'latitude': pickupLatitude,
          'longitude': pickupLongitude,
        },
        'dropOff': {
          'latitude': dropoffLatitude,
          'longitude': dropoffLongitude,
        },
        'duration': durationSeconds,
        'distance': distanceInKm.round(),
        'vehicleType': vehicleType,
        'price': price,
      },
    );
  }

  /// Fetches the passenger's current active ride (MATCHED / STARTED), if any.
  ///
  /// The backend answers 404/410 when there is no active ride.
  Future<PassengerActiveRide?> getActiveRide() async {
    final data = await _api.get(ApiConstants.rideActive);
    if (data is Map<String, dynamic>) {
      final rideJson = (data['ride'] as Map<String, dynamic>?) ?? data;
      return PassengerActiveRide.fromJson(rideJson);
    }
    return null;
  }

  /// Cancels the passenger's active ride request.
  Future<void> cancelRideRequest(String rideId) async {
    await _api.post(ApiConstants.cancelRideRequest(rideId));
  }

  /// Live stream of passenger ride updates (server-sent events).
  ///
  /// Expected SSE payloads from the backend:
  ///  - `event: ride_accepted` → `data: {AcceptedRide fields}`
  ///    sent when a driver accepts the passenger's request.
  ///  - `event: driver_arrived` → `data: {DriverArrived fields}`
  ///    sent when the matched driver reaches the pickup point.
  Stream<PassengerRideStreamEvent> streamPassengerEvents() async* {
    final http.StreamedResponse response;
    try {
      response = await _api.streamGet(ApiConstants.passengerStream);
    } catch (e) {
      throw ApiException('تعذر فتح التحديث المباشر للرحلة.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      throw ApiException(
        'تعذر فتح التحديث المباشر للرحلة (${response.statusCode}).',
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

  PassengerRideStreamEvent? _mapSseEvent(String name, String rawData) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawData);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    switch (name) {
      case 'ride_accepted':
        final rideJson =
            decoded['ride'] as Map<String, dynamic>? ?? decoded;
        final accepted = AcceptedRideInfo.fromJson(rideJson);
        if (accepted.rideId.isEmpty) return null;
        return PassengerRideStreamEvent(
          PassengerRideStreamType.rideAccepted,
          accepted: accepted,
        );

      case 'driver_arrived':
        final arrived = DriverArrivedInfo.fromJson(decoded);
        return PassengerRideStreamEvent(
          PassengerRideStreamType.driverArrived,
          arrived: arrived,
        );

      default:
        return null;
    }
  }
}