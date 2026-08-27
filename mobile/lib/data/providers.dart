import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/note.dart';
import 'mock_notes.dart';

// --- Auth State ---

class UserModel {
  const UserModel({
    required this.name,
    required this.email,
  });
  final String name;
  final String email;
}

class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.user,
  });
  final bool isLoggedIn;
  final UserModel? user;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void login(String email, String password) {
    // Extract name from email (part before @)
    final name = email.split('@').first;
    state = AuthState(
      isLoggedIn: true,
      user: UserModel(
        name: name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'User',
        email: email,
      ),
    );
  }

  void register(String name, String email, String password) {
    state = AuthState(
      isLoggedIn: true,
      user: UserModel(name: name, email: email),
    );
  }

  void updateProfile({String? name, String? email}) {
    if (state.user == null) return;
    state = AuthState(
      isLoggedIn: state.isLoggedIn,
      user: UserModel(
        name: name ?? state.user!.name,
        email: email ?? state.user!.email,
      ),
    );
  }

  void logout() {
    state = const AuthState();
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

  void setSize(TextSizeOption size) => state = size;
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
  List<CategoryItem> build() => [];

  void add(String name, IconData icon) {
    if (state.any((c) => c.name == name)) return;
    state = [...state, CategoryItem(name, icon)];
  }
}

// --- Notes ---

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    return MockNoteRepository().getAll();
  }

  Future<void> addNote(Note note) async {
    state = AsyncData([...state.value ?? const [], note]);
  }

  Future<void> updateNote(Note updated) async {
    final notes = state.value ?? const [];
    state = AsyncData([
      for (final note in notes)
        if (note.id == updated.id) updated else note,
    ]);
  }

  Future<void> deleteNote(String id) async {
    final notes = state.value ?? const [];
    state = AsyncData(notes.where((n) => n.id != id).toList());
  }
}
