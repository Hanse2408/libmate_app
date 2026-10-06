import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../models/librarian_notification.dart';

/// Decides which notification toast is on screen.
///
/// Listens to the repository's new-notification stream and shows each new
/// Librarian notification once, for [displayDuration] (about 2 seconds).
/// Notifications that arrive together wait in a queue and are shown one
/// after another, never on top of each other. Created and disposed by
/// LibrarianShell, so it only runs while a librarian is signed in.
class LibrarianToastController extends ChangeNotifier {
  LibrarianToastController({
    required Stream<LibrarianNotification> notifications,
    this.displayDuration = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 350),
    bool Function()? isAppVisible,
  }) : _isAppVisible = isAppVisible ?? _appInForeground {
    _subscription = notifications.listen(_onNotification);
  }

  final Duration displayDuration;

  /// Time for the slide in / out animation.
  final Duration animationDuration;
  final bool Function() _isAppVisible;
  late final StreamSubscription<LibrarianNotification> _subscription;

  final Queue<LibrarianNotification> _queue = Queue();

  /// Ids already shown or queued, so a notification is never shown twice.
  final Set<String> _handled = {};
  LibrarianNotification? _current;
  bool _visible = false;
  Timer? _timer;

  /// Time the current banner has been on screen (paused while held).
  final Stopwatch _shown = Stopwatch();
  bool _disposed = false;

  /// The notification in the toast (also while it slides out).
  LibrarianNotification? get current => _current;

  /// True while the toast should be on screen.
  bool get isVisible => _visible;

  /// Number of notifications waiting after the current one.
  int get queued => _queue.length;

  /// False only when the app cannot be seen (in the background or hidden).
  /// "inactive" still counts as visible: e.g. a browser window that is on
  /// screen but not focused.
  static bool _appInForeground() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden &&
        state != AppLifecycleState.detached;
  }

  void _onNotification(LibrarianNotification notification) {
    // An in-app toast cannot be seen while the app is in the background;
    // the notification is still in the Notifications screen.
    if (_disposed || !_isAppVisible() || !_handled.add(notification.id)) return;
    _queue.add(notification);
    _showNext();
  }

  void _showNext() {
    if (_disposed || _current != null || _queue.isEmpty) return;
    _current = _queue.removeFirst();
    _visible = true;
    notifyListeners();
    _shown
      ..reset()
      ..start();
    _timer = Timer(displayDuration, _hide);
  }

  /// The banner is being dragged: keep it until it is released.
  void hold() {
    if (_current == null || !_visible) return;
    _timer?.cancel();
    _shown.stop();
  }

  /// Released without dismissing: show it for the rest of its time.
  void resume() {
    if (_current == null || !_visible || _shown.isRunning) return;
    final left = displayDuration - _shown.elapsed;
    _shown.start();
    _timer = Timer(left.isNegative ? Duration.zero : left, _hide);
  }

  /// Swiped away: it already left the screen, so clear it at once (no
  /// slide-out) and show the next one. It is never shown again.
  void removeNow() {
    if (_current == null) return;
    _timer?.cancel();
    _shown.stop();
    _current = null;
    _visible = false;
    notifyListeners();
    _showNext();
  }

  void _hide() {
    if (_disposed || _current == null || !_visible) return;
    _timer?.cancel();
    _shown.stop();
    _visible = false;
    notifyListeners();
    // After the slide-out, clear it and show the next one, if any.
    _timer = Timer(animationDuration, () {
      if (_disposed) return;
      _current = null;
      notifyListeners();
      _showNext();
    });
  }

  /// Slides the banner away now (close button or tap).
  void dismiss() => _hide();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _subscription.cancel();
    _queue.clear();
    super.dispose();
  }
}
