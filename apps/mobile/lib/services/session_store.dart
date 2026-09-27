import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const int _pinIterations = 210000;
const int _pinSaltBytes = 16;

Future<String> derivePinVerifier({
  required String pin,
  required List<int> salt,
}) async {
  final algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pinIterations,
    bits: 256,
  );
  final derived = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(pin)),
    nonce: salt,
  );
  return base64UrlEncode(await derived.extractBytes());
}

bool constantTimeStringEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

class SessionStore {
  static const _walletCreatedKey = 'karta.wallet_created';
  static const _legacyPinKey = 'karta.pin';
  static const _pinHashKey = 'karta.pin_hash.v2';
  static const _pinSaltKey = 'karta.pin_salt.v2';
  static const _nameKey = 'karta.wallet_name';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> walletCreated() async =>
      (await _storage.read(key: _walletCreatedKey)) == 'true';

  Future<void> createWallet({
    required String pin,
    String name = 'A minha KARTA',
  }) async {
    await _storePinVerifier(pin);
    await _storage.write(key: _walletCreatedKey, value: 'true');
    await _storage.write(key: _nameKey, value: name);
  }

  Future<void> _storePinVerifier(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(
      _pinSaltBytes,
      (_) => random.nextInt(256),
      growable: false,
    );
    final verifier = await derivePinVerifier(pin: pin, salt: salt);

    await _storage.write(key: _pinSaltKey, value: base64UrlEncode(salt));
    await _storage.write(key: _pinHashKey, value: verifier);

    // Remove the Alpha legacy plaintext PIN after creating/migrating a verifier.
    await _storage.delete(key: _legacyPinKey);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final encodedSalt = await _storage.read(key: _pinSaltKey);

    if (storedHash != null && encodedSalt != null) {
      try {
        final salt = base64Url.decode(encodedSalt);
        final candidate = await derivePinVerifier(pin: pin, salt: salt);
        return constantTimeStringEquals(candidate, storedHash);
      } catch (_) {
        return false;
      }
    }

    // One-time compatibility path for Alpha wallets created before v2.
    final legacyPin = await _storage.read(key: _legacyPinKey);
    if (legacyPin == null || !constantTimeStringEquals(pin, legacyPin)) {
      return false;
    }
    await _storePinVerifier(pin);
    return true;
  }

  Future<String> walletName() async =>
      await _storage.read(key: _nameKey) ?? 'A minha KARTA';

  Future<void> deleteWallet() => _storage.deleteAll();
}
