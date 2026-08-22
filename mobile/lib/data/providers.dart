import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/note.dart';
import 'mock_notes.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

class CategoryItem {
  CategoryItem(this.name, this.iconCodePoint);
  final String name;
  final int iconCodePoint;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, List<CategoryItem>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends Notifier<List<CategoryItem>> {
  @override
  List<CategoryItem> build() => [];

  void add(String name, int iconCodePoint) {
    if (state.any((c) => c.name == name)) return;
    state = [...state, CategoryItem(name, iconCodePoint)];
  }
}

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
