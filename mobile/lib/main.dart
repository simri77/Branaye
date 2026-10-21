import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'features/settings/language_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Build the container before the first frame so the router guard can see an
  // already-restored session — no "flash of login screen" on app start.
  final container = ProviderContainer();

  await container.read(authProvider.notifier).restoreSession();
  await container.read(textSizeProvider.notifier).loadSavedSize();
  await container.read(selectedLanguageProvider.notifier).loadSavedLanguage();

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
    final textSize = ref.watch(textSizeProvider);
    final langCode = ref.watch(selectedLanguageProvider);
    final scale = switch (textSize) {
      TextSizeOption.small => 0.85,
      TextSizeOption.defaultSize => 1.0,
      TextSizeOption.extraLarge => 1.3,
    };
    final parts = langCode.split('_');
    final locale = parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);

    return MaterialApp.router(
      title: 'Branaye',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('ja'),
        Locale('am'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    );
  }
}
