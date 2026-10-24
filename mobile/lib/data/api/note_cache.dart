import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/models/note.dart';

class NoteCache {
  static const _boxName = 'notes_cache';
  static const _key = 'notes';

  Future<Box<String>> _box() async =>
      Hive.isBoxOpen(_boxName) ? Hive.box<String>(_boxName) : await Hive.openBox<String>(_boxName);

  Future<void> save(List<Note> notes) async {
    final box = await _box();
    final json = jsonEncode(notes.map((n) => n.toJson()).toList());
    await box.put(_key, json);
  }

  Future<List<Note>?> load() async {
    final box = await _box();
    final raw = box.get(_key);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }
}
