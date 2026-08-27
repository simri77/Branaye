import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  String? _profileImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = ref.read(authProvider);
      
      final name = prefs.getString('profile_name') ?? auth.user?.name ?? '';
      final email = prefs.getString('profile_email') ?? auth.user?.email ?? '';
      final phone = prefs.getString('profile_phone') ?? '';
      final bio = prefs.getString('profile_bio') ?? '';
      final imagePath = prefs.getString('profile_image_path');

      if (mounted) {
        setState(() {
          _nameController.text = name;
          _emailController.text = email;
          _phoneController.text = phone;
          _bioController.text = bio;
          _profileImagePath = imagePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email);
    await prefs.setString('profile_phone', _phoneController.text.trim());
    await prefs.setString('profile_bio', _bioController.text.trim());
    
    if (_profileImagePath != null) {
      await prefs.setString('profile_image_path', _profileImagePath!);
    }

    // Update auth provider so settings screen reflects changes
    ref.read(authProvider.notifier).updateProfile(name: name, email: email);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Personal Information'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Personal Information',
          style: textTheme.headlineSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.stackLg),
            _buildProfileSection(colors, textTheme),
            const SizedBox(height: AppSpacing.stackLg),
            _buildFormSection(colors, textTheme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(colors, textTheme),
    );
  }

  Widget _buildProfileSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceContainerHighest,
                  border: Border.all(
                    color: colors.surface,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _profileImagePath != null
                      ? Image.file(
                          File(_profileImagePath!),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 64,
                          color: colors.onSurfaceVariant,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                    border: Border.all(
                      color: colors.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 20,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'Tap to change photo',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      children: [
        _buildInputField(
          label: 'FULL NAME',
          controller: _nameController,
          hintText: 'Enter your full name',
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _buildInputField(
          label: 'EMAIL ADDRESS',
          controller: _emailController,
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _buildInputField(
          label: 'PHONE NUMBER',
          controller: _phoneController,
          hintText: '+1 (555) 000-0000',
          keyboardType: TextInputType.phone,
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _buildBioField(colors, textTheme),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ColorScheme colors,
    required TextTheme textTheme,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: textTheme.bodyLarge?.copyWith(
                color: colors.outline,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BIO',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          TextField(
            controller: _bioController,
            maxLines: 4,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Write a short bio about yourself...',
              hintStyle: textTheme.bodyLarge?.copyWith(
                color: colors.outline,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.stackMd,
        bottom: AppSpacing.stackMd + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: colors.surfaceContainerHighest,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.stackMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () async {
                await _saveProfile();
                if (!mounted) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved')),
                  );
                  context.pop();
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.stackMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20),
                  const SizedBox(width: AppSpacing.stackSm),
                  Text(
                    'Save Changes',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
