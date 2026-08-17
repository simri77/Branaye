import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const BranayeApp());
}

class BranayeApp extends StatelessWidget {
  const BranayeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Branaye',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
