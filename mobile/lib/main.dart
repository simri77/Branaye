import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build the container before the first frame so the router guard can see an
  // already-restored session — no "flash of login screen" on app start.
  final container = ProviderContainer();

  await container.read(authProvider.notifier).restoreSession();
  await container.read(textSizeProvider.notifier).loadSavedSize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BranayeApp(),
    ),
  );
}

class BranayeApp extends ConsumerWidget {
  const BranayeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
