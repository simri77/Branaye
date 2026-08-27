import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';

class ReportBugScreen extends ConsumerStatefulWidget {
  const ReportBugScreen({super.key});

  @override
  ConsumerState<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends ConsumerState<ReportBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          'Report a Bug',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We're sorry you're experiencing issues. Please provide as much detail as possible so we can fix it quickly.",
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              _buildSubjectField(colors, textTheme),
              const SizedBox(height: AppSpacing.stackMd),
              _buildDescriptionField(colors, textTheme),
              const SizedBox(height: AppSpacing.stackMd),
              _buildAttachScreenshot(colors, textTheme),
              const SizedBox(height: AppSpacing.stackLg),
              _buildSubmitButton(colors, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectField(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject',
          style: textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        TextFormField(
          controller: _subjectController,
          decoration: InputDecoration(
            hintText: 'Brief summary of the issue',
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colors.outline,
            ),
            filled: true,
            fillColor: colors.surfaceContainerLowest,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackMd,
            ),
          ),
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
              ),
            ),
            Text(
              '*Required',
              style: textTheme.labelSmall?.copyWith(
                color: colors.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Steps to reproduce, what you expected to happen, and what actually happened...',
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colors.outline,
            ),
            filled: true,
            fillColor: colors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: colors.error, width: 2),
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

  Widget _buildAttachScreenshot(ColorScheme colors, TextTheme textTheme) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement image picker
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot attachment coming soon!'),
          ),
        );
      },
      icon: Icon(
        Icons.add_photo_alternate_outlined,
        color: colors.primary,
      ),
      label: Text(
        'Attach Screenshot (Optional)',
        style: textTheme.labelLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 72),
        side: BorderSide(
          color: colors.outlineVariant,
          width: 2,
          style: BorderStyle.solid,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        padding: const EdgeInsets.all(AppSpacing.stackMd),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colors, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _submitReport,
        icon: Icon(
          Icons.send,
          size: 20,
        ),
        label: Text(
          'Send Report',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bug report sent successfully!',
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
}
