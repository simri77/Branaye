import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import 'session_events.dart';
import 'token_store.dart';

/// The single Dio instance for the whole app.
///
/// Two interceptors make it "authenticated by default":
/// - onRequest attaches `Authorization: Bearer <token>` when a token exists.
/// - onError fires a session-expired event on any 401 so the app can log out.
///
/// Repositories receive this Dio; they never touch tokens themselves.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final tokenStore = ref.watch(tokenStoreProvider);
  final sessionEvents = ref.watch(sessionEventsProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStore.clear();
          sessionEvents.fireUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});

/// Maps a Dio failure into a message we can show a human.
String messageForDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Connection timed out. Check your network.';
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return 'Cannot reach the server. Is the backend running?';
    case DioExceptionType.badResponse:
      final data = error.response?.data;
      if (data is Map && data['error'] is String) return data['error'] as String;
      final status = error.response?.statusCode;
      if (status == 401) return 'Invalid email or password.';
      if (status == 409) return 'That email is already registered.';
      if (status == 429) return 'Too many attempts. Try again in a minute.';
      if (status != null && status >= 500) return 'Server error. Please try again.';
      return 'Request failed (${status ?? 'unknown'}).';
    case DioExceptionType.cancel:
      return 'Request cancelled.';
    case DioExceptionType.badCertificate:
      return 'Secure connection failed.';
  }
}
