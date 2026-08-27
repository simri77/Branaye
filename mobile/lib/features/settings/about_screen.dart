import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'About Branaye',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: Column(
                children: [
                  _buildLogoSection(colors, textTheme),
                  const SizedBox(height: AppSpacing.stackLg),
                  _buildLinksSection(context, colors, textTheme),
                ],
              ),
            ),
          ),
          _buildFooter(context, colors, textTheme),
        ],
      ),
    );
  }

  Widget _buildLogoSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Image.asset(
              'lib/img/Branaye_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'B R A N A Y E',
          style: textTheme.titleSmall?.copyWith(
            color: colors.primary,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Version 1.0.0',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection(
      BuildContext context, ColorScheme colors, TextTheme textTheme) {
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
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLinkTile(
            context: context,
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () => context.push('/settings/about/privacy-policy'),
            colors: colors,
            textTheme: textTheme,
            showDivider: true,
          ),
          _buildLinkTile(
            context: context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => context.push('/settings/about/terms-of-service'),
            colors: colors,
            textTheme: textTheme,
            showDivider: true,
          ),
          _buildLinkTile(
            context: context,
            icon: Icons.star_outline,
            title: 'Rate Us',
            onTap: () => context.push('/settings/about/rate-us'),
            colors: colors,
            textTheme: textTheme,
            showDivider: true,
          ),
          _buildLinkTile(
            context: context,
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            onTap: () => context.push('/settings/about/report-bug'),
            colors: colors,
            textTheme: textTheme,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
          leading: Icon(
            icon,
            color: colors.outline,
          ),
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: colors.outlineVariant,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colors, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.stackMd,
        bottom: AppSpacing.stackMd + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Made with ',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Icon(
                Icons.favorite,
                size: 16,
                color: colors.error,
              ),
              Text(
                ' in San Francisco',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            '© 2024 Branaye Inc. All rights reserved.',
            style: textTheme.labelSmall?.copyWith(
              color: colors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
