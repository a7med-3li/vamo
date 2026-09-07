/// The driver's operational profile returned by `/api/v1/drivers/profile`.
class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.nationalId,
    required this.licenseNumber,
    required this.onShift,
    this.activeCorridorId,
    required this.approvalStatus,
  });

  final String id;
  final String nationalId;
  final String licenseNumber;

  /// Whether the driver is currently "on shift" (active).
  final bool onShift;

  /// The corridor the driver is currently assigned to, if any.
  final int? activeCorridorId;

  /// One of `PENDING`, `APPROVED`, `REJECTED`.
  final String approvalStatus;

  bool get isApproved => approvalStatus == 'APPROVED';
  bool get isPending => approvalStatus == 'PENDING';
  bool get isRejected => approvalStatus == 'REJECTED';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id']?.toString() ?? '',
      nationalId: json['nationalId'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      onShift: json['onShift'] as bool? ?? false,
      activeCorridorId: json['activeCorridorId'] as int?,
      approvalStatus: json['approvalStatus'] as String? ?? 'PENDING',
    );
  }

  DriverProfile copyWith({
    bool? onShift,
    String? approvalStatus,
  }) {
    return DriverProfile(
      id: id,
      nationalId: nationalId,
      licenseNumber: licenseNumber,
      onShift: onShift ?? this.onShift,
      activeCorridorId: activeCorridorId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  /// Arabic label for the approval status.
  String get approvalLabel {
    switch (approvalStatus) {
      case 'APPROVED':
        return 'مُعتمد';
      case 'REJECTED':
        return 'مرفوض';
      default:
        return 'قيد المراجعة';
    }
  }
}