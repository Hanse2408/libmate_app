import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/core/services/image_storage_service.dart';
import 'package:libmate_app/features/librarian/data/librarian_firestore_repository.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';

/// Stands in for Firebase Storage: keeps uploaded files in a map and can be
/// told to fail, like a missing bucket or a rules refusal.
class FakeImageStorage implements ImageStorage {
  final Map<String, Uint8List> files = {};
  final List<String> deleted = [];

  /// When set, uploads throw with this message.
  String? failWith;

  /// When true, uploads never finish (like a blocked browser upload).
  bool hang = false;

  @override
  Future<String> upload(
    String path,
    ImageUpload image, {
    void Function(double progress)? onProgress,
  }) async {
    if (failWith != null) throw ImageStorageException(failWith!);
    if (hang) return Completer<String>().future;
    onProgress?.call(0.5);
    files[path] = image.bytes;
    onProgress?.call(1);
    return 'https://storage.test/$path';
  }

  @override
  Future<void> delete(String path) async {
    files.remove(path);
    deleted.add(path);
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
