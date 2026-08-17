import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Branaye',
          style: textTheme.titleLarge?.copyWith(color: colors.primary),
        ),
        backgroundColor: colors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 48, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Categories Screen',
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
