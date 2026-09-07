import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT tokens using [SharedPreferences].
///
/// Uses driver-specific keys (`vamo_driver_*`) so a driver install
/// does not clash with the passenger app on the same device.
///
/// Call [init] once at app startup before any other method.
class TokenStorage {
  TokenStorage._();

  static const String _tokenKey = 'vamo_driver_jwt_token';
  static const String _refreshTokenKey = 'vamo_driver_refresh_token';

  static SharedPreferences? _prefs;

  /// Initialise the underlying [SharedPreferences] instance.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Write ───────────────────────────────────────────────────────────

  /// Persists both [token] and [refreshToken].
  static Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_refreshTokenKey, refreshToken);
  }

  // ── Read ────────────────────────────────────────────────────────────

  /// Returns the stored JWT access token, or `null` if absent.
  static String? getToken() => _prefs?.getString(_tokenKey);

  /// Returns the stored refresh token, or `null` if absent.
  static String? getRefreshToken() => _prefs?.getString(_refreshTokenKey);

  /// `true` when both access and refresh tokens are present.
  static bool hasTokens() =>
      getToken() != null && getRefreshToken() != null;

  // ── Delete ──────────────────────────────────────────────────────────

  /// Removes all stored tokens (used on logout).
  static Future<void> clearTokens() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_refreshTokenKey);
  }
}