import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/note.dart';
import 'api/auth_repository.dart';
import 'api/dio_provider.dart';
import 'api/fcm_service.dart';
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
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // A 401 from any request means our token is no longer good: drop it.
    ref.watch(sessionEventsProvider).onUnauthorized.listen((_) => logout());
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Called once at startup, before the first frame, to restore a saved session.
  Future<void> restoreSession() async {
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null || token.isEmpty) return;

    state = AuthState(status: AuthStatus.loading);
    try {
      final user = await _repository.me();
      state = AuthState(status: AuthStatus.authenticated, user: _toUser(user));
      ref.read(fcmServiceProvider).init();
    } on DioException catch (error) {
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
    return _authenticate(
      () => _repository.register(name: name, email: email, password: password),
    );
  }

  Future<bool> _authenticate(Future<AuthSession> Function() call) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final session = await call();
      await ref.read(tokenStoreProvider).write(session.accessToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: _toUser(session.user),
      );
      ref.invalidate(notesProvider);
      _notifyRouter();
      // Register FCM token (best-effort, non-blocking).
      ref.read(fcmServiceProvider).init();
      return true;
    } on DioException catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: messageForDioError(error),
      );
      _notifyRouter();
      return false;
    }
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

  void logout() {
    ref.read(tokenStoreProvider).clear();
    state = const AuthState();
    ref.invalidate(notesProvider);
    _notifyRouter();
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

// --- Notes ---

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return ApiNotesRepository(ref.watch(dioProvider));
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

// --- Text Size ---

enum TextSizeOption { small, defaultSize, extraLarge }

final textSizeProvider =
    NotifierProvider<TextSizeNotifier, TextSizeOption>(
  TextSizeNotifier.new,
);

class TextSizeNotifier extends Notifier<TextSizeOption> {
  @override
  TextSizeOption build() => TextSizeOption.defaultSize;

  Future<void> loadSavedSize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('text_size_option') ?? 1;
    state = TextSizeOption.values[savedIndex];
  }

  Future<void> setSize(TextSizeOption size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('text_size_option', size.index);
  }
}

// --- Categories ---

class CategoryItem {
  const CategoryItem(this.name, this.icon);
  final String name;
  final IconData icon;
}

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, List<CategoryItem>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends Notifier<List<CategoryItem>> {
  @override
  List<CategoryItem> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('custom_categories') ?? [];
    state = names.map((n) => CategoryItem(n, Icons.folder)).toList();
  }

  void add(String name, IconData icon) {
    if (state.any((c) => c.name == name)) return;
    state = [...state, CategoryItem(name, icon)];
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_categories', state.map((c) => c.name).toList());
  }
}
