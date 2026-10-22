import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';

/// Pure local Demo Mode implementation of [BaseStorageService].
/// Operates offline, retaining local file paths for picked images so that
/// photos captured with camera or selected from gallery immediately render
/// in chat bubbles and avatar previews.
class DemoStorageService implements BaseStorageService {
  final ImagePicker _picker;

  DemoStorageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB limit
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  @override
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      final bytes = await file.length();
      if (bytes > maxFileSizeBytes) {
        throw Exception('File size exceeds the 10 MB limit. Please select a smaller image.');
      }

      final ext = pickedFile.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        throw Exception('Unsupported file format ($ext). Allowed: jpg, png, webp.');
      }

      return file;
    } catch (e) {
      debugPrint('Error picking demo image: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadChatImage({
    required File file,
    required String conversationId,
    void Function(double progress)? onProgress,
    bool isDemoMode = true,
  }) async {
    // Simulate upload progression for smooth UI feedback
    onProgress?.call(0.25);
    await Future.delayed(const Duration(milliseconds: 200));
    onProgress?.call(0.75);
    await Future.delayed(const Duration(milliseconds: 200));
    onProgress?.call(1.0);

    // Return the actual local file path so the user's selected image renders directly
    return file.path;
  }

  @override
  Future<String> uploadProfileAvatar({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
    bool isDemoMode = true,
  }) async {
    onProgress?.call(0.5);
    await Future.delayed(const Duration(milliseconds: 200));
    onProgress?.call(1.0);

    return file.path;
  }
}
