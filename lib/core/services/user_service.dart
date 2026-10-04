import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user.dart';

/// Wraps all direct Firestore calls for the `users` collection.
class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUserProfile(AppUser user) {
    return _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }
}
