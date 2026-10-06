import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../constants/cloudinary_config.dart';
import 'cloudinary_upload_service.dart';

/// An image the user picked, ready to upload. Only the bytes are uploaded to
/// Cloudinary; Firestore stores its URL and public ID.
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

  /// "jpg", "png" or "webp", used for the uploaded file name.
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
      return (
        null,
        'The image is larger than 5 MB. Please choose a smaller one.',
      );
    }
    return (
      ImageUpload(bytes: bytes, fileName: fileName, contentType: type),
      null,
    );
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

/// Stores images remotely. An interface so tests can use a fake.
abstract class ImageStorage {
  /// Uploads [image] and returns the Cloudinary asset metadata.
  Future<CloudMediaAsset> upload(
    ImageUpload image, {
    void Function(double progress)? onProgress,
  });
}

class CloudinaryImageStorage implements ImageStorage {
  CloudinaryImageStorage({CloudinaryUploadClient? uploader})
    : _uploader = uploader ?? CloudinaryUploadClient();

  final CloudinaryUploadClient _uploader;

  @override
  Future<CloudMediaAsset> upload(
    ImageUpload image, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      return await _uploader.upload(
        bytes: image.bytes,
        fileName: image.fileName,
        uploadPreset: CloudinaryConfig.imageUploadPreset,
        onProgress: onProgress,
      );
    } on CloudinaryUploadException catch (e) {
      throw ImageStorageException(e.message);
    }
  }
}
