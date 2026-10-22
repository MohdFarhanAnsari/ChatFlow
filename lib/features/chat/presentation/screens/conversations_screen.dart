import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chatflow/core/constants/app_colors.dart';
import 'package:chatflow/core/constants/app_dimens.dart';
import 'package:chatflow/core/constants/app_strings.dart';
import 'package:chatflow/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatflow/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatflow/features/chat/presentation/widgets/conversation_tile.dart';
import 'package:chatflow/features/chat/presentation/widgets/demo_banner.dart';
import 'package:chatflow/shared/widgets/empty_view.dart';
import 'package:chatflow/shared/widgets/error_view.dart';
import 'package:chatflow/shared/widgets/loading_indicator.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyUnread = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryContainer : AppColors.primaryDark)
              : (isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard),
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.primaryLight : AppColors.primaryDark),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final isDemo = ref.watch(isDemoModeProvider);
    final conversationsAsync = ref.watch(conversationsStreamProvider);
    final totalUnread = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.emeraldGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(70),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21, letterSpacing: -0.4),
            ),
            if (totalUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalUnread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            tooltip: 'Discover Contacts',
            onPressed: () => context.push('/search-users'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isDemo) const DemoBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search chats or messages...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceInput : AppColors.lightSurfaceInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All Chats',
                    isSelected: !_showOnlyUnread,
                    onTap: () => setState(() => _showOnlyUnread = false),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Unread',
                    isSelected: _showOnlyUnread,
                    onTap: () => setState(() => _showOnlyUnread = true),
                    isDark: isDark,
                    count: totalUnread,
                  ),
                ],
              ),
            ),
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return EmptyView(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No Conversations Yet',
                      message:
                          'Your inbox is quiet. Tap the compose button below or discover colleagues to begin messaging in real time.',
                      actionText: 'Find Contacts',
                      onAction: () => context.push('/search-users'),
                    );
                  }

                  final query = _searchController.text.trim().toLowerCase();
                  var filtered = query.isEmpty
                      ? conversations
                      : conversations.where((c) {
                          final partner = c.getOtherParticipant(currentUser?.uid ?? '');
                          final nameMatch = partner?.displayName.toLowerCase().contains(query) ?? false;
                          final msgMatch = c.lastMessage.toLowerCase().contains(query);
                          return nameMatch || msgMatch;
                        }).toList();

                  if (_showOnlyUnread) {
                    filtered = filtered
                        .where((c) => c.getUnreadCount(currentUser?.uid ?? '') > 0)
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    if (_showOnlyUnread) {
                      return EmptyView(
                        icon: Icons.mark_chat_read_rounded,
                        title: 'All Caught Up',
                        message: 'You have read all of your conversations.',
                        actionText: 'Show All Chats',
                        onAction: () => setState(() => _showOnlyUnread = false),
                      );
                    }

                    return EmptyView(
                      icon: Icons.search_off_rounded,
                      title: 'No Matching Conversations',
                      message: 'No conversations match "${_searchController.text}".',
                      actionText: 'Clear Search',
                      onAction: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => Divider(
                      indent: 76,
                      color: isDark ? AppColors.darkBorder.withAlpha(80) : AppColors.lightBorder,
                    ),
                    itemBuilder: (context, index) {
                      final conversation = filtered[index];
                      return ConversationTile(
                        conversation: conversation,
                        currentUserId: currentUser?.uid ?? '',
                        onTap: () => context.push('/chat/${conversation.id}'),
                      );
                    },
                  );
                },
                loading: () => const AppLoadingIndicator(message: 'Syncing conversations...'),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(conversationsStreamProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/search-users'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(Icons.edit_square, size: 22),
      ),
    );
  }
}
