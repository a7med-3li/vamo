/// Live updates pushed to the passenger over the SSE stream
/// (`/api/v1/dispatch/passengers/stream`).
///
/// Mirrors the backend DTOs:
///  - `ride_accepted`  → `AcceptedRide` (a driver accepted the request).
///  - `driver_arrived` → `DriverArrived` (the driver reached the pickup).
enum PassengerRideStreamType { rideAccepted, driverArrived }

class PassengerRideStreamEvent {
  const PassengerRideStreamEvent(this.type, {this.accepted, this.arrived});

  final PassengerRideStreamType type;

  /// Populated for [PassengerRideStreamType.rideAccepted].
  final AcceptedRideInfo? accepted;

  /// Populated for [PassengerRideStreamType.driverArrived].
  final DriverArrivedInfo? arrived;
}

/// The ride details broadcast when a driver accepts the request.
class AcceptedRideInfo {
  const AcceptedRideInfo({
    required this.rideId,
    this.driverName = '',
    this.driverPhone = '',
    this.vehicleNumber = '',
    this.vehicleType = '',
    this.estimatedFare = 0,
    this.status = '',
  });

  final String rideId;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final String vehicleType;
  final double estimatedFare;
  final String status;

  /// Driver display name, falling back to a neutral placeholder when the
  /// backend does not send it.
  String get driverNameLabel {
    final name = driverName.trim();
    return name.isEmpty ? 'سائق فامو' : name;
  }

  factory AcceptedRideInfo.fromJson(Map<String, dynamic> json) {
    return AcceptedRideInfo(
      rideId: json['rideId']?.toString() ?? json['id']?.toString() ?? '',
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      estimatedFare:
          (json['estimatedFare'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
    );
  }
}

/// The payload pushed when the driver reaches the passenger.
class DriverArrivedInfo {
  const DriverArrivedInfo({
    this.driverPhone = '',
    this.vehicleNumber = '',
  });

  final String driverPhone;
  final String vehicleNumber;

  factory DriverArrivedInfo.fromJson(Map<String, dynamic> json) {
    return DriverArrivedInfo(
      driverPhone: json['driverPhone'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
    );
  }
}