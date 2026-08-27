import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _categoryNameController = TextEditingController();

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  void _showNewCategoryDialog() {
    _categoryNameController.clear();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    IconData selectedIcon = Icons.folder;

    final iconOptions = [
      Icons.folder,
      Icons.work,
      Icons.school,
      Icons.person,
      Icons.lightbulb,
      Icons.star,
      Icons.book,
      Icons.code,
      Icons.music_note,
      Icons.restaurant,
      Icons.flight,
      Icons.pets,
      Icons.sports_esports,
      Icons.shopping_bag,
      Icons.camera_alt,
      Icons.palette,
      Icons.fitness_center,
      Icons.travel_explore,
      Icons.health_and_safety,
      Icons.brush,
      Icons.park,
      Icons.coffee,
      Icons.science,
      Icons.auto_stories,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'New Category',
            style: textTheme.titleLarge?.copyWith(color: colors.onSurface),
          ),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose an icon',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: iconOptions.length,
                    itemBuilder: (context, index) {
                      final icon = iconOptions[index];
                      final isSelected =
                          selectedIcon == icon;
                      return InkWell(
                        onTap: () => setDialogState(
                            () => selectedIcon = icon),
                        borderRadius:
                            BorderRadius.circular(AppRadius.rounded),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primaryContainer
                                : colors.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(AppRadius.rounded),
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: isSelected
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text(
                    'Category name',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  TextField(
                    controller: _categoryNameController,
                    autofocus: true,
                    style:
                        textTheme.bodyLarge?.copyWith(color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'e.g. Recipes',
                      hintStyle: textTheme.bodyLarge
                          ?.copyWith(color: colors.outline),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.rounded),
                      ),
                    ),
                    onSubmitted: (_) => _createCategory(
                      dialogContext,
                      selectedIcon,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _createCategory(
                dialogContext,
                selectedIcon,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _createCategory(BuildContext dialogContext, IconData icon) {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(dialogContext);
    ref.read(categoriesProvider.notifier).add(name, icon);
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final customCategories = ref.watch(categoriesProvider);

    return Scaffold(
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load notes')),
        data: (notes) => _buildContent(context, notes, customCategories),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Note> notes,
    List<CategoryItem> customCategories,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoryData = [
      _CatInfo('Personal', Icons.person, colors.primary, colors.primary.withValues(alpha: 0.1)),
      _CatInfo('Work', Icons.work, colors.secondary, colors.secondary.withValues(alpha: 0.1)),
      _CatInfo('Study', Icons.school, colors.tertiary, colors.tertiary.withValues(alpha: 0.1)),
      _CatInfo('Ideas', Icons.lightbulb, colors.primary, colors.primaryContainer.withValues(alpha: 0.3)),
      ...customCategories.map((c) => _CatInfo(
            c.name,
            c.icon,
            colors.secondary,
            colors.secondaryContainer.withValues(alpha: 0.3),
          )),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        Text(
          'Categories',
          style: textTheme.displayLarge?.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Organize your thoughts efficiently.',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.gutter,
            mainAxisSpacing: AppSpacing.gutter,
            childAspectRatio: 1.0,
          ),
          itemCount: categoryData.length + 1,
          itemBuilder: (context, index) {
            if (index == categoryData.length) {
              return _AddCategoryCard(onTap: _showNewCategoryDialog);
            }
            final cat = categoryData[index];
            final count = notes.where((n) => n.category == cat.name).length;
            return _CategoryCard(
              category: cat,
              noteCount: count,
              onTap: () => _showCategoryNotes(
                context,
                cat.name,
                notes.where((n) => n.category == cat.name).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCategoryNotes(
    BuildContext context,
    String category,
    List<Note> notes,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.stackMd),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${notes.length} notes',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Text(
                          'No notes in this category',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.stackMd),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _NoteTile(
                            note: note,
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/editor?id=${note.id}');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatInfo {
  const _CatInfo(this.name, this.icon, this.iconColor, this.iconBg);
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.noteCount,
    required this.onTap,
  });

  final _CatInfo category;
  final int noteCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                ),
                child: Icon(category.icon, color: category.iconColor),
              ),
              const Spacer(),
              Text(
                category.name,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                '$noteCount Notes',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryCard extends StatelessWidget {
  const _AddCategoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: colors.outlineVariant,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 48, color: colors.outline),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'New Category',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
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
                      child: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (note.isPinned)
                      Icon(Icons.push_pin, size: 16, color: colors.primary),
                    if (note.isFavorite)
                      Icon(Icons.favorite, size: 16, color: colors.error),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
