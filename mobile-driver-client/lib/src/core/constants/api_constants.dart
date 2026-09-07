/// Centralised API configuration.
///
/// Switch [baseUrl] between the development IP and the production domain
/// before publishing a release build.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ────────────────────────────────────────────────────────
  /// Development server (direct IP).
  // ignore: unused_field
  static const String _devBaseUrl = 'http://13.51.40.28:8080';

  /// Production domain (when DNS is configured).
  // ignore: unused_field
  static const String _prodBaseUrl = 'https://api.vamoeg.app';

  static const String _localBaseUrl = 'http://localhost:8080';
  /// Active base URL used by the app.
  static const String baseUrl = _localBaseUrl;

  // ── Auth ────────────────────────────────────────────────────────────
  static const String registerDriver = '/api/v1/auth/register/driver';
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // ── User ────────────────────────────────────────────────────────────
  static const String myInfo = '/api/v1/users/me';

  // ── Driver ──────────────────────────────────────────────────────────
  static const String driverProfile = '/api/v1/drivers/profile';
  static const String toggleShift = '/api/v1/drivers/toggle-shift';
  static const String wallet = '/api/v1/drivers/wallet';
  static const String walletTransactions = '/api/v1/drivers/wallet/transactions';
  static const String walletDeposit = '/api/v1/drivers/wallet/deposit';

  // ── Ride requests ─────────────────────────────────────────────────
  /// Snapshot of pending ride requests (status = REQUESTED).
  static const String pendingRideRequests =
      '/api/v1/drivers/ride-requests/pending';

  /// Accepts a ride request, binding it to the current driver.
  static String acceptRideRequest(String rideId) =>
      '/api/v1/drivers/ride-requests/$rideId/accept';

  /// Server-sent events stream for live ride requests.
  static const String rideRequestStream =
      '/api/v1/drivers/ride-requests/stream';
}