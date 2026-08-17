import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            Icon(Icons.note_outlined, size: 48, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Home',
              style: textTheme.headlineMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
            Text(
              'Your notes will appear here',
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
