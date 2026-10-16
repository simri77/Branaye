import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the JWT access token.
///
/// Preference order:
/// 1. `flutter_secure_storage` (Keychain / Keystore / WebCrypto) — the real thing.
/// 2. `SharedPreferences` — fallback for platforms where the secure backend is
///    unavailable in this environment (e.g. Linux desktop without libsecret).
///
/// The fallback is deliberately logged so it is never a silent downgrade.
class TokenStore {
  TokenStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  static const _key = 'branaye_access_token';

  final FlutterSecureStorage _secure;
  bool _useFallback = false;

  Future<String?> read() async {
    if (!_useFallback) {
      try {
        return await _secure.read(key: _key);
      } catch (error) {
        _fallback(error);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> write(String token) async {
    if (!_useFallback) {
      try {
        await _secure.write(key: _key, value: token);
        return;
      } catch (error) {
        _fallback(error);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    if (!_useFallback) {
      try {
        await _secure.delete(key: _key);
        return;
      } catch (error) {
        _fallback(error);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  void _fallback(Object error) {
    _useFallback = true;
    debugPrint(
      'TokenStore: secure storage unavailable ($error) — falling back to '
      'SharedPreferences. Not suitable for production.',
    );
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
