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
    this.pickUpTitle = '',
    this.dropOffTitle = '',
  });

  final String id;
  final String status;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final String vehicleType;

  /// Whether the matched driver has reached the pickup point.
  final bool driverArrived;

  /// Human-friendly titles for the ride legs, when the backend sent them.
  final String pickUpTitle;
  final String dropOffTitle;

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
    String? pickUpTitle,
    String? dropOffTitle,
  }) {
    return PassengerActiveRide(
      id: id,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      driverArrived: driverArrived ?? this.driverArrived,
      pickUpTitle: pickUpTitle ?? this.pickUpTitle,
      dropOffTitle: dropOffTitle ?? this.dropOffTitle,
    );
  }

  factory PassengerActiveRide.fromJson(Map<String, dynamic> json) {
    String titleAt(Map<String, dynamic>? location) =>
        location == null ? '' : (location['title'] as String? ?? '');

    final pickUpRaw = (json['pickUp'] as Map<String, dynamic>?) ??
        (json['pickUpLocation'] as Map<String, dynamic>?);
    final dropOffRaw = (json['dropOff'] as Map<String, dynamic>?) ??
        (json['dropOffLocation'] as Map<String, dynamic>?);

    return PassengerActiveRide(
      id: json['rideId']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'REQUESTED',
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      pickUpTitle: titleAt(pickUpRaw),
      dropOffTitle: titleAt(dropOffRaw),
    );
  }
}