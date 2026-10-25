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
  bool _hideSensitiveContent = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySetting();
  }

  Future<void> _loadPrivacySetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hideSensitiveContent = prefs.getBool('security_hide_sensitive') ?? true;
    });
  }

  Future<void> _setHideSensitiveContent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('security_hide_sensitive', value);
    if (!mounted) return;
    setState(() => _hideSensitiveContent = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          _sectionTitle('ACCOUNT SECURITY', colors, textTheme),
          _settingsCard(
            colors,
            child: ListTile(
              leading: _leadingIcon(Icons.lock_reset, colors),
              title: Text(
                'Change Password',
                style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
              ),
              trailing: Icon(Icons.chevron_right, color: colors.outline),
              onTap: () => context.push('/settings/security/change-password'),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          _sectionTitle('PRIVACY', colors, textTheme),
          _settingsCard(
            colors,
            child: SwitchListTile(
              secondary: _leadingIcon(Icons.visibility_off, colors),
              title: Text(
                'Hide sensitive content',
                style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
              ),
              subtitle: Text(
                'Hide note content in system notifications',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              value: _hideSensitiveContent,
              onChanged: _setHideSensitiveContent,
              activeThumbColor: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
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

  Widget _settingsCard(ColorScheme colors, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }

  Widget _leadingIcon(IconData icon, ColorScheme colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colors.primary),
    );
  }
}
