import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
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
    final auth = ref.watch(authProvider);

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

          // --- Account Section (visible when logged in) ---
          if (auth.isLoggedIn && auth.user != null) ...[
            Text(
              'Account',
              style: textTheme.titleLarge?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackMd),

            // Profile Summary
            Material(
              color: colors.surfaceContainerLowest,
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
                    _ProfileAvatar(email: auth.user!.email),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user!.name,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            auth.user!.email,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),

            // Personal Information
            _SettingsTile(
              icon: Icons.person,
              title: 'Personal Information',
              trailing:
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              onTap: () => context.push('/settings/personal-info'),
            ),
            const SizedBox(height: AppSpacing.gutter),

            // Subscription
            _SettingsTile(
              icon: Icons.workspace_premium,
              title: 'Subscription',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'PRO',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
              onTap: () => context.push('/settings/subscription'),
            ),
            const SizedBox(height: AppSpacing.gutter),

            // Change Password
            _SettingsTile(
              icon: Icons.lock_reset,
              title: 'Change Password',
              trailing:
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              onTap: () => context.push('/settings/change-password'),
            ),
            const SizedBox(height: AppSpacing.stackLg),
          ],

          // --- General Settings ---
          _SettingsTile(
            icon: Icons.palette,
            title: 'Appearance',
            subtitle: 'Toggle light or dark mode',
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
            trailing:
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () => context.push('/settings/text-size'),
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'Sync & Backup',
            subtitle: 'Last synced: 2 mins ago',
            trailing:
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () => context.push('/settings/sync-backup'),
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English (US)',
            trailing:
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () => context.push('/settings/language'),
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.lock,
            title: 'Security',
            subtitle: 'App lock, fingerprint, and privacy',
            trailing:
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () => context.push('/settings/security'),
          ),
          const SizedBox(height: AppSpacing.gutter),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About Branaye',
            subtitle: 'Version 2.4.0',
            trailing:
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            onTap: () => context.push('/settings/about'),
          ),
          const SizedBox(height: AppSpacing.gutter),

          // Sign Out
          Material(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              onTap: () {
                ref.read(authProvider.notifier).logout();
                authRefreshNotifier.value++;
              },
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
                        borderRadius:
                            BorderRadius.circular(AppRadius.rounded),
                      ),
                      child: Icon(Icons.logout, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Text(
                      'Sign Out',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
                child: subtitle != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            subtitle!,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                        ),
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
                      color:
                          colors.onPrimaryContainer.withValues(alpha: 0.8),
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

class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar({required this.email});

  final String email;

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (mounted) {
      setState(() {
        _imagePath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get first letter of email for avatar
    final initial = widget.email.isNotEmpty ? widget.email[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: colors.primaryContainer,
      backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
      child: _imagePath == null
          ? Text(
              initial,
              style: textTheme.titleMedium?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}
