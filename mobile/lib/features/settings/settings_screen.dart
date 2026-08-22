import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          Text(
            'Settings',
            style: textTheme.headlineMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Manage your workspace and account preferences.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),

          // Appearance toggle
          _SettingsTile(
            icon: Icons.palette,
            title: 'Appearance',
            subtitle: isDark ? 'Dark mode' : 'Light mode',
            trailing: Switch(
              value: isDark,
              onChanged: (isDark) {
                ref.read(themeModeProvider.notifier).setMode(
                      isDark ? ThemeMode.dark : ThemeMode.light,
                    );
              },
              activeThumbColor: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.format_size,
            title: 'Text Size',
            subtitle: 'Medium (Default)',
            trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'Sync & Backup',
            subtitle: 'Last synced: 2 mins ago',
            trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English (US)',
            trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About Branaye',
            subtitle: 'Version 1.0.0',
            trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () {},
          ),

          // Statistics
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            'Statistics',
            style: textTheme.titleLarge?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          notesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (notes) {
              final active = notes.where((n) => !n.isArchived).length;
              final archived = notes.where((n) => n.isArchived).length;
              final favorites = notes.where((n) => n.isFavorite).length;
              return _StatisticsSection(
                totalNotes: active,
                archivedCount: archived,
                favoritesCount: favorites,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

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
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({
    required this.totalNotes,
    required this.archivedCount,
    required this.favoritesCount,
  });

  final int totalNotes;
  final int archivedCount;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Total Notes - full width
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Notes',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '$totalNotes',
                    style: textTheme.displayLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(
                  Icons.description,
                  size: 120,
                  color: colors.onPrimaryContainer.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),

        // Archived + Favorites
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.archive,
                iconColor: colors.secondary,
                label: 'Archived',
                value: '$archivedCount',
                backgroundColor: colors.surfaceContainer,
                onTap: () => context.push('/archived'),
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: _StatCard(
                icon: Icons.favorite,
                iconColor: colors.tertiary,
                label: 'Favorites',
                value: '$favoritesCount',
                backgroundColor: colors.surfaceContainer,
                onTap: () => context.push('/favorites'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.backgroundColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
