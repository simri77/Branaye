import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';

class TextSizeScreen extends ConsumerStatefulWidget {
  const TextSizeScreen({super.key});

  @override
  ConsumerState<TextSizeScreen> createState() => _TextSizeScreenState();
}

class _TextSizeScreenState extends ConsumerState<TextSizeScreen> {
  late double _sliderValue;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSize();
  }

  Future<void> _loadSavedSize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('text_size_option') ?? 1;
    final savedSize = TextSizeOption.values[savedIndex];
    
    ref.read(textSizeProvider.notifier).setSize(savedSize);
    
    if (mounted) {
      setState(() {
        _sliderValue = savedSize.index.toDouble();
        _isLoading = false;
      });
    }
  }

  TextSizeOption get _currentOption =>
      TextSizeOption.values[_sliderValue.round()];

  double _getTitleFontSize() {
    switch (_currentOption) {
      case TextSizeOption.small:
        return 24;
      case TextSizeOption.defaultSize:
        return 28;
      case TextSizeOption.extraLarge:
        return 34;
    }
  }

  double _getBodyFontSize() {
    switch (_currentOption) {
      case TextSizeOption.small:
        return 14;
      case TextSizeOption.defaultSize:
        return 16;
      case TextSizeOption.extraLarge:
        return 20;
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
          title: const Text('Text Size'),
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
          'Text Size',
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
              child: _buildPreviewCard(colors, textTheme),
            ),
          ),
          _buildBottomSection(colors, textTheme),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ColorScheme colors, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.rounded),
                ),
                child: Icon(
                  Icons.edit_note,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Text(
                'Preview Note',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Divider(color: colors.surfaceContainerHighest),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'The Architecture of Thought',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: _getTitleFontSize(),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            "Effective note-taking isn't just about recording information; it's about structuring ideas in a way that facilitates later retrieval and synthesis.",
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: _getBodyFontSize(),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'Consider the spaces between words as important as the words themselves. A clear visual hierarchy reduces cognitive load, allowing the mind to focus entirely on the substance of the ideas presented.',
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: _getBodyFontSize(),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _buildBulletPoint('Clarity over complexity', colors, textTheme),
          _buildBulletPoint('Structure informs understanding', colors, textTheme),
          _buildBulletPoint('Whitespace is an active element', colors, textTheme),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(
      String text, ColorScheme colors, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: colors.primary,
              fontSize: _getBodyFontSize(),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.primary,
                fontSize: _getBodyFontSize(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.stackMd,
        bottom: AppSpacing.stackMd + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: colors.surfaceContainerHighest,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tt',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              _buildLabel('Small', _currentOption == TextSizeOption.small, colors, textTheme),
              _buildLabel('Default', _currentOption == TextSizeOption.defaultSize, colors, textTheme),
              _buildLabel('Extra Large', _currentOption == TextSizeOption.extraLarge, colors, textTheme),
              Text(
                'TT',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _sliderValue,
            min: 0,
            max: 2,
            divisions: 2,
            activeColor: colors.primary,
            inactiveColor: colors.surfaceContainerHighest,
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(
      String text, bool isActive, ColorScheme colors, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.labelMedium?.copyWith(
        color: isActive ? colors.primary : colors.onSurfaceVariant,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
