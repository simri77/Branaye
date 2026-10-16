import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Broadcasts "the server rejected our token" so the auth layer can log out.
///
/// The Dio interceptor cannot import the auth notifier directly — that would be
/// a circular dependency. Instead it fires this event and whoever owns the
/// session decides what to do. Keeps the HTTP layer free of app state.
class SessionEvents {
  SessionEvents();

  final _unauthorized = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _unauthorized.stream;

  void fireUnauthorized() {
    if (!_unauthorized.isClosed) _unauthorized.add(null);
  }

  void dispose() => _unauthorized.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
