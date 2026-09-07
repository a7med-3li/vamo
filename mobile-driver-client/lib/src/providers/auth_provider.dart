import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../data/models/user_info.dart';
import '../data/repositories/auth_repository.dart';

/// Manages authentication state and user session.
///
/// Supports register (driver), login, auto-login (from stored tokens), and logout.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository authRepository})
      : _authRepo = authRepository;

  final AuthRepository _authRepo;

  // ── State ───────────────────────────────────────────────────────────

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  UserInfo? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserInfo? get user => _user;

  /// User display name — falls back to 'سائق' when not logged in.
  String get displayName =>
      _user?.displayName.isNotEmpty == true ? _user!.displayName : 'سائق';

  // ── Register (Driver) ──────────────────────────────────────────────

  Future<bool> registerDriver({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String gender,
    required String nationalId,
    required String licenseNumber,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authRepo.registerDriver(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        gender: gender,
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        password: password,
      );

      // Tokens are saved by the repository. Now fetch user info.
      await _fetchUserInfo();
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'حدث خطأ أثناء إنشاء الحساب.';
      _setLoading(false);
      return false;
    }
  }

  // ── Login ───────────────────────────────────────────────────────────

  Future<bool> login({
    required String phoneNumber,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authRepo.login(
        phoneNumber: phoneNumber,
        password: password,
      );

      // Tokens are saved by the repository. Now fetch user info.
      await _fetchUserInfo();
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تسجيل الدخول.';
      _setLoading(false);
      return false;
    }
  }

  // ── Auto-login ──────────────────────────────────────────────────────

  /// Checks for stored tokens and attempts to restore the session.
  ///
  /// Called on app startup from the splash screen.
  Future<void> tryAutoLogin() async {
    if (!TokenStorage.hasTokens()) return;

    _setLoading(true);

    try {
      await _fetchUserInfo();
      _isAuthenticated = true;
    } on ApiException catch (e) {
      if (e.isAuthError) {
        // Token expired — try refresh.
        final refreshed = await _authRepo.refreshToken();
        if (refreshed) {
          try {
            await _fetchUserInfo();
            _isAuthenticated = true;
          } catch (_) {
            await _clearSession();
          }
        } else {
          await _clearSession();
        }
      } else {
        await _clearSession();
      }
    } catch (_) {
      await _clearSession();
    }

    _setLoading(false);
  }

  // ── Logout ──────────────────────────────────────────────────────────

  Future<void> logout() async {
    _setLoading(true);
    await _authRepo.logout();
    await _clearSession();
    _setLoading(false);
  }

  // ── Error management ───────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ─────────────────────────────────────────────────

  Future<void> _fetchUserInfo() async {
    _user = await _authRepo.getMyInfo();
  }

  Future<void> _clearSession() async {
    _isAuthenticated = false;
    _user = null;
    await TokenStorage.clearTokens();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}