import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/push_messaging_client.dart';
import '../../../../models/notification.dart';
import '../../common/data/student_library_repository.dart';
import '../screens/student_notifications_screen.dart';
import '../widgets/notification_navigation.dart';

/// Client-side push (FCM) support for a signed-in student: stores this
/// device's token, keeps it fresh, removes it on logout and opens the right
/// screen when a system notification is tapped. Foreground messages are only
/// logged, because the Firestore in-app banner already covers them.
class StudentPushController {
  StudentPushController({
    required this.context,
    required this.library,
    required this.client,
    this.waitForNotifications = const Duration(seconds: 3),
  }) {
    library.beforeSignOut = removeCurrentToken;
    _start();
  }

  /// Context of a widget below the app Navigator.
  final BuildContext context;
  final StudentLibraryRepository library;
  final PushMessagingClient client;
  final Duration waitForNotifications;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _token;
  bool _disposed = false;

  Future<void> _start() async {
    try {
      _subscriptions.add(client.onTokenRefresh.listen(_onTokenRefresh));
      _subscriptions.add(client.onMessage.listen(_onForegroundMessage));
      _subscriptions.add(client.onMessageOpenedApp.listen(handleTap));
      if (await client.ensurePermission()) {
        final token = await client.getToken();
        if (token != null && token.isNotEmpty) {
          if (kDebugMode) debugPrint('FCM token: $token');
          await _store(token);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FCM setup skipped: $e');
    }
    try {
      final initial = await client.getInitialMessage();
      if (initial != null && !_disposed) await handleTap(initial);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM initial message ignored: $e');
    }
  }

  Future<void> _store(String token) async {
    final previous = _token;
    _token = token;
    await library.addFcmToken(token);
    if (previous != null && previous != token) {
      await library.removeFcmToken(previous);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    try {
      await _store(token);
    } catch (_) {}
  }

  void _onForegroundMessage(PushPayload payload) {
    // The Firestore in-app banner is the foreground UX; nothing to show here.
    if (kDebugMode) debugPrint('FCM foreground message: ${payload.type}');
  }

  /// Removes only this device's token (called before sign-out; never throws).
  Future<void> removeCurrentToken() async {
    try {
      final token = _token ?? await client.getToken();
      if (token != null) await library.removeFcmToken(token);
      _token = null;
      await client.deleteToken();
    } catch (_) {}
  }

  /// Opens the destination for a tapped system notification.
  Future<void> handleTap(PushPayload payload) async {
    try {
      if (_disposed || !context.mounted) return;
      if (payload.isEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => StudentNotificationsScreen(library: library)),
        );
        return;
      }
      final stored = await _findStored(payload.notificationId);
      if (!context.mounted) return;
      // No stored copy: open the same destination without marking anything.
      final notification =
          stored ??
          StudentNotification(
            id: '',
            recipientUid: library.student.uid,
            type: StudentNotificationType.fromName(payload.type),
            title: '',
            message: '',
            createdAt: DateTime.now(),
            reservationId: payload.reservationId,
            itemId: payload.itemId,
          );
      await openStudentNotification(context, library, notification, markRead: stored != null);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM tap ignored: $e');
    }
  }

  Future<StudentNotification?> _findStored(String? id) async {
    if (id == null) return null;
    StudentNotification? find() => library.notifications.where((n) => n.id == id).firstOrNull;
    final now = find();
    if (now != null) return now;
    // The list may still be loading right after a cold start.
    final done = Completer<void>();
    void listener() {
      if (find() != null && !done.isCompleted) done.complete();
    }

    library.addListener(listener);
    try {
      await done.future.timeout(waitForNotifications);
    } on TimeoutException {
      // Fall through to the payload-only destination.
    } finally {
      library.removeListener(listener);
    }
    return find();
  }

  void dispose() {
    _disposed = true;
    if (library.beforeSignOut == removeCurrentToken) {
      library.beforeSignOut = null;
    }
    for (final s in _subscriptions) {
      s.cancel();
    }
  }
}
