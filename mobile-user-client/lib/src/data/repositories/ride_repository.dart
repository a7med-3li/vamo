import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
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
}