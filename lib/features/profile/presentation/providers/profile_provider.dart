import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatflow/features/profile/domain/user_profile.dart';
import 'package:chatflow/features/profile/data/profile_repository.dart';
import 'package:chatflow/features/auth/presentation/providers/auth_provider.dart';

final profileRepositoryProvider = Provider<BaseProfileRepository>((ref) {
  return ProfileRepository();
});

/// Streams live profile for any user ID
final userProfileStreamProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  final repo = ref.watch(profileRepositoryProvider);
  final isDemo = ref.watch(isDemoModeProvider);
  return repo.streamUserProfile(uid, isDemoMode: isDemo);
});

/// Search users notifier
class UserSearchNotifier extends StateNotifier<AsyncValue<List<UserProfile>>> {
  final BaseProfileRepository _repository;
  final String _currentUserId;
  final bool _isDemoMode;

  UserSearchNotifier(this._repository, this._currentUserId, this._isDemoMode)
      : super(const AsyncValue.loading()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      final results = await _repository.searchUsers(
        '',
        currentUserId: _currentUserId,
        isDemoMode: _isDemoMode,
      );
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      return loadContacts();
    }

    state = const AsyncValue.loading();
    try {
      final results = await _repository.searchUsers(
        clean,
        currentUserId: _currentUserId,
        isDemoMode: _isDemoMode,
      );
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    loadContacts();
  }
}

final userSearchProvider =
    StateNotifierProvider.autoDispose<UserSearchNotifier, AsyncValue<List<UserProfile>>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final isDemo = ref.watch(isDemoModeProvider);
  return UserSearchNotifier(repo, user?.uid ?? '', isDemo);
});
