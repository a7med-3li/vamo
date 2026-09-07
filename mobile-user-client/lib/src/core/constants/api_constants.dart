/// Centralised API configuration.
///
/// Switch [baseUrl] between the development IP and the production domain
/// before publishing a release build.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ────────────────────────────────────────────────────────
  /// Development server (direct IP).
  static const String _devBaseUrl = 'http://13.51.40.28:8080';

  /// Production domain (when DNS is configured).
  // ignore: unused_field
  static const String _prodBaseUrl = 'https://api.vamoeg.app';

  static const String _localBaseUrl = 'http://localhost:8080';
  /// Active base URL used by the app.
  static const String baseUrl = _devBaseUrl;

  // ── Auth ────────────────────────────────────────────────────────────
  static const String registerPassenger = '/api/v1/auth/register/passenger';
  static const String registerDriver = '/api/v1/auth/register/driver';
  static const String login = '/api/v1/auth/login';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // ── OTP ─────────────────────────────────────────────────────────────
  static const String sendOtp = '/api/v1/auth/phone/send-otp';
  static const String verifyOtp = '/api/v1/auth/phone/verify-otp';

  // ── User ────────────────────────────────────────────────────────────
  static const String myInfo = '/api/v1/users/me';
  static String userById(String id) => '/api/v1/users/$id';

  // ── Corridors ───────────────────────────────────────────────────────
  static const String corridors = '/api/v1/corridors';
  static const String addCorridor = '/api/v1/corridors/add';

  // ── Subscriptions ──────────────────────────────────────────────────
  static const String purchaseSubscription = '/api/v1/subscriptions/purchase';
  static const String activeSubscription = '/api/v1/subscriptions/active';
  static const String pendingSubscription = '/api/v1/subscriptions/pending';
  static const String subscriptionHistory = '/api/v1/subscriptions/history';
  static String cancelSubscription(int id) => '/api/v1/subscriptions/$id/cancel';

  // ── Rides (future use) ─────────────────────────────────────────────
  static const String rideHistory = '/api/v3/ride/history';
  static const String rideSearch = '/api/v3/ride/search';
  static const String estimateRide = '/api/v3/ride/estimate-ride';
  static const String rideRequest = '/api/v3/ride/request';

  // ── Address / autocomplete / search (Book a Ride) ─────────────────
  static const String addressAutoComplete = '/api/v1/address/autoComplete';
  static const String addressSearch = '/api/v1/address/search';

  // ── Notifications ──────────────────────────────────────────────────
  static const String allNotifications = '/api/v1/notifications';
  static const String unreadCount = '/api/v1/notifications/unread-count';
  static String getNotification(String id) => '/api/v1/notifications/$id';
  static String markNotificationRead(String id) => '/api/v1/notifications/$id/read';
}
