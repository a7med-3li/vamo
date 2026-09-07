/// Centralised API configuration.
///
/// Switch [baseUrl] between the development IP and the production domain
/// before publishing a release build.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ────────────────────────────────────────────────────────
  /// Development server (direct IP).
  static const String _devBaseUrl = 'http://48.199.17.132:8080';

  /// Production domain (when DNS is configured).
  // ignore: unused_field
  static const String _prodBaseUrl = 'https://api.vamoeg.app';
  /// Local development server.
  static const String _localBaseUrl = 'http://localhost:8080';

  /// Active base URL used by the app.
  static const String baseUrl = _localBaseUrl;
  // ── Auth ────────────────────────────────────────────────────────────
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // ── User ────────────────────────────────────────────────────────────
  static const String myInfo = '/api/v1/users/me';
  static String userById(String id) => '/api/v1/users/$id';
  static const String users = '/api/v1/users/';

  // ── Corridors ───────────────────────────────────────────────────────
  static const String corridors = '/api/v1/corridors';
  static const String addCorridor = '/api/v1/corridors/add';

  // ── Subscriptions ──────────────────────────────────────────────────
  static const String purchaseSubscription = '/api/v1/subscriptions/purchase';
  static const String activeSubscription = '/api/v1/subscriptions/active';
  static const String subscriptionHistory = '/api/v1/subscriptions/history';
  static String cancelSubscription(int id) => '/api/v1/subscriptions/$id/cancel';

  // ── Admin ─────────────────────────────────────────────────────────
  static const String pendingSubscriptions =
      '/api/v1/admin/subscriptions/pending';
  static const String adminDrivers = '/api/v1/admin/drivers';
  static String adminApproveDriver(String profileId) =>
      '/api/v1/admin/drivers/$profileId/approve';
  static String adminRejectDriver(String profileId) =>
      '/api/v1/admin/drivers/$profileId/reject';

  // ── Configurations ────────────────────────────────────────────────
  static const String fareConfigs = '/api/v1/configurations/fare-configs';

  // ── Rides (future use) ─────────────────────────────────────────────
  static const String rideHistory = '/api/v3/ride/history';
  static const String rideSearch = '/api/v3/ride/search';
  static const String estimateRide = '/api/v3/ride/estimate-ride';

  // ── Notifications ─────────────────────────────────────────────────
  static const String allNotifications = '/api/v1/notifications';
  static String getNotification(String id) => '/api/v1/notifications/$id';
}
