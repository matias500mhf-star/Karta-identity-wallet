import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  static const _walletCreatedKey = 'karta.wallet_created';
  static const _pinKey = 'karta.pin';
  static const _nameKey = 'karta.wallet_name';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> walletCreated() async =>
      (await _storage.read(key: _walletCreatedKey)) == 'true';

  Future<void> createWallet({
    required String pin,
    String name = 'A minha KARTA',
  }) async {
    await _storage.write(key: _walletCreatedKey, value: 'true');
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _nameKey, value: name);
  }

  Future<bool> verifyPin(String pin) async =>
      (await _storage.read(key: _pinKey)) == pin;

  Future<String> walletName() async =>
      await _storage.read(key: _nameKey) ?? 'A minha KARTA';

  Future<void> deleteWallet() => _storage.deleteAll();
}
