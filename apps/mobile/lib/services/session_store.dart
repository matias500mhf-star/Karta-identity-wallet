import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

bool constantTimeStringEquals(String a, String b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return difference == 0;
}

class SessionStore {
  static const _walletCreatedKey = 'karta.wallet_created';
  static const _pinKey = 'karta.pin';
  static const _pinV2Key = 'karta.pin.v2';
  static const _nameKey = 'karta.wallet_name';
  static const _walletCreatePendingKey = 'karta.wallet_create.pending';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> walletCreated() async {
    await recoverInterruptedWalletCreation();
    return (await _storage.read(key: _walletCreatedKey)) == 'true';
  }

  Future<void> recoverInterruptedWalletCreation() async {
    if (await _storage.read(key: _walletCreatePendingKey) != 'true') {
      return;
    }
    if (await _storage.read(key: _walletCreatedKey) == 'true') {
      await _storage.delete(key: _walletCreatePendingKey);
      return;
    }
    await _clearIncompleteWalletCreation();
  }

  Future<void> createWallet({
    required String pin,
    String name = 'A minha KARTA',
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('PIN inválido.');
    }
    if (await _storage.read(key: _walletCreatedKey) == 'true') {
      throw StateError('Já existe uma carteira neste dispositivo.');
    }

    await recoverInterruptedWalletCreation();
    await _storage.write(key: _walletCreatePendingKey, value: 'true');
    try {
      await _savePin(pin);
      await _storage.write(key: _nameKey, value: name);
      await _storage.write(key: _walletCreatedKey, value: 'true');
    } catch (error, stackTrace) {
      try {
        await _clearIncompleteWalletCreation();
      } catch (_) {
        // Keep the original failure. The pending marker, if it could not be
        // removed, will trigger another safe cleanup on the next startup.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    // wallet_created is the commit point. Failure to remove only the marker
    // must never roll back an otherwise complete wallet; startup recovery can
    // safely remove a stale marker after confirming the committed state.
    try {
      await _storage.delete(key: _walletCreatePendingKey);
    } catch (_) {
      // Intentionally leave the marker for recoverInterruptedWalletCreation().
    }
  }

  Future<void> _clearIncompleteWalletCreation() async {
    await _storage.delete(key: _walletCreatedKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _pinV2Key);
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _walletCreatePendingKey);
  }

  static bool _checking = false;
  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );

  Future<void> _savePin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    await _storage.write(
      key: _pinV2Key,
      value: jsonEncode({
        'salt': base64Encode(salt),
        'hash': base64Encode(await hash.extractBytes()),
      }),
    );
    await _storage.delete(key: _pinKey);
  }

  Future<bool> verifyPin(String pin) async {
    if (_checking) {
      return false;
    }
    _checking = true;
    try {
      final until =
          int.tryParse(await _storage.read(key: 'karta.pin.lockUntil') ?? '') ??
          0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < until) {
        throw StateError('Aguarde antes de tentar novamente.');
      }
      final record = await _storage.read(key: _pinV2Key);
      bool valid = false;
      if (record == null) {
        final old = await _storage.read(key: _pinKey);
        valid = old != null && constantTimeStringEquals(pin, old);
        if (valid) {
          await _savePin(pin);
        }
      } else {
        final data = jsonDecode(record) as Map;
        final hash = await _kdf.deriveKey(
          secretKey: SecretKey(utf8.encode(pin)),
          nonce: base64Decode(data['salt'] as String),
        );
        final actual = await hash.extractBytes();
        final expected = base64Decode(data['hash'] as String);
        var difference = actual.length ^ expected.length;
        for (var i = 0; i < actual.length && i < expected.length; i++) {
          difference |= actual[i] ^ expected[i];
        }
        valid = difference == 0;
      }
      if (valid) {
        await _storage.delete(key: 'karta.pin.failures');
        await _storage.delete(key: 'karta.pin.lockUntil');
      } else {
        final failures =
            (int.tryParse(
                  await _storage.read(key: 'karta.pin.failures') ?? '',
                ) ??
                0) +
            1;
        await _storage.write(key: 'karta.pin.failures', value: '$failures');
        if (failures >= 5) {
          final seconds = min(900, 30 * (1 << min(5, failures - 5)));
          await _storage.write(
            key: 'karta.pin.lockUntil',
            value: '${DateTime.now().millisecondsSinceEpoch + seconds * 1000}',
          );
        }
      }
      return valid;
    } finally {
      _checking = false;
    }
  }

  Future<bool> biometricEnabled() async =>
      await _storage.read(key: 'karta.biometric.enabled') == 'true';
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: 'karta.biometric.enabled', value: '$enabled');

  Future<Map<String, String>> readProfile() async {
    final raw = await _storage.read(key: 'karta.profile.v1');
    if (raw == null) {
      return {};
    }
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveProfile({
    required String name,
    required String nationality,
  }) {
    if (name.trim().isEmpty ||
        name.trim().length > 120 ||
        nationality.trim().length > 80) {
      throw ArgumentError('Perfil inválido.');
    }
    return _storage.write(
      key: 'karta.profile.v1',
      value: jsonEncode({
        'name': name.trim(),
        'nationality': nationality.trim(),
      }),
    );
  }

  Future<String> walletName() async {
    final profile = await readProfile();
    return profile['name'] ??
        await _storage.read(key: _nameKey) ??
        'A minha KARTA';
  }

  Future<void> deleteWallet() => _storage.deleteAll();
}
