import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/note.dart';
import '../core/models/category.dart';
import 'api/auth_repository.dart';
import 'api/backup_repository.dart';
import 'api/categories_repository.dart';
import 'api/dio_provider.dart';
import 'api/fcm_service.dart';
import 'api/google_account_service.dart';
import 'api/notes_repository.dart';
import 'api/session_events.dart';
import 'api/token_store.dart';

/// Bumped whenever the session changes so GoRouter re-runs its redirect guard.
///
/// It lives here (not in the router) because it is auth state, and this avoids a
/// providers <-> router import cycle.
final authRefreshNotifier = ValueNotifier<int>(0);

// --- Auth ---

/// Where the user is in the login lifecycle.
enum AuthStatus { idle, loading, authenticated, error }

class UserModel {
  const UserModel({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? errorCode;

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref.watch(sessionEventsProvider).onUnauthorized.listen(
      (_) {
        logout().catchError((Object error) {
          debugPrint('Could not clear the expired session: $error');
        });
      },
    );
    ref.onDispose(subscription.cancel);
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  int _operationId = 0;
  Future<void> _pendingLogout = Future<void>.value();

  /// Called once at startup, before the first frame, to restore a saved session.
  Future<void> restoreSession() async {
    final operationId = ++_operationId;
    final token = await ref.read(tokenStoreProvider).read();
    if (operationId != _operationId || token == null || token.isEmpty) return;

    state = AuthState(status: AuthStatus.loading);
    try {
      final user = await _repository.me();
      if (operationId != _operationId) return;
      state = AuthState(status: AuthStatus.authenticated, user: _toUser(user));
      ref.read(fcmServiceProvider).init();
    } on DioException catch (error) {
      if (operationId != _operationId) return;
      // A dead token is not an error worth showing: just start logged out.
      if (error.response?.statusCode != 401) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: messageForDioError(error),
        );
      } else {
        state = const AuthState();
      }
    }
    _notifyRouter();
  }

  Future<bool> login(String email, String password) async {
    return _authenticate(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<bool> register(String name, String email, String password) async {
    final operationId = ++_operationId;
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _pendingLogout;
      if (operationId != _operationId) return false;
      final message = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      if (operationId != _operationId) return false;
      state = AuthState(errorMessage: message);
      _notifyRouter();
      return true;
    } on DioException catch (error) {
      if (operationId != _operationId) return false;
      _setAuthError(messageForDioError(error), error);
      _notifyRouter();
      return false;
    } catch (error) {
      if (operationId != _operationId) return false;
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: error.toString(),
      );
      _notifyRouter();
      return false;
    }
  }

  Future<String> resendVerification(String email) =>
      _repository.resendVerification(email);

  Future<bool> loginWithGoogle(String idToken) =>
      _authenticate(() => _repository.loginWithGoogle(idToken));

  Future<bool> _authenticate(Future<AuthSession> Function() call) async {
    final operationId = ++_operationId;
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _pendingLogout;
      if (operationId != _operationId) return false;
      final session = await call();
      if (operationId != _operationId) return false;
      await ref.read(tokenStoreProvider).write(session.accessToken);
      if (operationId != _operationId) return false;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: _toUser(session.user),
      );
      _notifyRouter();
      // Register FCM token (best-effort, non-blocking).
      ref.read(fcmServiceProvider).init();
      return true;
    } on DioException catch (error) {
      if (operationId != _operationId) return false;
      _setAuthError(messageForDioError(error), error);
      _notifyRouter();
      return false;
    } catch (error) {
      if (operationId != _operationId) return false;
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Could not save the login session: $error',
      );
      _notifyRouter();
      return false;
    }
  }

  void _setAuthError(String message, DioException error) {
    final data = error.response?.data;
    final details = data is Map<String, dynamic> ? data['details'] : null;
    final code = details is Map<String, dynamic> ? details['code'] : null;
    state = AuthState(
      status: AuthStatus.error,
      errorMessage: message,
      errorCode: code is String ? code : null,
    );
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (state.user == null) return;
    if (name == null) return;

    try {
      final user = await _repository.updateProfile(name: name);
      state = AuthState(status: AuthStatus.authenticated, user: _toUser(user));
    } on DioException catch (_) {
      // Keep the current user; the screen shows the failure itself.
      rethrow;
    }
  }

  Future<void> logout() async {
    ++_operationId;
    state = const AuthState();
    _notifyRouter();
    _pendingLogout = ref.read(tokenStoreProvider).clear();
    await _pendingLogout;
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthState(user: state.user);
    }
  }

  void _notifyRouter() => authRefreshNotifier.value++;

  UserModel _toUser(AuthUser user) =>
      UserModel(id: user.id, name: user.name, email: user.email);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final googleAccountServiceProvider = Provider<GoogleAccountService>((ref) {
  return GoogleAccountService();
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(ref.watch(dioProvider));
});

// --- Notes ---

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return ApiNotesRepository(ref.watch(dioProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(dioProvider));
});

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

final archivedNotesProvider = FutureProvider<List<Note>>((ref) async {
  ref.watch(authProvider.select((s) => s.user?.id));
  final repo = ref.read(notesRepositoryProvider);
  final all = await repo.list(includeArchived: true);
  return all.where((n) => n.isArchived).toList();
});

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    // Re-fetch (and discard cached notes) whenever the logged-in user changes,
    // so one account never sees another account's notes.
    ref.watch(authProvider.select((s) => s.user?.id));
    return _repository.list();
  }

  NotesRepository get _repository => ref.read(notesRepositoryProvider);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.list());
  }

  Future<void> addNote(Note note) async {
    final created = await _repository.create(note);
    final notes = state.value ?? const <Note>[];
    state = AsyncData([created, ...notes]);
  }

  Future<void> updateNote(Note updated) async {
    final saved = await _repository.update(updated);
    final notes = state.value ?? const <Note>[];
    state = AsyncData([
      for (final note in notes)
        if (note.id == saved.id) saved else note,
    ]);
  }

  Future<void> deleteNote(String id) async {
    await _repository.delete(id);
    final notes = state.value ?? const <Note>[];
    state = AsyncData(notes.where((n) => n.id != id).toList());
  }
}

// --- Theme ---

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

// --- Categories ---

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryItem>>(
      CategoriesNotifier.new,
    );

class CategoriesNotifier extends AsyncNotifier<List<CategoryItem>> {
  @override
  Future<List<CategoryItem>> build() {
    final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
    if (userId == null) return Future.value(const []);
    return ref.watch(categoriesRepositoryProvider).list();
  }

  Future<void> add(String name, IconData icon) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) throw StateError('Sign in to create a category');

    final category = await ref
        .read(categoriesRepositoryProvider)
        .create(name.trim(), icon.codePoint);
    if (ref.read(authProvider).user?.id != userId) return;
    state = AsyncData([
      ...state.asData?.value ?? const <CategoryItem>[],
      category,
    ]);
  }
}
