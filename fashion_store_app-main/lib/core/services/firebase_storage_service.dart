import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around [FirebaseStorage] for uploads and download URLs.
class FirebaseStorageService {
  FirebaseStorageService([FirebaseStorage? storage])
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference ref(String path) => _storage.ref(path);

  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }
}
