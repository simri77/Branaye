import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_typography.dart';

class LanguageItem {
  const LanguageItem({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
}

final languagesList = [
  const LanguageItem(
    code: 'en_US',
    name: 'English (US)',
    nativeName: 'English (US)',
    flag: '🇺🇸',
  ),
  const LanguageItem(
    code: 'en_UK',
    name: 'English (UK)',
    nativeName: 'English (UK)',
    flag: '🇬🇧',
  ),
  const LanguageItem(
    code: 'es',
    name: 'Español',
    nativeName: 'Spanish',
    flag: '🇪🇸',
  ),
  const LanguageItem(
    code: 'fr',
    name: 'Français',
    nativeName: 'French',
    flag: '🇫🇷',
  ),
  const LanguageItem(
    code: 'de',
    name: 'Deutsch',
    nativeName: 'German',
    flag: '🇩🇪',
  ),
  const LanguageItem(
    code: 'ja',
    name: '日本語',
    nativeName: 'Japanese',
    flag: '🇯🇵',
  ),
  const LanguageItem(
    code: 'am',
    name: 'አማርኛ',
    nativeName: 'Amharic',
    flag: '🇪🇹',
  ),
];

final selectedLanguageProvider =
    NotifierProvider<SelectedLanguageNotifier, String>(
  SelectedLanguageNotifier.new,
);

class SelectedLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'en_US';

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language_code') ?? 'en_US';
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }
}

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LanguageItem> get _filteredLanguages {
    if (_searchQuery.isEmpty) return languagesList;
    return languagesList.where((lang) {
      final query = _searchQuery.toLowerCase();
      return lang.name.toLowerCase().contains(query) ||
          lang.nativeName.toLowerCase().contains(query) ||
          lang.code.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedCode = ref.watch(selectedLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Language',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(colors, textTheme),
          Expanded(
            child: _filteredLanguages.isEmpty
                ? _buildNoResults(colors, textTheme)
                : _buildLanguageList(selectedCode, colors, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colors, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search languages...',
          hintStyle: textTheme.bodyLarge?.copyWith(
            color: colors.outline,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colors.onSurfaceVariant,
          ),
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
          filled: true,
          fillColor: colors.surfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd,
            vertical: AppSpacing.stackMd,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults(ColorScheme colors, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.language,
            size: 48,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'No languages found',
            style: textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(
      String selectedCode, ColorScheme colors, TextTheme textTheme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      itemCount: _filteredLanguages.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: colors.surfaceContainerHighest,
      ),
      itemBuilder: (context, index) {
        final lang = _filteredLanguages[index];
        final isSelected = lang.code == selectedCode;

        return _LanguageTile(
          language: lang,
          isSelected: isSelected,
          onTap: () async {
            await ref
                .read(selectedLanguageProvider.notifier)
                .setLanguage(lang.code);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language set to ${lang.name}')),
              );
            }
          },
          colors: colors,
          textTheme: textTheme,
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  final LanguageItem language;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppSpacing.stackSm,
      ),
      leading: Text(
        language.flag,
        style: const TextStyle(fontSize: 32),
      ),
      title: Text(
        language.name,
        style: textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        language.nativeName,
        style: textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.circle,
                    size: 12,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selected',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ],
            )
          : Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.outlineVariant,
                  width: 2,
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}
