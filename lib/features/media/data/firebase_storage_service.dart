import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/firebase_initializer.dart';
import 'storage_service.dart';

/// Pure production Firebase Storage service.
class FirebaseStorageService implements BaseStorageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final Uuid _uuid;

  FirebaseStorageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
    Uuid? uuid,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB limit
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  @override
  Future<File?> pickImage({required ImageSource source}) async {
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
  }

  @override
  Future<String> uploadChatImage({
    required File file,
    required String conversationId,
    void Function(double progress)? onProgress,
    bool isDemoMode = false,
  }) async {
    if (!FirebaseInitializer.isLiveConfigured) {
      throw Exception('Firebase Storage is not configured with live credentials.');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final filename = '${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('chat_images').child(conversationId).child(filename);

    final metadata = SettableMetadata(
      contentType: 'image/$ext',
      customMetadata: {'conversationId': conversationId},
    );

    final uploadTask = ref.putFile(file, metadata);
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Future<String> uploadProfileAvatar({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
    bool isDemoMode = false,
  }) async {
    if (!FirebaseInitializer.isLiveConfigured) {
      throw Exception('Firebase Storage is not configured with live credentials.');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final filename = 'avatar_${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('profile_avatars').child(userId).child(filename);

    final metadata = SettableMetadata(
      contentType: 'image/$ext',
      customMetadata: {'userId': userId},
    );

    final uploadTask = ref.putFile(file, metadata);
    uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
