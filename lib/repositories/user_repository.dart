import '../core/services/user_service.dart';
import '../models/user.dart';

/// Sits between AuthProvider and UserService. Holds no Firestore calls itself.
class UserRepository {
  UserRepository({UserService? userService})
    : _userService = userService ?? UserService();

  final UserService _userService;

  Future<void> createUserProfile(AppUser user) {
    return _userService.createUserProfile(user);
  }

  Future<AppUser?> getUserProfile(String uid) {
    return _userService.getUserProfile(uid);
  }
}
