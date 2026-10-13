import 'package:flutter/material.dart';

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.createdAt,
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.tags = const [],
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'Ideas',
      color: _parseColor(json['color'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF464BD4);
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) {
      buffer.write('FF');
      buffer.write(hex.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Note copyWith({
    String? title,
    String? content,
    String? category,
    Color? color,
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    List<String>? tags,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
    );
  }

  final String id;
  final String title;
  final String content;
  final String category;
  final Color color;
  final DateTime createdAt;
  final bool isPinned;
  final bool isFavorite;
  final bool isArchived;
  final List<String> tags;
}
