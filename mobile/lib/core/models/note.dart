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
