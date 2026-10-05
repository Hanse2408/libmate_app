import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// An image the user picked, ready to upload. Only the bytes are uploaded to
/// Firebase Storage; Firestore stores just the resulting download URL.
class ImageUpload {
  const ImageUpload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;

  /// e.g. "image/jpeg"
  final String contentType;

  static const int maxBytes = 5 * 1024 * 1024; // 5 MB
  static const Map<String, String> supportedTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// "jpg", "png" or "webp", used for the Storage file name.
  String get extension => switch (contentType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };

  /// Builds an upload from picked bytes, or returns the reason it is refused
  /// (wrong type or too large).
  static (ImageUpload?, String?) validate({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
    final type = supportedTypes.values.contains(mimeType)
        ? mimeType!
        : supportedTypes[ext];
    if (type == null) {
      return (null, 'Please choose a JPG, PNG or WebP image.');
    }
    if (bytes.isEmpty) return (null, 'The selected file is empty.');
    if (bytes.length > maxBytes) {
      return (null, 'The image is larger than 5 MB. Please choose a smaller one.');
    }
    return (ImageUpload(bytes: bytes, fileName: fileName, contentType: type), null);
  }
}

/// Opens the device gallery / file picker. Replaceable in widget tests,
/// where the real platform picker is not available.
class ImagePickerService {
  const ImagePickerService();

  static ImagePickerService instance = const ImagePickerService();

  /// The picked image, `(null, null)` if the user cancelled, or
  /// `(null, reason)` if the file is not a supported image.
  Future<(ImageUpload?, String?)> pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600, // keeps uploads small without visible quality loss
      imageQuality: 85,
    );
    if (file == null) return (null, null);
    return ImageUpload.validate(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType,
    );
  }
}

/// Thrown when an upload fails; [message] is shown to the user.
class ImageStorageException implements Exception {
  const ImageStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Stores images in Firebase Storage. An interface so tests can use a fake.
abstract class ImageStorage {
  /// Uploads [image] to [path] and returns its download URL.
  /// [onProgress] receives values from 0.0 to 1.0.
  Future<String> upload(
    String path,
    ImageUpload image, {
    void Function(double progress)? onProgress,
  });

  /// Deletes the file at [path]; a missing file is not an error.
  Future<void> delete(String path);
}

class FirebaseImageStorage implements ImageStorage {
  // Same constructor style as the other services (e.g. AuthService).
  // ignore: prefer_initializing_formals
  FirebaseImageStorage({FirebaseStorage? storage}) : _storage = storage;

  final FirebaseStorage? _storage;

  // Resolved on first use so the app can start without Storage configured.
  FirebaseStorage get _instance => _storage ?? FirebaseStorage.instance;

  @override
  Future<String> upload(
    String path,
    ImageUpload image, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // The SDK retries failed uploads for 10 minutes by default. In the
      // browser, uploads to a project without Storage enabled are blocked and
      // look like network errors, so Save would spin for 10 minutes.
      _instance.setMaxUploadRetryTime(const Duration(seconds: 30));
      final ref = _instance.ref(path);
      final task = ref.putData(
        image.bytes,
        SettableMetadata(contentType: image.contentType),
      );
      final progress = task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      }, onError: (_) {}); // the error is reported by `await task` below
      try {
        await task;
      } finally {
        await progress.cancel();
      }
      onProgress?.call(1);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // A new file cannot be "not found": the bucket itself is missing.
      if (e.code == 'object-not-found') {
        throw const ImageStorageException(_storageNotEnabled);
      }
      throw ImageStorageException(describeStorageError(e));
    }
  }

  static const String _storageNotEnabled =
      'Firebase Storage is not enabled for this project, so the image could '
      'not be uploaded and nothing was saved. Enable it in the Firebase '
      'console (Build > Storage > Get started).';

  @override
  Future<void> delete(String path) async {
    try {
      await _instance.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      throw ImageStorageException(describeStorageError(e));
    }
  }

  /// User-friendly text for Firebase Storage error codes.
  static String describeStorageError(FirebaseException e) {
    return switch (e.code) {
      'unauthorized' || 'unauthenticated' =>
        'Image upload was refused by Firebase Storage rules. '
            'Only librarians can upload images.',
      'bucket-not-found' || 'project-not-found' || 'no-default-bucket' =>
        _storageNotEnabled,
      'quota-exceeded' => 'Firebase Storage quota exceeded. Please try later.',
      'retry-limit-exceeded' || 'unknown' =>
        'Could not reach Firebase Storage, so nothing was saved. Either you '
            'are offline, or Storage is not enabled for this project (Firebase '
            'console > Build > Storage > Get started).',
      'canceled' => 'The image upload was cancelled.',
      _ => 'The image upload failed (${e.code}).',
    };
  }
}
