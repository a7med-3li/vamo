/// The passenger's currently active ride, as returned by `/api/v3/ride/active`.
///
/// Only the fields needed to drive the MVP "ride status" screen are parsed:
/// the ride id and its status (REQUESTED → MATCHED → STARTED → gone).
class PassengerActiveRide {
  const PassengerActiveRide({required this.id, required this.status});

  final String id;
  final String status;

  bool get isMatched => status.toUpperCase() == 'MATCHED';
  bool get isStarted => status.toUpperCase() == 'STARTED';

  factory PassengerActiveRide.fromJson(Map<String, dynamic> json) {
    return PassengerActiveRide(
      id: json['rideId']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'REQUESTED',
    );
  }
}