import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/api/dio_provider.dart';
import '../../data/providers.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  Note? _existingNote;
  bool _isLoaded = false;

  Color _selectedColor = AppColors.noteWashWork;
  String _selectedCategory = 'Ideas';
  List<String> _selectedTags = [];
  bool _showColorPicker = false;
  bool _showCategoryPicker = false;
  bool _showTagPicker = false;

  static const List<Color> _noteColors = [
    AppColors.noteWashWork,
    AppColors.noteWashPersonal,
    AppColors.noteWashStudy,
    AppColors.noteWashIdeas,
  ];

  Color _editorBackground(bool isDark) {
    if (isDark) {
      return Color.alphaBlend(_selectedColor.withValues(alpha: 0.15), AppColors.darkSurface);
    }
    return _selectedColor;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoaded) return;
    _isLoaded = true;

    final id = GoRouterState.of(context).uri.queryParameters['id'];
    if (id != null) {
      Note? cached;
      for (final note in ref.read(notesProvider).value ?? const <Note>[]) {
        if (note.id == id) {
          cached = note;
          break;
        }
      }
      if (cached != null) {
        _applyNote(cached);
      } else {
        _fetchNote(id);
      }
    }
  }

  /// Deep links and post-refresh opens may not have the note in memory yet.
  Future<void> _fetchNote(String id) async {
    try {
      final note = await ref.read(notesRepositoryProvider).getById(id);
      if (!mounted || note == null) return;
      _applyNote(note);
    } catch (error) {
      _showError(error);
    }
  }

  void _applyNote(Note note) {
    setState(() {
      _existingNote = note;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedColor = note.color;
      _selectedCategory = note.category;
      _selectedTags = List.from(note.tags);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is DioException
        ? messageForDioError(error)
        : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      context.pop();
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_existingNote != null) {
        final updated = _existingNote!.copyWith(
          title: title.isEmpty ? 'Untitled' : title,
          content: content,
          category: _selectedCategory,
          color: _selectedColor,
          tags: _selectedTags,
        );
        await ref.read(notesProvider.notifier).updateNote(updated);
      } else {
        final note = Note(
          id: '',
          title: title.isEmpty ? 'Untitled' : title,
          content: content,
          category: _selectedCategory,
          color: _selectedColor,
          createdAt: DateTime.now(),
          tags: _selectedTags,
        );
        await ref.read(notesProvider.notifier).addNote(note);
      }
      if (!mounted) return;
      context.pop();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _togglePin() async {
    if (_existingNote == null) return;
    final previous = _existingNote!;
    final next = previous.copyWith(isPinned: !previous.isPinned);
    setState(() => _existingNote = next);
    try {
      await ref.read(notesProvider.notifier).updateNote(next);
    } catch (error) {
      setState(() => _existingNote = previous);
      _showError(error);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_existingNote == null) return;
    final previous = _existingNote!;
    final next = previous.copyWith(isFavorite: !previous.isFavorite);
    setState(() => _existingNote = next);
    try {
      await ref.read(notesProvider.notifier).updateNote(next);
    } catch (error) {
      setState(() => _existingNote = previous);
      _showError(error);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  void _showMoreOptions() {
    final isArchived = _existingNote?.isArchived ?? false;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isArchived ? Icons.unarchive : Icons.archive),
              title: Text(isArchived ? 'Unarchive' : 'Archive'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (_existingNote == null) return;
                final next = _existingNote!.copyWith(isArchived: !isArchived);
                setState(() => _existingNote = next);
                try {
                  await ref.read(notesProvider.notifier).updateNote(next);
                  if (!mounted) return;
                  if (!isArchived) context.pop();
                } catch (error) {
                  _showError(error);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (_existingNote == null) return;
                try {
                  await ref
                      .read(notesProvider.notifier)
                      .deleteNote(_existingNote!.id);
                  if (!mounted) return;
                  context.pop();
                } catch (error) {
                  _showError(error);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(sheetContext),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (_existingNote == null) return;
                final note = Note(
                  id: '',
                  title: '${_existingNote!.title} (copy)',
                  content: _existingNote!.content,
                  category: _existingNote!.category,
                  color: _existingNote!.color,
                  createdAt: DateTime.now(),
                  tags: _existingNote!.tags,
                );
                try {
                  await ref.read(notesProvider.notifier).addNote(note);
                  if (!mounted) return;
                  context.pop();
                } catch (error) {
                  _showError(error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _editorBackground(isDark);
    final textColor = isDark ? colors.onSurface : AppColors.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.push_pin,
              color: _existingNote?.isPinned == true
                  ? colors.primary
                  : textColor.withValues(alpha: 0.6),
            ),
            onPressed: _togglePin,
          ),
          IconButton(
            icon: Icon(
              _existingNote?.isFavorite == true
                  ? Icons.favorite
                  : Icons.favorite_outline,
              color: _existingNote?.isFavorite == true
                  ? colors.error
                  : textColor.withValues(alpha: 0.6),
            ),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: AppSpacing.base),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: textTheme.headlineMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: textTheme.headlineMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                TextField(
                  controller: _contentController,
                  style: textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start typing...',
                    hintStyle: textTheme.bodyLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.3),
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  minLines: 15,
                ),
              ],
            ),
          ),

          // Tag picker overlay
          if (_showTagPicker)
            GestureDetector(
              onTap: () => setState(() => _showTagPicker = false),
              child: Container(
                color: Colors.black26,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Tags',
                            style: textTheme.titleLarge?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          // Current tags
                          if (_selectedTags.isNotEmpty) ...[
                            Wrap(
                              spacing: AppSpacing.stackSm,
                              runSpacing: AppSpacing.stackSm,
                              children: _selectedTags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removeTag(tag),
                                  backgroundColor: colors.primaryContainer,
                                  labelStyle: textTheme.labelLarge?.copyWith(
                                    color: colors.onPrimaryContainer,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                          ],
                          // Add tag input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagController,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Add a tag...',
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: colors.outline,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.rounded,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.stackMd,
                                      vertical: AppSpacing.base,
                                    ),
                                  ),
                                  onSubmitted: (_) => _addTag(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.stackSm),
                              IconButton(
                                onPressed: _addTag,
                                icon: Icon(
                                  Icons.add_circle,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Category picker overlay
          if (_showCategoryPicker)
            GestureDetector(
              onTap: () => setState(() => _showCategoryPicker = false),
              child: Container(
                color: Colors.black26,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Select Category',
                            style: textTheme.titleLarge?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          Wrap(
                            spacing: AppSpacing.stackSm,
                            runSpacing: AppSpacing.stackSm,
                            children: ['Personal', 'Work', 'Study', 'Ideas', ...ref.read(categoriesProvider).map((c) => c.name)].map((cat) {
                              final isSelected = cat == _selectedCategory;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = cat;
                                    _showCategoryPicker = false;
                                  });
                                },
                                selectedColor: colors.primary,
                                backgroundColor: colors.surfaceContainerHighest,
                                labelStyle: textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant,
                                ),
                                showCheckmark: false,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Color picker overlay
          if (_showColorPicker)
            GestureDetector(
              onTap: () => setState(() => _showColorPicker = false),
              child: Container(
                color: Colors.black26,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Select Color',
                            style: textTheme.titleLarge?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _noteColors.map((color) {
                              final isSelected = color == _selectedColor;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.stackSm,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedColor = color;
                                      _showColorPicker = false;
                                    });
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? colors.primary
                                            : colors.outlineVariant,
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(Icons.check, color: colors.primary)
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _EditorToolbar(
        onCategoryTap: () => setState(() {
          _showCategoryPicker = true;
          _showColorPicker = false;
          _showTagPicker = false;
        }),
        onColorTap: () => setState(() {
          _showColorPicker = true;
          _showCategoryPicker = false;
          _showTagPicker = false;
        }),
        onTagTap: () => setState(() {
          _showTagPicker = true;
          _showColorPicker = false;
          _showCategoryPicker = false;
        }),
        onMoreTap: _showMoreOptions,
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.onCategoryTap,
    required this.onColorTap,
    required this.onTagTap,
    required this.onMoreTap,
  });

  final VoidCallback onCategoryTap;
  final VoidCallback onColorTap;
  final VoidCallback onTagTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.stackSm,
        AppSpacing.marginMobile,
        MediaQuery.of(context).padding.bottom + AppSpacing.stackSm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.folder_open,
            label: 'Categories',
            onTap: onCategoryTap,
          ),
          _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.palette,
            label: 'Color',
            onTap: onColorTap,
          ),
          _ToolbarButton(
            icon: Icons.sell,
            label: 'Tags',
            onTap: onTagTap,
          ),
          _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.more_vert,
            label: 'More',
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.rounded),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Icon(icon, color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
