/// The passenger's currently active ride.
///
/// Produced from the live SSE stream (`/api/v1/dispatch/passengers/stream`)
/// when a driver accepts (`ride_accepted`) or arrives (`driver_arrived`).
class PassengerActiveRide {
  const PassengerActiveRide({
    required this.id,
    required this.status,
    this.driverName = '',
    this.driverPhone = '',
    this.vehicleNumber = '',
    this.vehicleType = '',
    this.driverArrived = false,
  });

  final String id;
  final String status;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final String vehicleType;

  /// Whether the matched driver has reached the pickup point.
  final bool driverArrived;

  bool get isMatched => status.toUpperCase() == 'MATCHED';
  bool get isStarted => status.toUpperCase() == 'STARTED';

  /// Driver display name, falling back to a neutral placeholder.
  String get driverNameLabel {
    final name = driverName.trim();
    return name.isEmpty ? 'سائق فامو' : name;
  }

  /// Vehicle number, falling back to a neutral placeholder.
  String get vehicleNumberLabel {
    final number = vehicleNumber.trim();
    return number.isEmpty ? '—' : number;
  }

  PassengerActiveRide copyWith({
    String? status,
    String? driverName,
    String? driverPhone,
    String? vehicleNumber,
    String? vehicleType,
    bool? driverArrived,
  }) {
    return PassengerActiveRide(
      id: id,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      driverArrived: driverArrived ?? this.driverArrived,
    );
  }

  factory PassengerActiveRide.fromJson(Map<String, dynamic> json) {
    return PassengerActiveRide(
      id: json['rideId']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'REQUESTED',
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
    );
  }
}