import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/student/common/screens/profile_screen.dart';
import 'package:libmate_app/features/student/common/widgets/edit_profile_dialog.dart';
import 'library_test_support.dart';

void main() {
  test('profile edits persist without changing account identity or saved library data', () async {
    final db = await seededFirestore(); final library = studentRepo(db);
    addTearDown(library.dispose);
    await library.setFavorite('book', favorite: true);
    await settle();
    expect((await library.updateProfile(name: '  Updated Student  ', phone: '+94 77 123 4567')).success, true);
    await settle();
    expect(library.student.name, 'Updated Student');
    expect(library.student.phone, '+94 77 123 4567');
    final data = (await db.collection('users').doc(studentUid).get()).data()!;
    expect(data['uid'], studentUid); expect(data['role'], 'student');
    expect(data['studentId'], 'IT23004512'); expect(data['email'], 'nethmi@student.test');
    expect(data['favoriteBookIds'], ['book']);
    final reopened = studentRepo(db); addTearDown(reopened.dispose); await settle();
    expect(reopened.student.name, 'Updated Student');
    expect(reopened.student.phone, '+94 77 123 4567');
    expect((await library.updateProfile(name: '', phone: '')).success, false);
    expect((await library.updateProfile(name: 'Valid Name', phone: 'abc')).success, false);
    expect((await library.updateProfile(name: 'Valid Name', phone: '')).success, true);
  });
  testWidgets('failed save keeps edits visible and does not change profile', (tester) async {
    final db = await seededFirestore(); final library = studentRepo(db);
    addTearDown(library.dispose);
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(library: library)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit profile')); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('profile-name')), 'Unsaved Name');
    whenCalling(Invocation.method(#update, null)).on(db.collection('users').doc(studentUid))
      .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
    await tester.ensureVisible(find.text('Save changes')); await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileDialog), findsOneWidget);
    expect(library.student.name, 'Nethmi Perera');
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('profile-name'))).controller!.text, 'Unsaved Name');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [false, true]) {
    testWidgets('real profile, cancel, validation and save, dark: $dark', (tester) async {
      tester.view.physicalSize = const Size(360, 1000); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = await seededFirestore(); final library = studentRepo(db);
      addTearDown(library.dispose);
      await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
        home: ProfileScreen(library: library)));
      await tester.pumpAndSettle();
      expect(find.text('Nethmi Perera'), findsOneWidget);
      expect(find.text('Nilumi Dakshika'), findsNothing);
      await tester.tap(find.byTooltip('Edit profile')); await tester.pumpAndSettle();
      expect(find.byType(EditProfileDialog), findsOneWidget);
      final name = find.byKey(const ValueKey('profile-name'));
      await tester.enterText(name, 'Discard This');
      await tester.ensureVisible(find.text('Cancel')); await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle(); expect(library.student.name, 'Nethmi Perera');
      await tester.tap(find.byTooltip('Edit profile')); await tester.pumpAndSettle();
      await tester.enterText(name, '');
      await tester.ensureVisible(find.text('Save changes')); await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle(); expect(find.text('Enter a name between 2 and 80 characters.'), findsOneWidget);
      await tester.enterText(name, 'Edited Student');
      await tester.enterText(find.byKey(const ValueKey('profile-phone')), '0771234567');
      await tester.ensureVisible(find.text('Save changes')); await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileDialog), findsNothing);
      expect(find.text('Edited Student'), findsOneWidget);
      expect(library.student.phone, '0771234567');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
