import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:libmate_app/core/constants/cloudinary_config.dart';
import 'package:libmate_app/core/services/cloudinary_upload_service.dart';
import 'package:libmate_app/core/services/ebook_service.dart';
import 'package:libmate_app/core/services/image_storage_service.dart';

class _ReplyClient extends http.BaseClient {
  _ReplyClient({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  http.MultipartRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request as http.MultipartRequest;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

const _response = '''
{
  "secure_url": "https://res.cloudinary.com/upd9kfcf/image/upload/v123/libmate/example.pdf",
  "public_id": "libmate/example",
  "resource_type": "image",
  "format": "pdf",
  "bytes": 128
}
''';

void main() {
  group('image validation', () {
    test('rejects unsupported image types and images above 5 MB', () {
      expect(
        ImageUpload.validate(
          bytes: Uint8List.fromList([1]),
          fileName: 'file.gif',
        ).$2,
        contains('JPG, PNG or WebP'),
      );
      expect(
        ImageUpload.validate(
          bytes: Uint8List(ImageUpload.maxBytes + 1),
          fileName: 'large.png',
        ).$2,
        contains('5 MB'),
      );
    });
  });

  test('unsigned image upload parses metadata and sends configured multipart fields', () async {
    final client = _ReplyClient(statusCode: 200, body: _response);
    final storage = CloudinaryImageStorage(
      uploader: CloudinaryUploadClient(client: client),
    );
    final (image, error) = ImageUpload.validate(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'seat.png',
    );
    expect(error, isNull);

    final asset = await storage.upload(image!);

    expect(asset.secureUrl, contains('https://'));
    expect(asset.publicId, 'libmate/example');
    expect(asset.resourceType, 'image');
    expect(asset.format, 'pdf');
    expect(asset.sizeBytes, 128);
    expect(asset.fileName, 'seat.png');
    expect(
      client.request!.url.toString(),
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    expect(client.request!.fields, {
      'upload_preset': CloudinaryConfig.imageUploadPreset,
    });
    expect(client.request!.files.single.field, 'file');
    expect(client.request!.files.single.filename, 'seat.png');
  });

  test(
    'unsigned PDF upload uses the PDF preset and parses secure_url',
    () async {
      final client = _ReplyClient(statusCode: 200, body: _response);
      final storage = CloudinaryEbookFileStorage(
        uploader: CloudinaryUploadClient(client: client),
      );
      final (pdf, error) = PdfFile.validate(
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]),
        fileName: 'sample.pdf',
      );
      expect(error, isNull);

      final asset = await storage.upload(pdf!);

      expect(
        asset.secureUrl,
        'https://res.cloudinary.com/upd9kfcf/image/upload/v123/libmate/example.pdf',
      );
      expect(client.request!.fields, {
        'upload_preset': CloudinaryConfig.pdfUploadPreset,
      });
      expect(client.request!.files.single.filename, 'sample.pdf');
    },
  );

  test('rejects provider errors and malformed success responses with safe messages', () async {
    final rejected = CloudinaryImageStorage(
      uploader: CloudinaryUploadClient(
        client: _ReplyClient(
          statusCode: 415,
          body: '{"error":"private provider detail"}',
        ),
      ),
    );
    final (image, _) = ImageUpload.validate(
      bytes: Uint8List.fromList([1]),
      fileName: 'seat.jpg',
    );
    await expectLater(
      rejected.upload(image!),
      throwsA(
        isA<ImageStorageException>().having(
          (error) => error.message,
          'message',
          contains('rejected'),
        ),
      ),
    );

    final invalid = CloudinaryImageStorage(
      uploader: CloudinaryUploadClient(
        client: _ReplyClient(
          statusCode: 200,
          body: '{"public_id":"missing-url"}',
        ),
      ),
    );
    await expectLater(
      invalid.upload(image),
      throwsA(
        isA<ImageStorageException>().having(
          (error) => error.message,
          'message',
          contains('invalid upload response'),
        ),
      ),
    );
  });
}
