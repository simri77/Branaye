import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_provider.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});

class FcmService {
  FcmService(this._ref);
  final Ref _ref;

  Future<void> init() async {
    if (defaultTargetPlatform == TargetPlatform.windows) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FCM foreground message: ${message.notification?.title ?? 'Notification'}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        'FCM app opened from notification: ${message.notification?.title ?? 'Notification'}',
      );
    });

    final token = await messaging.getToken();
    if (token == null) return;

    try {
      await _ref
          .read(dioProvider)
          .post('/auth/fcm-token', data: {'token': token});
    } catch (_) {}
  }
}
