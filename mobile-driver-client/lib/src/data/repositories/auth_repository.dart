import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_response.dart';
import '../models/user_info.dart';

/// Handles all authentication-related API calls.
class AuthRepository {
  AuthRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Registers a new driver and returns tokens.
  ///
  /// Automatically saves the tokens to [TokenStorage].
  Future<AuthResponse> registerDriver({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String gender,
    required String nationalId,
    required String licenseNumber,
    required String password,
  }) async {
    final data = await _api.postPublic(
      ApiConstants.registerDriver,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'nationalId': nationalId,
        'licenseNumber': licenseNumber,
        'password': password,
      },
    );

    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await TokenStorage.saveTokens(
      token: auth.token,
      refreshToken: auth.refreshToken,
    );
    return auth;
  }

  /// Logs in with phone number and password, returns tokens.
  ///
  /// Automatically saves the tokens to [TokenStorage].
  Future<AuthResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    final data = await _api.postPublic(
      ApiConstants.login,
      body: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );

    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await TokenStorage.saveTokens(
      token: auth.token,
      refreshToken: auth.refreshToken,
    );
    return auth;
  }

  /// Fetches the currently authenticated user's profile.
  Future<UserInfo> getMyInfo() async {
    final data = await _api.get(ApiConstants.myInfo);
    return UserInfo.fromJson(data as Map<String, dynamic>);
  }

  /// Logs out the current user (server-side) and clears stored tokens.
  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {
      // Even if the server call fails, clear local tokens.
    }
    await TokenStorage.clearTokens();
  }

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Returns `true` if the refresh succeeded.
  Future<bool> refreshToken() async {
    final refreshToken = TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final data = await _api.postPublic(
        ApiConstants.refreshToken,
        body: {'refreshToken': refreshToken},
      );

      if (data is Map<String, dynamic>) {
        final newToken = data['token'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newToken != null && newRefresh != null) {
          await TokenStorage.saveTokens(
            token: newToken,
            refreshToken: newRefresh,
          );
          return true;
        }
      }
    } catch (_) {
      // Refresh failed
    }

    await TokenStorage.clearTokens();
    return false;
  }
}