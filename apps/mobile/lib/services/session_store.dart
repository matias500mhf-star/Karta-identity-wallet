import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  static const _accessKey = 'karta.access_token';
  static const _refreshKey = 'karta.refresh_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> accessToken() => _storage.read(key: _accessKey);
  Future<void> clear() => _storage.deleteAll();
}
