import 'package:flutter/material.dart';

import '../../core/models/note.dart';
import '../../core/theme/app_typography.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, this.onTap});

  final Note note;
  final VoidCallback? onTap;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.stackSm / 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.rounded),
                    ),
                    child: Text(
                      note.category,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (note.isPinned)
                    Icon(Icons.push_pin, size: 20, color: colors.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: colors.outline),
                  const SizedBox(width: AppSpacing.stackSm),
                  Text(
                    _formatDate(note.createdAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
