import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'demo_storage_service.dart';
import 'firebase_storage_service.dart';

abstract class BaseStorageService {
  Future<File?> pickImage({required ImageSource source});
  Future<String> uploadChatImage({
    required File file,
    required String conversationId,
    void Function(double progress)? onProgress,
    bool isDemoMode = false,
  });
  Future<String> uploadProfileAvatar({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
    bool isDemoMode = false,
  });
}

/// Unified coordinator storage service that delegates cleanly between
/// [FirebaseStorageService] (live Cloud Storage) and [DemoStorageService] (local demo).
class StorageService implements BaseStorageService {
  final FirebaseStorageService _firebaseStorage;
  final DemoStorageService _demoStorage;

  StorageService({
    FirebaseStorageService? firebaseStorage,
    DemoStorageService? demoStorage,
  })  : _firebaseStorage = firebaseStorage ?? FirebaseStorageService(),
        _demoStorage = demoStorage ?? DemoStorageService();

  @override
  Future<File?> pickImage({required ImageSource source}) {
    // Both implementations use image picker with standard validation
    return _demoStorage.pickImage(source: source);
  }

  @override
  Future<String> uploadChatImage({
    required File file,
    required String conversationId,
    void Function(double progress)? onProgress,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoStorage.uploadChatImage(
        file: file,
        conversationId: conversationId,
        onProgress: onProgress,
        isDemoMode: true,
      );
    }
    return _firebaseStorage.uploadChatImage(
      file: file,
      conversationId: conversationId,
      onProgress: onProgress,
      isDemoMode: false,
    );
  }

  @override
  Future<String> uploadProfileAvatar({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
    bool isDemoMode = false,
  }) {
    if (isDemoMode) {
      return _demoStorage.uploadProfileAvatar(
        file: file,
        userId: userId,
        onProgress: onProgress,
        isDemoMode: true,
      );
    }
    return _firebaseStorage.uploadProfileAvatar(
      file: file,
      userId: userId,
      onProgress: onProgress,
      isDemoMode: false,
    );
  }

  DemoStorageService get demoService => _demoStorage;
  FirebaseStorageService get firebaseService => _firebaseStorage;
}
