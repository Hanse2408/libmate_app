import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/core/services/image_storage_service.dart';
import 'package:libmate_app/features/student/common/data/student_library_repository.dart';
import 'package:libmate_app/features/student/common/widgets/edit_profile_dialog.dart';
import 'package:libmate_app/features/student/common/widgets/student_avatar.dart';
import 'library_test_support.dart';

class _Picker extends ImagePickerService {
  _Picker(this.image);
  final ImageUpload image;
  @override
  Future<(ImageUpload?, String?)> pickImage() async => (image, null);
}

StudentLibraryRepository repository(FakeFirebaseFirestore db, FakeImageStorage storage) =>
  StudentLibraryRepository(firestore: db, profileImages: storage,
    student: const StudentIdentity(uid: studentUid, name: 'Nethmi Perera',
      studentId: 'IT23004512', email: 'nethmi@student.test'));

void main() {
  test('photo saves, persists, replaces and removes without changing other user fields', () async {
    final db = await seededFirestore(); final storage = FakeImageStorage();
    final library = repository(db, storage); addTearDown(library.dispose); await settle();
    expect((await library.updateProfile(name: library.student.name, phone: '', photo: pngUpload())).success, true);
    await settle();
    final firstUrl = library.student.photoUrl;
    expect(firstUrl, isNotNull);
    final reopened = repository(db, storage); addTearDown(reopened.dispose); await settle();
    expect(reopened.student.photoUrl, firstUrl);
    await library.updateProfile(name: library.student.name, phone: '', photo: pngUpload('replacement.png'));
    await settle(); expect(library.student.photoUrl, isNot(firstUrl));
    final replacementUrl = library.student.photoUrl;
    storage.failWith = 'Upload failed';
    final failed = await library.updateProfile(name: 'Unsaved Name', phone: '', photo: pngUpload());
    expect(failed.success, false); await settle();
    expect(library.student.photoUrl, replacementUrl); expect(library.student.name, 'Nethmi Perera');
    await library.updateProfile(name: library.student.name, phone: '', removePhoto: true);
    await settle(); expect(library.student.photoUrl, isNull);
    final data = (await db.collection('users').doc(studentUid).get()).data()!;
    expect(data.containsKey('photoPublicId'), false); expect(data['role'], 'student');
    expect(data['studentId'], 'IT23004512'); expect(data['email'], 'nethmi@student.test');
  });

  for (final dark in [false, true]) {
    testWidgets('photo preview and cancel do not upload; save uploads once, dark: $dark', (tester) async {
      tester.view.physicalSize = const Size(360, 1200); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final originalPicker = ImagePickerService.instance;
      ImagePickerService.instance = _Picker(pngUpload());
      addTearDown(() => ImagePickerService.instance = originalPicker);
      final db = await seededFirestore(); final storage = FakeImageStorage();
      final library = repository(db, storage); addTearDown(library.dispose);
      await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: Builder(builder: (context) => TextButton(
          onPressed: () => showDialog<void>(context: context, builder: (_) => EditProfileDialog(library: library)),
          child: const Text('Edit'))))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit')); await tester.pumpAndSettle();
      await tester.tap(find.text('Choose photo')); await tester.pumpAndSettle();
      expect(tester.widget<StudentAvatar>(find.byType(StudentAvatar)).preview, isNotNull);
      expect(storage.files, isEmpty);
      await tester.ensureVisible(find.text('Cancel')); await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle(); expect(library.student.photoUrl, isNull);
      expect(storage.files, isEmpty);
      await tester.tap(find.text('Edit')); await tester.pumpAndSettle();
      await tester.tap(find.text('Choose photo')); await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save changes')); await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(storage.files, hasLength(1)); expect(library.student.photoUrl, isNotNull);
      expect(find.byType(EditProfileDialog), findsNothing); expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
