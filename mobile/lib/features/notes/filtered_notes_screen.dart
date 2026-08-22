import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import '../widgets/note_card.dart';

enum FilterMode { favorites, archived }

class FilteredNotesScreen extends ConsumerWidget {
  const FilteredNotesScreen({
    super.key,
    required this.mode,
  });

  final FilterMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final title = mode == FilterMode.favorites ? 'Favorites' : 'Archived';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: textTheme.titleLarge?.copyWith(color: colors.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load notes')),
        data: (notes) {
          final filtered = mode == FilterMode.favorites
              ? notes.where((n) => n.isFavorite).toList()
              : notes.where((n) => n.isArchived).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode == FilterMode.favorites
                        ? Icons.favorite_border
                        : Icons.archive_outlined,
                    size: 64,
                    color: colors.outlineVariant,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text(
                    mode == FilterMode.favorites
                        ? 'No favorite notes yet'
                        : 'No archived notes',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            itemCount: filtered.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.gutter),
            itemBuilder: (context, index) {
              final note = filtered[index];
              return NoteCard(
                note: note,
                onTap: () => context.push('/editor?id=${note.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
