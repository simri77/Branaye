import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isYearly = true;

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
          'Subscription',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          children: [
            _buildHeroSection(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildCurrentPlanCard(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildBillingToggle(colors, textTheme),
            const SizedBox(height: AppSpacing.stackMd),
            _buildPricingCard(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildRestorePurchases(colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.workspace_premium,
            size: 40,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'Elevate your notes',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Unlock full potential with cloud sync across all devices and advanced security features.',
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCurrentPlanCard(ColorScheme colors, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PLAN',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Text(
                'Free Tier',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.stackSm + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Active',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Basic local notes.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            label: 'Monthly',
            isSelected: !_isYearly,
            colors: colors,
            textTheme: textTheme,
            onTap: () => setState(() => _isYearly = false),
          ),
          _buildToggleOption(
            label: 'Yearly',
            isSelected: _isYearly,
            colors: colors,
            textTheme: textTheme,
            onTap: () => setState(() => _isYearly = true),
            badge: 'SAVE 20%',
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required ColorScheme colors,
    required TextTheme textTheme,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackLg,
          vertical: AppSpacing.stackSm + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: isSelected ? colors.onPrimary : colors.onSurface,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: AppSpacing.stackSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  badge,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(ColorScheme colors, TextTheme textTheme) {
    final monthlyPrice = 4.99;
    final yearlyPrice = 59.88;
    final displayPrice = _isYearly ? monthlyPrice : 5.99;
    final billingText =
        _isYearly ? 'Billed annually at \$$yearlyPrice' : 'Billed monthly';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  children: [
                    Text(
                      'Pro Plan',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$',
                          style: textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          displayPrice.toStringAsFixed(2),
                          style: textTheme.displaySmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/mo',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      billingText,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          // TODO: Implement upgrade
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.stackMd,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        child: Text(
                          'Upgrade to Pro',
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Cancel anytime. No hidden fees.',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.stackMd,
                    vertical: AppSpacing.stackSm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppRadius.xl - 2),
                      bottomLeft: Radius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'POPULAR',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.surfaceContainerHigh,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everything in Free, plus:',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _buildFeature(
                  icon: Icons.check_circle,
                  title: 'Unlimited Notes',
                  subtitle: 'Create as many notes and folders as you need.',
                  colors: colors,
                  textTheme: textTheme,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _buildFeature(
                  icon: Icons.cloud_sync,
                  title: 'Cloud Sync',
                  subtitle: 'Access your notes across all devices seamlessly.',
                  colors: colors,
                  textTheme: textTheme,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _buildFeature(
                  icon: Icons.lock,
                  title: 'Advanced Security',
                  subtitle: 'End-to-end encryption for your most private thoughts.',
                  colors: colors,
                  textTheme: textTheme,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _buildFeature(
                  icon: Icons.support_agent,
                  title: 'Priority Support',
                  subtitle: 'Get help faster when you need it.',
                  colors: colors,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: colors.primary,
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestorePurchases(ColorScheme colors, TextTheme textTheme) {
    return TextButton(
      onPressed: () {
        // TODO: Implement restore purchases
      },
      child: Text(
        'Restore Purchases',
        style: textTheme.labelLarge?.copyWith(
          color: colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary,
        ),
      ),
    );
  }
}
