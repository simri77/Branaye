import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_provider.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});

class FcmService {
  FcmService(this._ref);
  final Ref _ref;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      try {
        await _ref.read(dioProvider).post('/auth/fcm-token', data: {'token': token});
      } catch (_) {}
    }
    FirebaseMessaging.onMessage.listen((_) {});
    FirebaseMessaging.onMessageOpenedApp.listen((_) {});
  }
}
