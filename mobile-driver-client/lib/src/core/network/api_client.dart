import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Central HTTP client that auto-attaches JWT tokens and handles
/// automatic token refresh on 401/403 responses.
class ApiClient {
  ApiClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Flag to prevent infinite refresh loops.
  bool _isRefreshing = false;

  // ── Public API ──────────────────────────────────────────────────────

  /// Sends a GET request to [path] (relative to [ApiConstants.baseUrl]).
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    return _sendWithRetry(() => _client.get(uri, headers: _headers()));
  }

  /// Opens a long-lived GET connection and returns the raw response stream.
  ///
  /// Used for server-sent events (SSE). No timeout is applied — the caller
  /// owns the returned stream and must handle errors/cancellation.
  Future<http.StreamedResponse> streamGet(String path) async {
    final uri = _buildUri(path);
    final request = http.Request('GET', uri);
    final token = TokenStorage.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'text/event-stream';
    return _client.send(request);
  }

  /// Sends a POST request with a JSON [body].
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    return _sendWithRetry(
      () => _client.post(uri, headers: _headers(), body: jsonEncode(body ?? {})),
    );
  }

  /// Sends a PATCH request with a JSON [body].
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    return _sendWithRetry(
      () => _client.patch(uri, headers: _headers(), body: jsonEncode(body ?? {})),
    );
  }

  /// Sends a DELETE request.
  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    return _sendWithRetry(() => _client.delete(uri, headers: _headers()));
  }

  /// Sends a POST request **without** attaching the bearer token.
  /// Used for login, register, and refresh endpoints.
  Future<dynamic> postPublic(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    return _send(
      () => _client.post(uri, headers: _publicHeaders(), body: jsonEncode(body ?? {})),
      retry: false,
    );
  }

  // ── Internal helpers ────────────────────────────────────────────────

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(ApiConstants.baseUrl);
    return base.replace(
      path: path,
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = TokenStorage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, String> _publicHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Sends the request. If it returns 401/403 and [retry] is true,
  /// attempts a token refresh then retries the original request once.
  Future<dynamic> _sendWithRetry(
    Future<http.Response> Function() request,
  ) async {
    return _send(request, retry: true);
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    required bool retry,
  }) async {
    late http.Response response;

    try {
      response = await request().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw ApiException(
        'انتهت مهلة الاتصال. حاول مرة أخرى.',
      );
    } on SocketException {
      throw ApiException(
        'تعذر الوصول إلى الخادم. تحقق من اتصال الإنترنت.',
      );
    } on HttpException {
      throw ApiException('حدث خطأ أثناء الاتصال بالخادم.');
    } on ApiException {
      rethrow;
    } on Exception catch (e, stackTrace) {
      debugPrint('🚨 [ApiClient] Exception: $e');
      debugPrint('🚨 [ApiClient] StackTrace: $stackTrace');
      throw ApiException('خطأ غير متوقع: ${e.toString()}');
    }

    // ── Attempt auto-refresh on auth failure ────────────────────────
    if (retry && (response.statusCode == 401 || response.statusCode == 403)) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request with the new token.
        try {
          response = await request().timeout(const Duration(seconds: 30));
        } on TimeoutException {
          throw ApiException(
            'انتهت مهلة الاتصال. حاول مرة أخرى.',
          );
        } on SocketException {
          throw ApiException(
            'تعذر الوصول إلى الخادم. تحقق من اتصال الإنترنت.',
          );
        } on HttpException {
          throw ApiException('حدث خطأ أثناء الاتصال بالخادم.');
        }
      }
    }

    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    final body = response.body.trim();
    dynamic decoded;
    
    try {
      decoded = body.isEmpty ? null : jsonDecode(body);
    } catch (e) {
      debugPrint('🚨 [ApiClient] Failed to decode JSON: $body');
      // If it's an error response, we'll handle it below.
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded ?? <String, dynamic>{};
    }

    if (response.statusCode >= 400) {
      debugPrint('🚨 [ApiClient] HTTP Error ${response.statusCode}: $body');
      
      if (decoded is Map<String, dynamic>) {
        throw ApiException.fromJson(decoded, statusCode: response.statusCode);
      }
      
      // Fallback meaningful message if it's not JSON
      String message = 'حدث خطأ في الخادم (${response.statusCode}).';
      if (response.statusCode == 400) message = 'طلب غير صالح. يرجى التحقق من البيانات.';
      if (response.statusCode == 401) message = 'انتهت صلاحية الجلسة. سجل الدخول مرة أخرى.';
      if (response.statusCode == 404) message = 'الخدمة غير موجودة.';
      if (response.statusCode == 500) message = 'خطأ داخلي في الخادم. حاول لاحقاً.';
      
      throw ApiException(message, statusCode: response.statusCode);
    }

    throw ApiException(
      'فشل الطلب (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  /// Attempts to refresh the JWT access token using the stored refresh token.
  /// Returns `true` if refresh succeeded, `false` otherwise.
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;

    final refreshToken = TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    _isRefreshing = true;

    try {
      final uri = _buildUri(ApiConstants.refreshToken);
      final response = await _client.post(
        uri,
        headers: _publicHeaders(),
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final newToken = decoded['token'] as String?;
          final newRefreshToken = decoded['refreshToken'] as String?;

          if (newToken != null && newRefreshToken != null) {
            await TokenStorage.saveTokens(
              token: newToken,
              refreshToken: newRefreshToken,
            );
            return true;
          }
        }
      }

      // Refresh failed — clear tokens so the user gets sent to login.
      await TokenStorage.clearTokens();
      return false;
    } catch (_) {
      await TokenStorage.clearTokens();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}