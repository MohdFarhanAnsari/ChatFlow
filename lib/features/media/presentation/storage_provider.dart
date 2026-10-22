import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/storage_service.dart';

final storageServiceProvider = Provider<BaseStorageService>((ref) {
  return StorageService();
});
