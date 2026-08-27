import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/personal_information_screen.dart';
import '../../features/settings/subscription_screen.dart';
import '../../features/settings/change_password_screen.dart';
import '../../features/settings/text_size_screen.dart';
import '../../features/settings/sync_backup_screen.dart';
import '../../features/settings/language_screen.dart';
import '../../features/settings/security_screen.dart';
import '../../features/settings/change_pin_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/rate_us_screen.dart';
import '../../features/settings/report_bug_screen.dart';
import '../../features/settings/terms_of_service_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/editor/editor_screen.dart';
import '../../features/notes/filtered_notes_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../data/providers.dart';

final authRefreshNotifier = ValueNotifier<int>(0);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRefreshNotifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(child: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'personal-info',
                    builder: (context, state) =>
                        const PersonalInformationScreen(),
                  ),
                  GoRoute(
                    path: 'subscription',
                    builder: (context, state) =>
                        const SubscriptionScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) =>
                        const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) =>
                        const SecurityScreen(),
                    routes: [
                      GoRoute(
                        path: 'change-pin',
                        builder: (context, state) =>
                            const ChangePinFlow(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'text-size',
                    builder: (context, state) =>
                        const TextSizeScreen(),
                  ),
                  GoRoute(
                    path: 'sync-backup',
                    builder: (context, state) =>
                        const SyncBackupScreen(),
                  ),
                  GoRoute(
                    path: 'language',
                    builder: (context, state) =>
                        const LanguageScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) =>
                        const AboutScreen(),
                    routes: [
                      GoRoute(
                        path: 'privacy-policy',
                        builder: (context, state) =>
                            const PrivacyPolicyScreen(),
                      ),
                      GoRoute(
                        path: 'terms-of-service',
                        builder: (context, state) =>
                            const TermsOfServiceScreen(),
                      ),
                      GoRoute(
                        path: 'rate-us',
                        builder: (context, state) =>
                            const RateUsScreen(),
                      ),
                      GoRoute(
                        path: 'report-bug',
                        builder: (context, state) =>
                            const ReportBugScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => const EditorScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) =>
            const FilteredNotesScreen(mode: FilterMode.favorites),
      ),
      GoRoute(
        path: '/archived',
        builder: (context, state) =>
            const FilteredNotesScreen(mode: FilterMode.archived),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/categories')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 1:
        context.go('/search');
      case 2:
        context.go('/categories');
      case 3:
        context.go('/settings');
      default:
        context.go('/');
    }
  }
}
