import 'dart:async';
import '../domain/user_profile.dart';
import '../../demo/data/demo_local_store.dart';
import 'profile_repository.dart';

/// Pure local Demo Mode implementation of [BaseProfileRepository].
/// Operates completely offline, persisting profile changes and contacts to [DemoLocalStore].
class DemoProfileRepository implements BaseProfileRepository {
  final DemoLocalStore _store;
  final StreamController<UserProfile?> _profileStreamController =
      StreamController<UserProfile?>.broadcast();

  DemoProfileRepository({DemoLocalStore? store})
      : _store = store ?? DemoLocalStore();

  @override
  Stream<UserProfile?> streamUserProfile(String uid, {bool isDemoMode = true}) {
    _store.getUserProfile().then((user) {
      if (user.uid == uid) {
        _profileStreamController.add(user);
      } else {
        _store.getContacts().then((contacts) {
          final match = contacts.where((c) => c.uid == uid).firstOrNull;
          _profileStreamController.add(match);
        });
      }
    });
    return _profileStreamController.stream;
  }

  @override
  Future<UserProfile?> getUserProfile(String uid, {bool isDemoMode = true}) async {
    final current = await _store.getUserProfile();
    if (current.uid == uid) return current;

    final contacts = await _store.getContacts();
    return contacts.where((c) => c.uid == uid).firstOrNull;
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String currentUserId,
    String? displayName,
    String? bio,
    String? photoUrl,
    bool isDemoMode = true,
  }) async {
    if (uid != currentUserId) {
      throw Exception('Permission denied: You can only edit your own profile.');
    }

    final current = await _store.getUserProfile();
    final updated = current.copyWith(
      displayName: displayName?.trim() ?? current.displayName,
      bio: bio?.trim() ?? current.bio,
      photoUrl: photoUrl ?? current.photoUrl,
    );

    await _store.saveUserProfile(updated);
    _profileStreamController.add(updated);

    // Also update current user in existing conversations
    final convs = await _store.getConversations();
    bool convsChanged = false;
    for (int i = 0; i < convs.length; i++) {
      if (convs[i].participantProfiles.containsKey(uid)) {
        final newProfiles = Map<String, UserProfile>.from(convs[i].participantProfiles);
        newProfiles[uid] = updated;
        convs[i] = convs[i].copyWith(participantProfiles: newProfiles);
        convsChanged = true;
      }
    }
    if (convsChanged) {
      await _store.saveConversations(convs);
    }
  }

  @override
  Future<void> setPresence({
    required String uid,
    required bool isOnline,
    bool isDemoMode = true,
  }) async {
    final current = await _store.getUserProfile();
    if (current.uid == uid) {
      final updated = current.copyWith(isOnline: isOnline, lastSeen: DateTime.now());
      await _store.saveUserProfile(updated);
      _profileStreamController.add(updated);
    }
  }

  @override
  Future<List<UserProfile>> searchUsers(
    String query, {
    required String currentUserId,
    bool isDemoMode = true,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    final contacts = await _store.getContacts();

    if (cleanQuery.isEmpty) {
      return contacts.where((u) => u.uid != currentUserId).toList();
    }

    return contacts.where((u) {
      if (u.uid == currentUserId) return false;
      final nameMatch = u.displayName.toLowerCase().contains(cleanQuery);
      final emailMatch = u.email.toLowerCase().contains(cleanQuery);
      return nameMatch || emailMatch;
    }).toList();
  }

  void dispose() {
    _profileStreamController.close();
  }
}
