import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/providers/auth_provider.dart';

/// Decides when the start-up splash may give way to the normal routes:
/// once Firebase has reported the saved sign-in state (and, for a signed-in
/// user, their profile / role has loaded) and the splash has been visible
/// for at least [minimumDisplay] since launch. No fixed long delay: if
/// start-up takes longer than the minimum, the splash leaves as soon as it
/// is done.
class AppStartup extends ChangeNotifier {
  AppStartup({
    required this._auth,
    Stopwatch? sinceLaunch,
    this.minimumDisplay = const Duration(seconds: 5),
    this.maximumAuthWait = const Duration(seconds: 8),
  }) : _sinceLaunch = sinceLaunch ?? (Stopwatch()..start()) {
    _auth.addListener(_update);
    final elapsed = _sinceLaunch.elapsed;
    _minimumTimer = Timer(_remaining(minimumDisplay, elapsed), () {
      _minimumShown = true;
      _update();
    });
    // Never keep the splash forever if Firebase does not answer.
    _fallbackTimer = Timer(_remaining(maximumAuthWait, elapsed), () {
      _authTimedOut = true;
      _update();
    });
    _update();
  }

  final AuthProvider _auth;
  final Stopwatch _sinceLaunch;

  /// Shortest time the splash is shown (counted from app launch).
  final Duration minimumDisplay;

  /// Longest wait for Firebase to report the sign-in state.
  final Duration maximumAuthWait;

  late final Timer _minimumTimer;
  late final Timer _fallbackTimer;
  bool _minimumShown = false;
  bool _authTimedOut = false;
  bool _isReady = false;

  /// True once the app may leave the splash.
  bool get isReady => _isReady;

  static Duration _remaining(Duration target, Duration elapsed) =>
      target > elapsed ? target - elapsed : Duration.zero;

  void _update() {
    if (_isReady) return;
    final authDone =
        _authTimedOut || (_auth.isAuthResolved && !_auth.isProfileLoading);
    if (_minimumShown && authDone) {
      _isReady = true;
      _auth.removeListener(_update);
      _fallbackTimer.cancel();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _minimumTimer.cancel();
    _fallbackTimer.cancel();
    _auth.removeListener(_update);
    super.dispose();
  }
}
