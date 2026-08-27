import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: October 24, 2023',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _buildSection(
              title: '1. Introduction',
              content: 'Welcome to Branaye. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our application and tell you about your privacy rights and how the law protects you.',
              colors: colors,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _buildSectionWithList(
              title: '2. Data Collection',
              content: 'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together follows:',
              items: [
                'Identity Data: includes first name, last name, username or similar identifier.',
                'Contact Data: includes email address and telephone numbers.',
                'Technical Data: includes internet protocol (IP) address, your login data, browser type and version, time zone setting and location.',
                'Content Data: includes the notes, lists, and other information you create and store within the app.',
              ],
              colors: colors,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _buildSectionWithCards(
              title: '3. How We Use Your Data',
              content: 'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:',
              cards: [
                {
                  'icon': Icons.cloud_sync,
                  'title': 'Sync & Backup',
                  'description': 'To securely sync your notes across devices and provide automated backups to prevent data loss.',
                },
                {
                  'icon': Icons.support_agent,
                  'title': 'Customer Support',
                  'description': 'To respond to your inquiries, troubleshoot issues, and provide general assistance regarding the application.',
                },
              ],
              colors: colors,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _buildSection(
              title: '4. Contact Us',
              content: 'If you have any questions about this privacy policy or our privacy practices, please contact us at privacy@branaye.app.',
              colors: colors,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          content,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionWithList({
    required String title,
    required String content,
    required List<String> items,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          content,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: AppSpacing.stackMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSectionWithCards({
    required String title,
    required String content,
    required List<Map<String, dynamic>> cards,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          content,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        ...cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      card['icon'] as IconData,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Text(
                      card['title'] as String,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  card['description'] as String,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
