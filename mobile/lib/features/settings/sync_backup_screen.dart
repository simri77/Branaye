import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_typography.dart';
import '../../data/api/google_drive_backup_service.dart';
import '../../data/providers.dart';
import '../search/search_providers.dart';

class SyncBackupScreen extends ConsumerStatefulWidget {
  const SyncBackupScreen({super.key});

  @override
  ConsumerState<SyncBackupScreen> createState() => _SyncBackupScreenState();
}

class _SyncBackupScreenState extends ConsumerState<SyncBackupScreen> {
  final _driveBackup = GoogleDriveBackupService();
  String? _driveAccessToken;
  DateTime? _lastBackup;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final key = _backupPreferenceKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(key);
    if (!mounted) return;
    setState(() {
      _lastBackup = timestamp == null ? null : DateTime.tryParse(timestamp);
    });
  }

  Future<void> _createBackup() async {
    setState(() => _isBusy = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw StateError('Sign in to back up your data.');
      final token =
          _driveAccessToken ??
          await ref.read(googleAccountServiceProvider).authorizeDrive();
      if (!mounted || token == null) return;
      setState(() => _driveAccessToken = token);
      final notes = await ref.read(notesRepositoryProvider).listAllForBackup();
      final categories = await ref.read(categoriesRepositoryProvider).list();
      final tags = await ref.read(apiRepositoryProvider).getTags();
      if (ref.read(authProvider).user?.id != user.id) {
        throw StateError('Account changed while preparing the backup.');
      }
      final backupTime = DateTime.now().toUtc();
      final backup = <String, dynamic>{
        'format': 'branaye-backup',
        'version': 1,
        'createdAt': backupTime.toIso8601String(),
        'account': {'id': user.id, 'email': user.email},
        'notes': [
          for (final note in notes)
            {
              'id': note.id,
              'title': note.title,
              'content': note.content,
              'category': note.category,
              'color':
                  '#${note.color.toARGB32().toRadixString(16).substring(2)}',
              'createdAt': note.createdAt.toIso8601String(),
              'isPinned': note.isPinned,
              'isFavorite': note.isFavorite,
              'isArchived': note.isArchived,
              'tags': note.tags,
            },
        ],
        'categories': [
          for (final category in categories)
            {
              'id': category.id,
              'name': category.name,
              'iconCodePoint': category.icon.codePoint,
            },
        ],
        'tags': [
          for (final tag in tags)
            {'id': tag.id, 'name': tag.name, 'color': tag.color},
        ],
      };

      await _driveBackup.uploadBackup(
        accessToken: token,
        accountId: user.id,
        backup: backup,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'drive_last_backup_${user.id}',
        backupTime.toIso8601String(),
      );
      if (!mounted) return;
      setState(() => _lastBackup = backupTime);
      _showMessage('Your Branaye backup was saved to Google Drive.');
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 && mounted) {
        setState(() => _driveAccessToken = null);
      }
      if (mounted) _showMessage('Google Drive backup failed: $error');
    } catch (error) {
      if (mounted) _showMessage('Google Drive backup failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isBusy = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw StateError('Sign in to restore your data.');
      final token =
          _driveAccessToken ??
          await ref.read(googleAccountServiceProvider).authorizeDrive();
      if (!mounted || token == null) return;
      setState(() => _driveAccessToken = token);
      final backup = await _driveBackup.downloadBackup(
        accessToken: token,
        accountId: user.id,
      );
      final backupAccount = backup['account'];
      if (backupAccount is! Map<String, dynamic> ||
          backupAccount['id'] != user.id) {
        throw FormatException(
          'This backup belongs to a different Branaye account.',
        );
      }

      final confirmed = await _confirmRestore(backup);
      if (!mounted || confirmed != true) return;
      if (ref.read(authProvider).user?.id != user.id) {
        throw StateError(
          'Account changed before the backup could be restored.',
        );
      }

      final result = await ref.read(backupRepositoryProvider).restore(backup);
      ref.invalidate(notesProvider);
      ref.invalidate(archivedNotesProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(allTagsProvider);
      ref.invalidate(popularTagsProvider);
      ref.invalidate(searchResultsProvider);
      if (!mounted) return;
      final restored = result['restored'] as Map<String, dynamic>;
      _showMessage(
        'Restored ${restored['notes']} notes, ${restored['tags']} tags, and ${restored['categories']} categories.',
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 && mounted) {
        setState(() => _driveAccessToken = null);
      }
      if (mounted) _showMessage('Google Drive restore failed: $error');
    } catch (error) {
      if (mounted) _showMessage('Google Drive restore failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool?> _confirmRestore(Map<String, dynamic> backup) {
    final noteCount = (backup['notes'] as List).length;
    final tagCount = (backup['tags'] as List).length;
    final categoryCount = (backup['categories'] as List).length;
    final createdAt = DateTime.parse(backup['createdAt'] as String).toLocal();

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace your Branaye data?'),
        content: Text(
          'Backup from $createdAt contains $noteCount notes, $tagCount tags, and $categoryCount categories. '
          'Restoring will permanently replace all notes, tags, and custom categories in this account. '
          'Create a new backup first if you may need the current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Replace data'),
          ),
        ],
      ),
    );
  }

  String? _backupPreferenceKey() {
    final userId = ref.read(authProvider).user?.id;
    return userId == null ? null : 'drive_last_backup_$userId';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final connected = _driveAccessToken != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Backup')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_outlined, color: colors.primary, size: 32),
                const SizedBox(height: AppSpacing.stackMd),
                Text('Google Drive backup', style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'Save a full Branaye backup file containing your notes, tags, and categories to your Google Drive.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  children: [
                    Icon(
                      connected ? Icons.check_circle : Icons.cloud_off,
                      color: connected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Text(
                      connected ? 'Google Drive connected' : 'Not connected',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  _lastBackup == null
                      ? 'No backup created on this device yet.'
                      : 'Last backup: ${_lastBackup!.toLocal()}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isBusy ? null : _createBackup,
                        icon: _isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isBusy
                              ? 'Working…'
                              : connected
                              ? 'Back up now'
                              : 'Connect & back up',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isBusy ? null : _restoreBackup,
                        icon: const Icon(Icons.settings_backup_restore),
                        label: const Text('Restore from Drive'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'The backup is stored as Branaye-backup.json in Google Drive. The first backup asks you to choose an account and grant access to the Branaye backup file.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
