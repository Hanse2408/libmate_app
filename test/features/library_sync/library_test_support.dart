import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/core/services/image_storage_service.dart';
import 'package:libmate_app/core/services/cloudinary_upload_service.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';

/// Keeps uploaded image bytes in memory and can be told to fail.
class FakeImageStorage implements ImageStorage {
  final Map<String, Uint8List> files = {};
  var _nextId = 0;

  /// When set, uploads throw with this message.
  String? failWith;

  /// When true, uploads never finish (like a blocked browser upload).
  bool hang = false;

  @override
  Future<CloudMediaAsset> upload(
    ImageUpload image, {
    void Function(double progress)? onProgress,
  }) async {
    if (failWith != null) throw ImageStorageException(failWith!);
    if (hang) return Completer<CloudMediaAsset>().future;
    final publicId = 'seat_images/test-${_nextId++}';
    files[publicId] = image.bytes;
    onProgress?.call(1);
    return CloudMediaAsset(
      secureUrl:
          'https://res.cloudinary.com/test/image/upload/$publicId.${image.extension}',
      publicId: publicId,
      resourceType: 'image',
      format: image.extension,
      sizeBytes: image.bytes.length,
      fileName: image.fileName,
    );
  }
}

const librarianUid = 'librarian-1';
const studentUid = 'student-1';
const otherStudentUid = 'student-2';

/// Firestore with one librarian and two student profiles, as created by the
/// existing sign-up / console setup.
Future<FakeFirebaseFirestore> seededFirestore() async {
  final db = FakeFirebaseFirestore();
  await db.collection('users').doc(librarianUid).set({
    'uid': librarianUid,
    'name': 'Janith',
    'email': 'janith@library.test',
    'role': 'librarian',
  });
  await db.collection('users').doc(studentUid).set({
    'uid': studentUid,
    'name': 'Nethmi Perera',
    'studentId': 'IT23004512',
    'email': 'nethmi@student.test',
    'role': 'student',
  });
  await db.collection('users').doc(otherStudentUid).set({
    'uid': otherStudentUid,
    'name': 'Kasun Silva',
    'studentId': 'IT23007789',
    'email': 'kasun@student.test',
    'role': 'student',
  });
  return db;
}

LibrarianFirestoreRepository librarianRepo(
  FakeFirebaseFirestore db,
  FakeImageStorage storage, {
  Duration uploadTimeout = const Duration(minutes: 2),
  Duration writeTimeout = const Duration(seconds: 30),
}) {
  return LibrarianFirestoreRepository(
    firestore: db,
    imageStorage: storage,
    librarianUid: librarianUid,
    uploadTimeout: uploadTimeout,
    writeTimeout: writeTimeout,
  );
}

StudentLibraryRepository studentRepo(
  FakeFirebaseFirestore db, {
  String uid = studentUid,
}) {
  final isFirst = uid == studentUid;
  return StudentLibraryRepository(
    firestore: db,
    student: StudentIdentity(
      uid: uid,
      studentId: isFirst ? 'IT23004512' : 'IT23007789',
      name: isFirst ? 'Nethmi Perera' : 'Kasun Silva',
      email: isFirst ? 'nethmi@student.test' : 'kasun@student.test',
    ),
  );
}

/// Lets Firestore snapshot listeners deliver their latest data.
Future<void> settle() => pumpEventQueue();

/// A real 1x1 PNG, so image previews can decode it.
final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

ImageUpload pngUpload([String name = 'cover.png']) {
  final (image, error) = ImageUpload.validate(
    bytes: _onePixelPng,
    fileName: name,
  );
  expect(error, isNull);
  return image!;
}

DateTime tomorrow() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
}
