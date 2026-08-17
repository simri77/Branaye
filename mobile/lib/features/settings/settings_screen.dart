import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NoteFlow',
          style: textTheme.titleLarge?.copyWith(color: colors.primary),
        ),
        backgroundColor: colors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_outlined, size: 48, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Settings Screen',
              style: textTheme.headlineMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
            Text(
              'your notes will apear here',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
