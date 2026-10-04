import 'package:firebase_core/firebase_core.dart';

/// Thrown inside a Firestore transaction when a rule refuses the action
/// (e.g. "no copies left"). The transaction is rolled back and [message] is
/// shown to the user.
class ActionRefused implements Exception {
  const ActionRefused(this.message);
  final String message;

  @override
  String toString() => message;
}

/// User-friendly text for Cloud Firestore error codes, so a failed write is
/// reported instead of looking like a success.
String describeFirestoreError(FirebaseException e) {
  return switch (e.code) {
    'permission-denied' =>
      'You do not have permission to do this. Check that your account has '
          'the right role and that the Firestore security rules are deployed.',
    'unavailable' || 'deadline-exceeded' =>
      'Cannot reach the database. Check your internet connection and try again.',
    'not-found' => 'This record no longer exists.',
    'aborted' => 'Someone else changed this record at the same time. Please try again.',
    'failed-precondition' =>
      'The database is not ready for this request (a Firestore index or '
          'setting may be missing).',
    'unauthenticated' => 'Please sign in again.',
    _ => 'The database request failed (${e.code}). Please try again.',
  };
}
