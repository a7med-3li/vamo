/// A ride request offered to an active driver.
///
/// Mirrors the backend `DriverRideRequestItem` DTO returned by the
/// pending-ride-requests snapshot and pushed via the SSE stream.
class RideRequest {
  const RideRequest({
    required this.id,
    required this.passengerName,
    required this.passengerPhone,
    required this.price,
    required this.requestedAt,
    required this.pickUpLat,
    required this.pickUpLng,
    required this.dropOffLat,
    required this.dropOffLng,
    this.distanceInKm = 0,
    this.durationSeconds = 0,
    this.vehicleType = '',
    this.status = 'REQUESTED',
  });

  final String id;
  final String passengerName;
  final String passengerPhone;
  final double price;
  final DateTime requestedAt;
  final double pickUpLat;
  final double pickUpLng;
  final double dropOffLat;
  final double dropOffLng;
  final double distanceInKm;
  final int durationSeconds;
  final String vehicleType;
  final String status;

  /// Human-friendly label for the pickup location (from coordinates).
  String get pickupLabel => RideRequest._coord(pickUpLat, pickUpLng);

  /// Human-friendly label for the drop-off location (from coordinates).
  String get destinationLabel => RideRequest._coord(dropOffLat, dropOffLng);

  int get durationMinutes => (durationSeconds / 60).round();

  String get vehicleLabel {
    switch (vehicleType.toUpperCase()) {
      case 'CAR':
        return 'سيارة';
      case 'TAXI':
        return 'تاكسي';
      case 'SCOOTER':
        return 'موتوسيكل';
      case 'BUS':
        return 'أوتوبيس';
      default:
        return vehicleType.isEmpty ? '—' : vehicleType;
    }
  }

  static String _coord(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    double numVal(Object? v) => (v as num?)?.toDouble() ?? 0;
    return RideRequest(
      id: json['rideId']?.toString() ?? json['id']?.toString() ?? '',
      passengerName: json['passengerName'] as String? ?? '',
      passengerPhone: json['passengerPhone'] as String? ?? '',
      price: numVal(json['estimatedFare'] ?? json['price']),
      requestedAt:
          DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
              DateTime.now(),
      pickUpLat: numVal(json['pickUpLat']),
      pickUpLng: numVal(json['pickUpLng']),
      dropOffLat: numVal(json['dropOffLat']),
      dropOffLng: numVal(json['dropOffLng']),
      distanceInKm: numVal(json['distanceInKm']),
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      vehicleType: json['vehicleType'] as String? ?? '',
      status: json['status'] as String? ?? 'REQUESTED',
    );
  }
}

/// Incoming events parsed from the driver live ride-request stream (SSE).
enum RideStreamEventType {
  /// Initial snapshot of pending requests, sent on connect.
  snapshot,

  /// A new ride request was published by a passenger.
  newRide,

  /// A ride request was accepted (by another driver).
  rideAccepted,
}

class RideStreamEvent {
  const RideStreamEvent(this.type, {this.rides, this.ride, this.rideId});

  final RideStreamEventType type;

  /// Populated for [RideStreamEventType.snapshot].
  final List<RideRequest>? rides;

  /// Populated for [RideStreamEventType.newRide].
  final RideRequest? ride;

  /// Populated for [RideStreamEventType.rideAccepted].
  final String? rideId;
}