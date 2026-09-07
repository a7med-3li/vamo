/// JWT authentication response returned by login and register endpoints.
class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.refreshToken,
  });

  /// The short-lived JWT access token (expires in ~15 minutes).
  final String token;

  /// The long-lived refresh token used to obtain a new access token.
  final String refreshToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'refreshToken': refreshToken,
      };
}