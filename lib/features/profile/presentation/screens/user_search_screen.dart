import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chatflow/core/constants/app_colors.dart';
import 'package:chatflow/core/constants/app_strings.dart';
import 'package:chatflow/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatflow/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatflow/features/profile/domain/user_profile.dart';
import 'package:chatflow/features/profile/presentation/providers/profile_provider.dart';
import 'package:chatflow/shared/widgets/app_avatar.dart';
import 'package:chatflow/shared/widgets/empty_view.dart';
import 'package:chatflow/shared/widgets/error_view.dart';
import 'package:chatflow/shared/widgets/loading_indicator.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();
  bool _isStartingChat = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startConversation(UserProfile targetUser) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isStartingChat = true);

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final isDemo = ref.read(isDemoModeProvider);

      final conversation = await chatRepo.getOrCreateConversation(
        currentUserId: currentUser.uid,
        currentUser: currentUser,
        otherUser: targetUser,
        isDemoMode: isDemo,
      );

      if (mounted) {
        context.pushReplacement('/chat/${conversation.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate conversation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchState = ref.watch(userSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Conversation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 15,
                  ),
                  onChanged: (val) {
                    ref.read(userSearchProvider.notifier).search(val);
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.searchUsers,
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            onPressed: () {
                              _searchController.clear();
                              ref.read(userSearchProvider.notifier).clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

            // Search Results / Suggested list
            Expanded(
              child: _isStartingChat
                  ? const AppLoadingIndicator(message: 'Starting conversation...')
                  : searchState.when(
                      data: (users) {
                        if (users.isEmpty) {
                          final query = _searchController.text.trim();
                          return EmptyView(
                            icon: query.isEmpty
                                ? Icons.people_outline_rounded
                                : Icons.search_off_rounded,
                            title: query.isEmpty ? 'No Contacts Found' : 'No matching users',
                            message: query.isEmpty
                                ? 'No contacts available in your directory.'
                                : 'No users matching "$query". Check spelling or clear search.',
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                              child: Row(
                                children: [
                                  Text(
                                    _searchController.text.trim().isEmpty
                                        ? 'DIRECTORY CONTACTS'
                                        : 'SEARCH RESULTS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${users.length}',
                                      style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: users.length,
                                separatorBuilder: (context, index) => Divider(
                                  indent: 72,
                                  endIndent: 16,
                                  height: 1,
                                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withAlpha(120),
                                ),
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _startConversation(user),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                        child: Row(
                                          children: [
                                            AppAvatar(
                                              name: user.displayName,
                                              imageUrl: user.photoUrl,
                                              size: AvatarSize.medium,
                                              isOnline: user.isOnline,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.displayName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                      color: isDark
                                                          ? AppColors.darkTextPrimary
                                                          : AppColors.lightTextPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    user.bio ?? user.email,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? AppColors.darkTextSecondary
                                                          : AppColors.lightTextSecondary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.chat_bubble_outline_rounded,
                                                color: AppColors.primaryLight,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const AppLoadingIndicator(message: 'Searching directory...'),
                      error: (err, _) => ErrorView(
                        message: err.toString(),
                        onRetry: () => ref
                            .read(userSearchProvider.notifier)
                            .search(_searchController.text),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
