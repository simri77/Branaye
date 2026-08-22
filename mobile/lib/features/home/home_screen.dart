import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import '../widgets/note_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<String> _categories = [
    'All',
    'Personal',
    'Work',
    'Study',
    'Ideas',
  ];

  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Branaye',
          style: textTheme.headlineMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colors.surface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/editor'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.rounded),
        ),
        child: const Icon(Icons.add, size: 32),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load notes')),
        data: (notes) => _buildContent(context, notes),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Note> notes) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final pinned = notes.where((n) => n.isPinned && !n.isArchived).toList();
    final favorites = notes.where((n) => n.isFavorite && !n.isArchived).toList();
    final visible = (_selectedCategory == 'All'
            ? notes
            : notes.where((n) => n.category == _selectedCategory))
        .where((n) => !n.isArchived)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        Text(
          'Good morning, Alex',
          style: textTheme.headlineMedium?.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'You have ${notes.length} notes in your collection today.',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),

        _CategoryChips(
          categories: _categories,
          selected: _selectedCategory,
          onSelected: (category) =>
              setState(() => _selectedCategory = category),
        ),
        const SizedBox(height: AppSpacing.stackLg),

        if (pinned.isNotEmpty) ...[
          const _SectionHeader(icon: Icons.push_pin, title: 'Pinned Notes'),
          const SizedBox(height: AppSpacing.stackMd),
          NoteCard(
            note: pinned.first,
            onTap: () => context.push('/editor?id=${pinned.first.id}'),
          ),
          const SizedBox(height: AppSpacing.stackLg),
        ],

        if (favorites.isNotEmpty) ...[
          const _SectionHeader(icon: Icons.favorite, title: 'Favorites'),
          const SizedBox(height: AppSpacing.stackMd),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.gutter),
              itemBuilder: (context, index) {
                final note = favorites[index];
                return SizedBox(
                  width: 160,
                  child: _CompactFavoriteCard(
                    note: note,
                    onTap: () => context.push('/editor?id=${note.id}'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
        ],

        const _SectionHeader(icon: Icons.history, title: 'Recent Notes'),
        const SizedBox(height: AppSpacing.stackMd),
        _MasonryGrid(
          notes: visible,
          onNoteTap: (note) => context.push('/editor?id=${note.id}'),
        ),
        const SizedBox(height: AppSpacing.stackLg),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            if (category != categories.first)
              const SizedBox(width: AppSpacing.gutter),
            ChoiceChip(
              label: Text(category),
              selected: category == selected,
              onSelected: (_) => onSelected(category),
              labelStyle: textTheme.labelLarge?.copyWith(
                color: category == selected
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
              ),
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceContainer,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: AppSpacing.base),
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}

class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({required this.notes, required this.onNoteTap});

  final List<Note> notes;
  final ValueChanged<Note> onNoteTap;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
        child: Center(
          child: Text(
            'No notes in this category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final left = <Note>[];
    final right = <Note>[];
    for (var i = 0; i < notes.length; i++) {
      if (i.isEven) {
        left.add(notes[i]);
      } else {
        right.add(notes[i]);
      }
    }

    Widget column(List<Note> column) {
      return Expanded(
        child: Column(
          children: [
            for (final note in column) ...[
              NoteCard(note: note, onTap: () => onNoteTap(note)),
              const SizedBox(height: AppSpacing.gutter),
            ],
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        column(left),
        const SizedBox(width: AppSpacing.gutter),
        column(right),
      ],
    );
  }
}

class _CompactFavoriteCard extends StatelessWidget {
  const _CompactFavoriteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wash = isDark
        ? Color.alphaBlend(note.color.withValues(alpha: 0.2), colors.surface)
        : note.color;

    return Material(
      color: wash,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark
                  ? colors.outlineVariant
                  : colors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.rounded),
                      ),
                      child: Text(
                        note.category,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Icon(Icons.favorite, size: 16, color: colors.error),
                ],
              ),
              const Spacer(),
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
