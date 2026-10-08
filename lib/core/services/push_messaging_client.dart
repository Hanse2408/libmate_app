import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// The custom data fields of a push message. Every field is optional and
/// anything malformed is ignored, so parsing never throws.
class PushPayload {
  const PushPayload({this.type, this.notificationId, this.reservationId, this.itemId});

  final String? type;
  final String? notificationId;
  final String? reservationId;
  final String? itemId;

  factory PushPayload.fromData(Object? data) {
    String? read(Map<Object?, Object?> map, String key) {
      final value = map[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (data is! Map) return const PushPayload();
    return PushPayload(
      type: read(data, 'type'),
      notificationId: read(data, 'notificationId'),
      reservationId: read(data, 'reservationId'),
      itemId: read(data, 'itemId'),
    );
  }

  bool get isEmpty => notificationId == null && reservationId == null && itemId == null;
}

/// The small part of Firebase Messaging the app uses (easy to fake in tests).
abstract class PushMessagingClient {
  /// Asks for notification permission only if it is still undecided.
  /// Returns whether notifications are allowed.
  Future<bool> ensurePermission();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<PushPayload> get onMessage;
  Stream<PushPayload> get onMessageOpenedApp;
  Future<PushPayload?> getInitialMessage();
}

class FirebaseMessagingClient implements PushMessagingClient {
  FirebaseMessagingClient({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<bool> ensurePermission() async {
    var settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await _messaging.requestPermission();
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushPayload> get onMessage =>
      FirebaseMessaging.onMessage.map((m) => PushPayload.fromData(m.data));

  @override
  Stream<PushPayload> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => PushPayload.fromData(m.data));

  @override
  Future<PushPayload?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : PushPayload.fromData(message.data);
  }
}

/// Runs in a background isolate when a push arrives. The system shows the
/// notification itself, so this only makes sure Firebase is initialised.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// Registers the background handler (not supported on web).
void registerPushBackgroundHandler() {
  if (kIsWeb) return;
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
