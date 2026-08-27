import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    double strength = 0;
    String label = '';

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
      });
      return;
    }

    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;

    if (strength < 0.3) {
      label = 'Weak';
    } else if (strength < 0.6) {
      label = 'Fair';
    } else if (strength < 0.8) {
      label = 'Good';
    } else {
      label = 'Strong';
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.3) return Colors.orange;
    if (_passwordStrength < 0.6) return Colors.amber;
    if (_passwordStrength < 0.8) return Colors.lightGreen;
    return Colors.green;
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
          'Change Password',
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
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'Enter your current password and choose a new one.',
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _buildPasswordField(
              label: 'Current Password',
              controller: _currentPasswordController,
              hintText: 'Enter current password',
              isVisible: _showCurrentPassword,
              onToggle: () =>
                  setState(() => _showCurrentPassword = !_showCurrentPassword),
              colors: colors,
              textTheme: textTheme,
              icon: Icons.lock,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _buildPasswordField(
              label: 'New Password',
              controller: _newPasswordController,
              hintText: 'Choose new password',
              isVisible: _showNewPassword,
              onToggle: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
              colors: colors,
              textTheme: textTheme,
              icon: Icons.vpn_key,
              onChanged: _checkPasswordStrength,
            ),
            if (_passwordStrengthLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stackSm),
              _buildPasswordStrengthIndicator(colors, textTheme),
            ],
            const SizedBox(height: AppSpacing.stackMd),
            _buildPasswordField(
              label: 'Confirm New Password',
              controller: _confirmPasswordController,
              hintText: 'Re-enter new password',
              isVisible: _showConfirmPassword,
              onToggle: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              colors: colors,
              textTheme: textTheme,
              icon: Icons.vpn_key,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _buildUpdateButton(colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggle,
    required ColorScheme colors,
    required TextTheme textTheme,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          onChanged: onChanged,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colors.outline,
            ),
            prefixIcon: Icon(
              icon,
              color: colors.onSurfaceVariant,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: colors.onSurfaceVariant,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            filled: true,
            fillColor: colors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackMd,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(
      ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LinearProgressIndicator(
          value: _passwordStrength,
          backgroundColor: colors.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          _passwordStrengthLabel,
          style: textTheme.labelSmall?.copyWith(
            color: _getStrengthColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton(ColorScheme colors, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          // TODO: Implement password change
          if (_currentPasswordController.text.isEmpty ||
              _newPasswordController.text.isEmpty ||
              _confirmPasswordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill in all fields')),
            );
            return;
          }
          if (_newPasswordController.text != _confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match')),
            );
            return;
          }
          if (_newPasswordController.text.length < 8) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Password must be at least 8 characters')),
            );
            return;
          }
          // TODO: Call API to change password
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
          context.pop();
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.stackMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.update, size: 20),
            const SizedBox(width: AppSpacing.stackSm),
            Text(
              'Update Password',
              style: textTheme.labelLarge?.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
