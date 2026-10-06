import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/cloudinary_config.dart';

class CloudMediaAsset {
  const CloudMediaAsset({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.sizeBytes,
    required this.fileName,
  });

  final String secureUrl;
  final String publicId;
  final String resourceType;
  final String format;
  final int sizeBytes;
  final String fileName;
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sends unsigned multipart uploads and converts Cloudinary's response to a
/// small typed value rather than exposing provider JSON to app features.
/// Asset deletion is deliberately excluded because Cloudinary requires a
/// server-side signature for destroy requests.
class CloudinaryUploadClient {
  CloudinaryUploadClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<CloudMediaAsset> upload({
    required Uint8List bytes,
    required String fileName,
    required String uploadPreset,
    void Function(double progress)? onProgress,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.https(
              'api.cloudinary.com',
              '/v1_1/${CloudinaryConfig.cloudName}/image/upload',
            ),
          )
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 400 || response.statusCode == 415) {
          throw const CloudinaryUploadException(
            'Cloudinary rejected this file type. Choose a supported file and try again.',
          );
        }
        throw CloudinaryUploadException(
          'Cloudinary upload failed (HTTP ${response.statusCode}). Please try again.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const CloudinaryUploadException(
          'Cloudinary returned an invalid upload response. Please try again.',
        );
      }
      final secureUrl = decoded['secure_url'];
      final publicId = decoded['public_id'];
      final resourceType = decoded['resource_type'];
      final format = decoded['format'];
      final size = decoded['bytes'];
      final uri = secureUrl is String ? Uri.tryParse(secureUrl) : null;
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          publicId is! String ||
          publicId.trim().isEmpty ||
          resourceType is! String ||
          resourceType.trim().isEmpty ||
          format is! String ||
          format.trim().isEmpty ||
          size is! num ||
          size < 0) {
        throw const CloudinaryUploadException(
          'Cloudinary returned an invalid upload response. Please try again.',
        );
      }

      onProgress?.call(1);
      return CloudMediaAsset(
        secureUrl: secureUrl,
        publicId: publicId,
        resourceType: resourceType,
        format: format,
        sizeBytes: size.toInt(),
        fileName: fileName,
      );
    } on CloudinaryUploadException {
      rethrow;
    } on TimeoutException {
      throw const CloudinaryUploadException(
        'Cloudinary upload timed out. Check your internet connection and try again.',
      );
    } on http.ClientException {
      throw const CloudinaryUploadException(
        'Could not reach Cloudinary. Check your internet connection and try again.',
      );
    } on FormatException {
      throw const CloudinaryUploadException(
        'Cloudinary returned an invalid upload response. Please try again.',
      );
    }
  }
}
