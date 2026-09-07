/// The authenticated driver's profile information.
class UserInfo {
  const UserInfo({
    required this.displayName,
    required this.gender,
    required this.phoneNumber,
    this.email,
    required this.role,
  });

  final String displayName;
  final String gender;
  final String phoneNumber;
  final String? email;
  final String role;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      displayName: json['displayName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'DRIVER',
    );
  }

  /// Arabic label for the user's gender.
  String get genderLabel => gender == 'FEMALE' ? 'أنثى' : 'ذكر';

  /// Arabic label for the user's role.
  String get roleLabel {
    switch (role) {
      case 'ADMIN':
        return 'مدير';
      case 'DRIVER':
        return 'سائق';
      case 'MANAGER':
        return 'مشرف';
      case 'BOTH':
        return 'سائق وراكب';
      default:
        return 'راكب';
    }
  }
}