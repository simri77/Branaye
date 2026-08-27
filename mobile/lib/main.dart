import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';

void main() {
  runApp(const ProviderScope(child: BranayeApp()));
}

class BranayeApp extends ConsumerStatefulWidget {
  const BranayeApp({super.key});

  @override
  ConsumerState<BranayeApp> createState() => _BranayeAppState();
}

class _BranayeAppState extends ConsumerState<BranayeApp> {
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await ref.read(textSizeProvider.notifier).loadSavedSize();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Branaye',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
