import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_typography.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _appLock = true;
  bool _biometricUnlock = true;
  bool _hideSensitiveContent = true;
  String _lockoutTiming = 'immediately';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _appLock = prefs.getBool('security_app_lock') ?? true;
        _biometricUnlock = prefs.getBool('security_biometric_unlock') ?? true;
        _hideSensitiveContent = prefs.getBool('security_hide_sensitive') ?? true;
        _lockoutTiming = prefs.getString('security_lockout_timing') ?? 'immediately';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Security'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Security',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('APP PROTECTION', colors, textTheme),
            _buildProtectionSection(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildSectionHeader('PRIVACY', colors, textTheme),
            _buildPrivacySection(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildSectionHeader('LOCKOUT TIMING', colors, textTheme),
            _buildLockoutSection(colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colors, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Text(
        title,
        style: textTheme.labelLarge?.copyWith(
          color: colors.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProtectionSection(ColorScheme colors, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleTile(
            icon: Icons.lock,
            title: 'App Lock',
            subtitle: 'Require PIN or biometrics to open',
            value: _appLock,
            onChanged: (value) {
              setState(() => _appLock = value);
              _saveSetting('security_app_lock', value);
            },
            colors: colors,
            textTheme: textTheme,
            showDivider: true,
          ),
          _buildToggleTile(
            icon: Icons.fingerprint,
            title: 'Biometric Unlock',
            subtitle: 'Use Fingerprint or Face ID',
            value: _biometricUnlock,
            onChanged: (value) {
              setState(() => _biometricUnlock = value);
              _saveSetting('security_biometric_unlock', value);
            },
            colors: colors,
            textTheme: textTheme,
            showDivider: false,
          ),
          _buildActionTile(
            icon: Icons.pin,
            title: 'Change PIN',
            onTap: () {
              context.push('/settings/security/change-pin');
            },
            colors: colors,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(ColorScheme colors, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildToggleTile(
        icon: Icons.visibility_off,
        title: 'Hide sensitive content',
        subtitle: 'Hide note content in system notifications when locked',
        value: _hideSensitiveContent,
        onChanged: (value) {
          setState(() => _hideSensitiveContent = value);
          _saveSetting('security_hide_sensitive', value);
        },
        colors: colors,
        textTheme: textTheme,
        showDivider: false,
      ),
    );
  }

  Widget _buildLockoutSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            children: [
              _buildRadioTile(
                title: 'Immediately',
                value: 'immediately',
                groupValue: _lockoutTiming,
                onChanged: (value) {
                  setState(() => _lockoutTiming = value!);
                  _saveSetting('security_lockout_timing', value);
                },
                colors: colors,
                textTheme: textTheme,
              ),
              _buildRadioTile(
                title: 'After 1 minute',
                value: '1min',
                groupValue: _lockoutTiming,
                onChanged: (value) {
                  setState(() => _lockoutTiming = value!);
                  _saveSetting('security_lockout_timing', value);
                },
                colors: colors,
                textTheme: textTheme,
              ),
              _buildRadioTile(
                title: 'After 5 minutes',
                value: '5min',
                groupValue: _lockoutTiming,
                onChanged: (value) {
                  setState(() => _lockoutTiming = value!);
                  _saveSetting('security_lockout_timing', value);
                },
                colors: colors,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          child: Text(
            'When Branaye is in the background, it will require a lock after this duration.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colors,
    required TextTheme textTheme,
    required bool showDivider,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.2),
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackMd,
          vertical: AppSpacing.stackSm,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.primary),
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colors.primary,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stackMd,
        vertical: AppSpacing.stackSm,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.primary),
      ),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colors.outline,
      ),
      onTap: onTap,
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return RadioGroup<String>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: RadioListTile<String>(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackMd,
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
        value: value,
      ),
    );
  }
}
