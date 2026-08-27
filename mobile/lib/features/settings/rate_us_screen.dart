import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';

class RateUsScreen extends ConsumerStatefulWidget {
  const RateUsScreen({super.key});

  @override
  ConsumerState<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends ConsumerState<RateUsScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIllustration(colors),
                const SizedBox(height: AppSpacing.stackMd),
                _buildPrompt(colors, textTheme),
                const SizedBox(height: AppSpacing.stackLg),
                _buildStarRating(colors),
                if (_rating > 0) ...[
                  const SizedBox(height: AppSpacing.stackLg),
                  _buildReviewSection(colors, textTheme),
                ],
                const SizedBox(height: AppSpacing.stackLg),
                _buildActions(colors, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(ColorScheme colors) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.favorite,
        size: 64,
        color: colors.onPrimaryContainer,
      ),
    );
  }

  Widget _buildPrompt(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          'Enjoying Branaye?',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Your feedback helps us improve the experience for everyone.',
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStarRating(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = starNumber <= _rating;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _rating = starNumber;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter / 2),
            child: Icon(
              isSelected ? Icons.star : Icons.star_outline,
              size: 40,
              color: isSelected ? colors.primary : colors.surfaceContainerHighest,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReviewSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write a review (optional)',
          style: textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us what you love or how we can improve...',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colors.outline,
            ),
            filled: true,
            fillColor: colors.surface,
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
            contentPadding: const EdgeInsets.all(AppSpacing.stackMd),
          ),
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _rating > 0 ? _submitFeedback : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _rating > 0 ? colors.primary : colors.surfaceContainerHighest,
              foregroundColor: _rating > 0 ? colors.onPrimary : colors.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              elevation: _rating > 0 ? 2 : 0,
            ),
            child: Text(
              'Submit Feedback',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            child: Text(
              'Not Now',
              style: textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _submitFeedback() {
    // Show success message and dismiss
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thank you for your feedback!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.pop();
      }
    });
  }
}
