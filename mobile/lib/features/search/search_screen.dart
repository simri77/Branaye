import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_typography.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum SearchFilter { all, title, content, tags }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  SearchFilter _selectedFilter = SearchFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load recent searches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentSearchesProvider.notifier);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final results = ref.read(searchResultsProvider(
        ref.read(searchParamsProvider),
      ));
      if (results.hasValue && results.value!.hasMore) {
        ref.read(searchParamsProvider.notifier).nextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final params = ref.watch(searchParamsProvider);
    final resultsAsync = ref.watch(searchResultsProvider(params));
    final recentSearches = ref.watch(recentSearchesProvider);

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
      body: Column(
        children: [
          _SearchInput(
            controller: _controller,
            focusNode: _focusNode,
            query: _query,
            onChanged: (v) {
              setState(() => _query = v);
              ref.read(searchParamsProvider.notifier).updateQuery(v);
            },
            onClear: () {
              _controller.clear();
              setState(() => _query = '');
              ref.read(searchParamsProvider.notifier).updateQuery('');
            },
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                ref.read(recentSearchesProvider.notifier).addSearch(v.trim());
              }
            },
            recentSearches: recentSearches,
            onRecentTap: (recent) {
              _controller.text = recent;
              setState(() => _query = recent);
              ref.read(searchParamsProvider.notifier).updateQuery(recent);
              _focusNode.unfocus();
            },
            onClearHistory: () {
              ref.read(recentSearchesProvider.notifier).clearHistory();
            },
          ),
          _FilterChips(
            selected: _selectedFilter,
            onSelected: (f) => setState(() => _selectedFilter = f),
            categories: const ['Personal', 'Work', 'Study', 'Ideas'],
            selectedCategory: params.category,
            onCategorySelected: (cat) {
              ref.read(searchParamsProvider.notifier).updateCategory(cat);
            },
            selectedTags: params.tags,
            onTagSelected: (tag) {
              final newTags = params.tags.contains(tag)
                  ? params.tags.where((t) => t != tag).toList()
                  : [...params.tags, tag];
              ref.read(searchParamsProvider.notifier).updateTags(newTags);
            },
          ),
          Expanded(
            child: resultsAsync.when(
              loading: () => params.page == 1
                  ? const _LoadingSkeleton()
                  : _ResultList(
                      notes: const [],
                      query: _query,
                      onNoteTap: (note) => context.push('/editor?id=${note.id}'),
                      scrollController: _scrollController,
                      isLoadingMore: true,
                    ),
              error: (e, _) => _ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(searchResultsProvider(params)),
              ),
              data: (paginated) {
                final notes = paginated.data;
                return _query.isEmpty && params.category == null && params.tags.isEmpty
                    ? _ResultList(
                        notes: notes,
                        query: '',
                        onNoteTap: (note) => context.push('/editor?id=${note.id}'),
                        scrollController: _scrollController,
                        isLoadingMore: paginated.hasMore,
                      )
                    : notes.isEmpty
                        ? _EmptyState(
                            onClear: () {
                              _controller.clear();
                              _focusNode.unfocus();
                              ref.read(searchParamsProvider.notifier).reset();
                              setState(() {
                                _query = '';
                                _selectedFilter = SearchFilter.all;
                              });
                            },
                            hasFilters: params.category != null || params.tags.isNotEmpty,
                          )
                        : _ResultList(
                            notes: notes,
                            query: _query,
                            onNoteTap: (note) => context.push('/editor?id=${note.id}'),
                            scrollController: _scrollController,
                            isLoadingMore: paginated.hasMore,
                          );
              },
            ),
          ),
        ],
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
    required this.onSubmitted,
    required this.recentSearches,
    required this.onRecentTap,
    required this.onClearHistory,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final List<String> recentSearches;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final showRecent = focusNode.hasFocus && query.isEmpty && recentSearches.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
            onSubmitted: onSubmitted,
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
        ),
        if (showRecent) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackSm,
              AppSpacing.marginMobile,
              AppSpacing.stackSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent searches',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: onClearHistory,
                      child: Text(
                        'Clear',
                        style: textTheme.labelLarge?.copyWith(color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Wrap(
                  spacing: AppSpacing.stackSm,
                  runSpacing: AppSpacing.stackSm,
                  children: recentSearches.map((recent) {
                    return ActionChip(
                      label: Text(recent),
                      onPressed: () => onRecentTap(recent),
                      backgroundColor: colors.surfaceContainerHighest,
                      side: BorderSide(color: colors.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.selectedTags,
    required this.onTagSelected,
  });

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onSelected;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final List<String> selectedTags;
  final ValueChanged<String> onTagSelected;

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
            ...categories.map((cat) {
              final isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.gutter),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => onCategorySelected(isSelected ? null : cat),
                  labelStyle: textTheme.labelLarge?.copyWith(
                    color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                  ),
                  selectedColor: colors.primary,
                  backgroundColor: colors.surfaceContainerHighest,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded),
                  ),
                ),
              );
            }),
            if (selectedTags.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.gutter),
              Container(
                width: 1,
                height: 24,
                color: colors.outlineVariant,
              ),
              const SizedBox(width: AppSpacing.gutter),
              ...selectedTags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.gutter),
                  child: InputChip(
                    label: Text('#$tag'),
                    onPressed: () => onTagSelected(tag),
                    onDeleted: () => onTagSelected(tag),
                    labelStyle: textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                    ),
                    backgroundColor: colors.primaryContainer.withValues(alpha: 0.2),
                    deleteIconColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                );
              }),
            ],
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
    required this.scrollController,
    this.isLoadingMore = false,
  });

  final List<Note> notes;
  final String query;
  final ValueChanged<Note> onNoteTap;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: notes.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= notes.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.stackMd),
            child: Center(child: CircularProgressIndicator()),
          );
        }
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
                      return ActionChip(
                        label: Text('#$tag'),
                        onPressed: () {
                          // TODO: Navigate to search with this tag pre-selected
                        },
                        labelStyle: textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                        ),
                        backgroundColor: colors.primaryContainer.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.rounded),
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

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'Search failed',
              style: textTheme.headlineMedium?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear, this.hasFilters = false});

  final VoidCallback onClear;
  final bool hasFilters;

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
                  hasFilters ? 'No notes match your filters' : 'No notes found',
                  style: textTheme.headlineMedium?.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  hasFilters
                      ? 'Try adjusting your search or filters.'
                      : 'We couldn\'t find anything matching your search.\nTry different keywords or broader tags.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
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
                  child: Text(hasFilters ? 'Clear all filters' : 'Clear search'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}