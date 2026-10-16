import 'package:flutter/foundation.dart';

/// Base URL of the Branaye backend.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api
///
/// Defaults by platform:
/// - Android emulator reaches the host machine at 10.0.2.2
/// - Web / desktop / iOS simulator reach it at localhost
const String _override = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_override.isNotEmpty) return _override;
  if (kIsWeb) return 'http://localhost:3000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}
