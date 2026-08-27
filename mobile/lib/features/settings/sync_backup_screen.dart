import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';

class SyncBackupScreen extends ConsumerStatefulWidget {
  const SyncBackupScreen({super.key});

  @override
  ConsumerState<SyncBackupScreen> createState() => _SyncBackupScreenState();
}

class _SyncBackupScreenState extends ConsumerState<SyncBackupScreen> {
  bool _autoSync = false;
  bool _syncWifiOnly = false;
  bool _includeAttachments = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);
    final userEmail = auth.user?.email ?? 'user@example.com';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Sync & Backup',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncStatusCard(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildSectionTitle('Sync Preferences', colors, textTheme),
            const SizedBox(height: AppSpacing.stackMd),
            _buildSyncPreferencesCard(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildSectionTitle('Cloud Provider', colors, textTheme),
            const SizedBox(height: AppSpacing.stackMd),
            _buildCloudProviderCard(colors, textTheme, userEmail),
            const SizedBox(height: AppSpacing.stackLg),
            _buildManualBackupButton(colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(ColorScheme colors, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryContainer,
            ),
            child: Icon(
              Icons.cloud_done,
              size: 32,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'All notes synced',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Your data is backed up and up to date.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Text(
                'Last sync: Today, 10:42 AM',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Implement sync
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing...')),
                );
              },
              icon: const Icon(Icons.sync, size: 20),
              label: Text(
                'Sync Now',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.stackMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, ColorScheme colors, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSyncPreferencesCard(ColorScheme colors, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildToggleTile(
            title: 'Auto Sync',
            subtitle: 'Keep changes synced in real-time',
            value: _autoSync,
            onChanged: (value) => setState(() => _autoSync = value),
            colors: colors,
            textTheme: textTheme,
            showDivider: true,
          ),
          _buildToggleTile(
            title: 'Sync over Wi-Fi only',
            subtitle: 'Save cellular data',
            value: _syncWifiOnly,
            onChanged: (value) => setState(() => _syncWifiOnly = value),
            colors: colors,
            textTheme: textTheme,
            showDivider: true,
          ),
          _buildToggleTile(
            title: 'Include Attachments',
            subtitle: 'Sync images and files',
            value: _includeAttachments,
            onChanged: (value) => setState(() => _includeAttachments = value),
            colors: colors,
            textTheme: textTheme,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colors,
    required TextTheme textTheme,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd,
          ),
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: colors.surfaceContainerHighest,
          ),
      ],
    );
  }

  Widget _buildCloudProviderCard(
      ColorScheme colors, TextTheme textTheme, String email) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                ),
                child: Icon(
                  Icons.cloud,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Drive',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      email,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement unlink
                },
                child: Text(
                  'Unlink',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Used',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    '45 MB of 15 GB',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: LinearProgressIndicator(
                  value: 45 / 15000,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualBackupButton(ColorScheme colors, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO: Implement manual backup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creating backup...')),
          );
        },
        icon: Icon(
          Icons.download,
          color: colors.primary,
        ),
        label: Text(
          'Create Manual Local Backup',
          style: textTheme.labelLarge?.copyWith(
            color: colors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.stackMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}
