import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum SearchFilter { all, title, content, tags }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  SearchFilter _selectedFilter = SearchFilter.all;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Note> _filterNotes(List<Note> notes) {
    final active = notes.where((n) => !n.isArchived).toList();
    if (_query.isEmpty) return active;
    final q = _query.toLowerCase();
    return active.where((note) {
      switch (_selectedFilter) {
        case SearchFilter.title:
          return note.title.toLowerCase().contains(q);
        case SearchFilter.content:
          return note.content.toLowerCase().contains(q);
        case SearchFilter.tags:
          return note.tags.any((t) => t.toLowerCase().contains(q));
        case SearchFilter.all:
          return note.title.toLowerCase().contains(q) ||
              note.content.toLowerCase().contains(q) ||
              note.tags.any((t) => t.toLowerCase().contains(q));
      }
    }).toList();
  }

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
        error: (e, _) => const Center(child: Text('Failed to load notes')),
        data: (notes) {
          final results = _filterNotes(notes);
          return Column(
            children: [
              _SearchInput(
                controller: _controller,
                focusNode: _focusNode,
                query: _query,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
              ),
              _FilterChips(
                selected: _selectedFilter,
                onSelected: (f) => setState(() => _selectedFilter = f),
              ),
              Expanded(
                child: _query.isEmpty
                    ? _ResultList(
                        notes: notes,
                        query: '',
                        onNoteTap: (note) =>
                            context.push('/editor?id=${note.id}'),
                      )
                    : results.isEmpty
                        ? _EmptyState(onClear: () {
                            _controller.clear();
                            _focusNode.unfocus();
                            setState(() {
                              _query = '';
                              _selectedFilter = SearchFilter.all;
                            });
                          })
                        : _ResultList(
                            notes: results,
                            query: _query,
                            onNoteTap: (note) =>
                                context.push('/editor?id=${note.id}'),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.stackMd,
        AppSpacing.marginMobile,
        0,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: textTheme.titleMedium?.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: 'Search your notes...',
          hintStyle: textTheme.titleMedium?.copyWith(color: colors.outline),
          prefixIcon: Icon(Icons.search, color: colors.primary),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: colors.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd,
            vertical: AppSpacing.base,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.stackMd,
        0,
        0,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in SearchFilter.values) ...[
              if (filter != SearchFilter.values.first)
                const SizedBox(width: AppSpacing.gutter),
              ChoiceChip(
                label: Text(
                  filter.name[0].toUpperCase() + filter.name.substring(1),
                ),
                selected: filter == selected,
                onSelected: (_) => onSelected(filter),
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: filter == selected
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                ),
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceContainerHighest,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.gutter),
            Container(
              width: 1,
              height: 24,
              color: colors.outlineVariant,
            ),
            const SizedBox(width: AppSpacing.gutter),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.tune, size: 18, color: colors.primary),
              label: Text(
                'Filters',
                style: textTheme.labelLarge?.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.notes,
    required this.query,
    required this.onNoteTap,
  });

  final List<Note> notes;
  final String query;
  final ValueChanged<Note> onNoteTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _ResultCard(
          note: note,
          query: query,
          onTap: () => onNoteTap(note),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.note,
    required this.query,
    required this.onTap,
  });

  final Note note;
  final String query;
  final VoidCallback onTap;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${_months[date.month - 1]} ${date.day}';
  }

  TextSpan _highlightText(
    String text,
    String query,
    TextStyle style,
    Color highlightColor,
  ) {
    if (query.isEmpty) return TextSpan(text: text, style: style);
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: style.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + q.length;
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      child: Material(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        text: _highlightText(
                          note.title,
                          query,
                          textTheme.titleMedium!.copyWith(
                            color: colors.onSurface,
                          ),
                          colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Text(
                      _relativeTime(note.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                RichText(
                  text: _highlightText(
                    note.content,
                    query,
                    textTheme.bodyMedium!.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    colors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.stackMd),
                  Wrap(
                    spacing: AppSpacing.stackSm,
                    runSpacing: AppSpacing.stackSm,
                    children: note.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.stackSm / 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppRadius.rounded),
                        ),
                        child: Text(
                          '#$tag',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 300),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 64,
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'No notes found',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'We couldn\'t find anything matching your search.\nTry different keywords or broad tags.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                FilledButton(
                  onPressed: onClear,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  child: const Text('Clear all filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
