import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatflow/core/constants/app_colors.dart';
import 'package:chatflow/core/constants/app_dimens.dart';
import 'package:chatflow/core/constants/app_strings.dart';
import 'package:chatflow/core/utils/validators.dart';
import 'package:chatflow/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatflow/features/media/presentation/storage_provider.dart';
import 'package:chatflow/features/profile/presentation/providers/profile_provider.dart';
import 'package:chatflow/shared/widgets/app_avatar.dart';
import 'package:chatflow/shared/widgets/app_button.dart';
import 'package:chatflow/shared/widgets/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  File? _pickedImageFile;
  bool _isLoading = false;
  double? _uploadProgress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final file = await storage.pickImage(source: source);
      if (file != null) {
        setState(() {
          _pickedImageFile = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? newPhotoUrl = currentUser.photoUrl;

      if (_pickedImageFile != null) {
        final storage = ref.read(storageServiceProvider);
        final isDemo = ref.read(isDemoModeProvider);
        newPhotoUrl = await storage.uploadProfileAvatar(
          file: _pickedImageFile!,
          userId: currentUser.uid,
          isDemoMode: isDemo,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      }

      final profileRepo = ref.read(profileRepositoryProvider);
      final isDemo = ref.read(isDemoModeProvider);

      await profileRepo.updateProfile(
        uid: currentUser.uid,
        currentUserId: currentUser.uid,
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: newPhotoUrl,
        isDemoMode: isDemo,
      );

      final updatedProfile = currentUser.copyWith(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: newPhotoUrl,
      );

      ref.read(authNotifierProvider.notifier).updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Camera Overlay
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(isDark ? 80 : 120),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _pickedImageFile != null
                            ? Container(
                                width: AppDimens.avatarXLarge,
                                height: AppDimens.avatarXLarge,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: FileImage(_pickedImageFile!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : AppAvatar(
                                name: user?.displayName ?? 'User',
                                imageUrl: user?.photoUrl,
                                size: AvatarSize.xlarge,
                              ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _showImagePickerModal,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.emeraldGradient,
                                border: Border.all(
                                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap camera icon to change photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                if (_uploadProgress != null && _uploadProgress! < 1.0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      border: Border.all(color: AppColors.error.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Information Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Name Input
                      AppTextField(
                        controller: _nameController,
                        label: AppStrings.displayName,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: Validators.validateDisplayName,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // Bio Input
                      AppTextField(
                        controller: _bioController,
                        label: AppStrings.bio,
                        prefixIcon: Icons.info_outline_rounded,
                        maxLines: 3,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Read-only email notice
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withAlpha(120),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: AppStrings.saveChanges,
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                  variant: ButtonVariant.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
