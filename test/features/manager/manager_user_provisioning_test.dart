import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/features/manager/data/manager_firestore_repository.dart';
import 'package:libmate_app/models/user.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

class TemporaryApp implements FirebaseApp {
  TemporaryApp(this.events);
  final List<String> events;
  @override
  Future<void> delete() async {
    events.add('dispose');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CreatedUser implements User {
  CreatedUser(this.auth);
  final SecondaryAuth auth;
  @override
  String get uid => 'real-firebase-uid';
  @override
  Future<void> delete() async {
    expect(auth.signedIn, true);
    auth.events.add('rollback');
    if (auth.failRollback) throw StateError('delete failed');
    auth.emails.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Credential implements UserCredential {
  Credential(this.user);
  @override
  final User user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SecondaryAuth implements FirebaseAuth {
  final events = <String>[];
  final emails = <String>{};
  bool signedIn = false;
  bool failRollback = false;
  bool failSignOut = false;
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!emails.add(email)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    signedIn = true;
    events.add('create');
    return Credential(CreatedUser(this));
  }

  @override
  Future<void> signOut() async {
    events.add('signOut');
    if (failSignOut) throw StateError('sign-out failed');
    signedIn = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ManagerFirestoreRepository repository(
  FakeFirebaseFirestore db,
  SecondaryAuth auth,
) => ManagerFirestoreRepository(
  firestore: db,
  managerUid: 'manager-uid',
  createSecondaryApp: () async => TemporaryApp(auth.events),
  secondaryAuthFor: (_) => auth,
);

void main() {
  for (final role in UserRole.values) {
    test(
      'Add ${role.name} saves real UID and active profile using Manager database',
      () async {
        final db = FakeFirebaseFirestore();
        final auth = SecondaryAuth();
        final repo = repository(db, auth);
        addTearDown(repo.dispose);
        final result = await repo.addUser(
          name: ' New User ',
          email: ' user@test.com ',
          password: 'secret123',
          role: role,
          institutionId: ' ID123 ',
        );
        expect(result.success, true);
        final docs = await db.collection('users').get();
        expect(docs.docs.single.id, 'real-firebase-uid');
        expect(
          docs.docs.single.data(),
          containsPair('uid', 'real-firebase-uid'),
        );
        expect(docs.docs.single.data(), containsPair('role', role.name));
        expect(
          docs.docs.single.data(),
          containsPair('accountStatus', 'active'),
        );
        expect(docs.docs.single.data(), containsPair('studentId', 'ID123'));
        expect(repo.managerUid, 'manager-uid');
        expect(auth.events, ['create', 'signOut', 'dispose']);
      },
    );
  }

  test(
    'profile failure rolls back before sign-out and retry reuses email',
    () async {
      final auth = SecondaryAuth();
      final failedDb = FakeFirebaseFirestore();
      whenCalling(Invocation.method(#set, null))
          .on(failedDb.collection('users').doc('real-firebase-uid'))
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );
      final repo = repository(failedDb, auth);
      addTearDown(repo.dispose);
      final result = await repo.addUser(
        name: 'User',
        email: 'retry@test.com',
        password: 'secret123',
        role: UserRole.student,
      );
      expect(result.success, false);
      expect(result.message, contains('rolled back'));
      expect(auth.events, ['create', 'rollback', 'signOut', 'dispose']);
      expect(auth.emails, isEmpty);
      expect((await failedDb.collection('users').get()).docs, isEmpty);

      final retry = repository(FakeFirebaseFirestore(), auth);
      addTearDown(retry.dispose);
      expect(
        (await retry.addUser(
          name: 'User',
          email: 'retry@test.com',
          password: 'secret123',
          role: UserRole.student,
        )).success,
        true,
      );
    },
  );

  test(
    'rollback failure reports manual cleanup and still disposes app',
    () async {
      final auth = SecondaryAuth()
        ..failRollback = true
        ..failSignOut = true;
      final db = FakeFirebaseFirestore();
      whenCalling(Invocation.method(#set, null))
          .on(db.collection('users').doc('real-firebase-uid'))
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );
      final repo = repository(db, auth);
      addTearDown(repo.dispose);
      final result = await repo.addUser(
        name: 'User',
        email: 'cleanup@test.com',
        password: 'secret123',
        role: UserRole.manager,
      );
      expect(result.success, false);
      expect(result.message, contains('may need manual cleanup'));
      expect(auth.events, ['create', 'rollback', 'signOut', 'dispose']);
    },
  );

  test(
    'activate/deactivate, self guards, and editing preserves status and email',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('other').set({
        'uid': 'other',
        'name': 'Other',
        'email': 'other@test.com',
        'role': 'student',
        'accountStatus': 'inactive',
      });
      await db.collection('users').doc('manager-uid').set({
        'uid': 'manager-uid',
        'name': 'Manager',
        'email': 'manager@test.com',
        'role': 'manager',
        'accountStatus': 'active',
      });
      final repo = repository(db, SecondaryAuth());
      addTearDown(repo.dispose);
      expect(
        (await repo.setAccountStatus('other', AccountStatus.active)).success,
        true,
      );
      expect(
        (await db.collection('users').doc('other').get())
            .data()!['accountStatus'],
        'active',
      );
      expect(
        (await repo.setAccountStatus('other', AccountStatus.inactive)).success,
        true,
      );
      expect(
        (await repo.setAccountStatus(
          'manager-uid',
          AccountStatus.inactive,
        )).success,
        false,
      );
      expect(
        (await repo.setAccountStatus('other', AccountStatus.suspended)).success,
        false,
      );
      expect(
        (await repo.updateUser(
          'manager-uid',
          name: 'Manager',
          role: UserRole.student,
        )).success,
        false,
      );
      expect(
        (await repo.updateUser(
          'other',
          name: 'Edited',
          role: UserRole.librarian,
          institutionId: 'STAFF123',
        )).success,
        true,
      );
      final data = (await db.collection('users').doc('other').get()).data()!;
      expect(data['accountStatus'], 'inactive');
      expect(data['email'], 'other@test.com');
      expect(data['uid'], 'other');
      expect(data['studentId'], 'STAFF123');
    },
  );
}
