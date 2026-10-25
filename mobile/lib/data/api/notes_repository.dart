import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Color;

import '../../core/models/note.dart';

/// Note persistence. The UI depends on this interface, never on Dio — so the
/// data source (mock or API) can be swapped without touching screens.
abstract class NotesRepository {
  Future<List<Note>> list({
    String? q,
    String? category,
    List<String>? tags,
    bool includeArchived = false,
    String sort = 'createdAt:desc',
  });

  Future<List<Note>> listAllForBackup();
  Future<Note> create(Note note);
  Future<Note> update(Note note);
  Future<void> delete(String id);
  Future<Note?> getById(String id);
}

/// Real implementation against the Notes CRUD API.
class ApiNotesRepository implements NotesRepository {
  ApiNotesRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Note>> listAllForBackup() async {
    final notes = <Note>[];
    var page = 1;
    var totalPages = 1;
    do {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notes',
        queryParameters: {
          'page': page,
          'limit': 100,
          'includeArchived': true,
          'sort': 'createdAt:asc',
        },
      );
      final result = response.data!;
      final data = result['data'] as List<dynamic>;
      notes.addAll(
        data.map((item) => Note.fromJson(item as Map<String, dynamic>)),
      );
      final meta = result['meta'] as Map<String, dynamic>;
      totalPages = meta['totalPages'] as int;
      page++;
    } while (page <= totalPages);
    return notes;
  }

  @override
  Future<List<Note>> list({
    String? q,
    String? category,
    List<String>? tags,
    bool includeArchived = false,
    String sort = 'createdAt:desc',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notes',
      queryParameters: {
        'limit': 100,
        'sort': sort,
        ...?q != null && q.isNotEmpty ? {'q': q} : null,
        ...?category == null ? null : {'category': category},
        ...?tags != null && tags.isNotEmpty ? {'tags': tags.join(',')} : null,
        if (includeArchived) 'includeArchived': true,
      },
    );
    final data = (response.data!['data'] as List<dynamic>);
    return data.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Note> create(Note note) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/notes',
      data: _toRequestBody(note),
    );
    return Note.fromJson(response.data!);
  }

  @override
  Future<Note> update(Note note) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/notes/${note.id}',
      data: _toRequestBody(note),
    );
    return Note.fromJson(response.data!);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/notes/$id');
  }

  @override
  Future<Note?> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/notes/$id');
      return Note.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Map<String, dynamic> _toRequestBody(Note note) {
    return {
      'title': note.title.isEmpty ? 'Untitled' : note.title,
      'content': note.content,
      'category': note.category,
      'color': hexFromColor(note.color),
      'isPinned': note.isPinned,
      'isFavorite': note.isFavorite,
      'isArchived': note.isArchived,
      'tags': note.tags,
    };
  }
}

/// `Color(0xFF464BD4)` -> `#464BD4` (the format the API validates).
String hexFromColor(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
