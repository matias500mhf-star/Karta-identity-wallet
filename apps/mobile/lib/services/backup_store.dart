import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class BackupCodec {
  static const maxBytes = 48 * 1024 * 1024;
  static final _cipher = AesGcm.with256bits();
  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );
  static Future<Uint8List> encode(
    Map<String, dynamic> data,
    String password,
  ) async {
    if (password.length < 12 || password.length > 256)
      throw const FormatException(
        'Use uma palavra-passe de 12 a 256 caracteres.',
      );
    final plain = utf8.encode(jsonEncode(data));
    if (plain.length > maxBytes / 2)
      throw const FormatException(
        'A carteira excede o limite desta versão de backup.',
      );
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final box = await _cipher.encrypt(plain, secretKey: key);
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'karta-backup',
          'version': 1,
          'salt': base64Encode(salt),
          'nonce': base64Encode(box.nonce),
          'mac': base64Encode(box.mac.bytes),
          'ciphertext': base64Encode(box.cipherText),
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> decode(
    Uint8List bytes,
    String password,
  ) async {
    if (bytes.length > maxBytes || password.length > 256)
      throw const FormatException('Backup demasiado grande.');
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map ||
        data['format'] != 'karta-backup' ||
        data['version'] != 1)
      throw const FormatException('Backup incompatível.');
    final salt = base64Decode(data['salt'] as String);
    final nonce = base64Decode(data['nonce'] as String);
    final mac = base64Decode(data['mac'] as String);
    if (salt.length != 16 || nonce.length != 12 || mac.length != 16)
      throw const FormatException('Backup inválido.');
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final plain = await _cipher.decrypt(
      SecretBox(
        base64Decode(data['ciphertext'] as String),
        nonce: nonce,
        mac: Mac(mac),
      ),
      secretKey: key,
    );
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(plain)) as Map);
  }
}

class BackupStore {
  BackupStore({this.directory});
  final Directory? directory;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  static const keys = {
    'karta.wallet_created',
    'karta.wallet_name',
    'karta.pin',
    'karta.pin.v2',
    'karta.profile.v1',
    'karta.local_credentials.v1',
    'karta.document_vault.index.v1',
    'karta.document_vault.key.v1',
  };
  Future<Directory> _root() async =>
      directory ?? await getApplicationSupportDirectory();
  static bool safeName(String name) =>
      RegExp(r'^[a-zA-Z0-9_-]+\.karta$').hasMatch(name);

  Future<Uint8List> export(String password) async {
    final all = await storage.readAll();
    if (all['karta.wallet_created'] != 'true')
      throw StateError('Carteira indisponível.');
    final values = {
      for (final key in keys)
        if (all[key] != null) key: all[key]!,
    };
    final index =
        jsonDecode(values['karta.document_vault.index.v1'] ?? '[]') as List;
    final files = <String, String>{};
    var total = 0;
    final root = await _root();
    for (final item in index) {
      for (final field in ['frontFile', 'backFile', 'attachmentFile']) {
        final name = item[field] as String?;
        if (name == null || files.containsKey(name)) continue;
        if (!safeName(name))
          throw const FormatException('Nome de ficheiro inválido.');
        final file = File('${root.path}/karta_vault/$name');
        total += await file.length();
        if (total > 16 * 1024 * 1024)
          throw const FormatException(
            'Nesta versão, o backup suporta até 16 MB de ficheiros cifrados.',
          );
        files[name] = base64Encode(await file.readAsBytes());
      }
    }
    return BackupCodec.encode({'values': values, 'files': files}, password);
  }

  // Complete or roll back an interrupted restore before opening the wallet gate.
  Future<void> recoverInterruptedRestore() async {
    if (await storage.read(key: 'karta.restore.pending') != 'true') return;
    final root = await _root();
    if (await storage.read(key: 'karta.wallet_created') != 'true') {
      for (final key in keys) {
        await storage.delete(key: key);
      }
      final vault = Directory('${root.path}/karta_vault');
      if (await vault.exists()) await vault.delete(recursive: true);
    }
    final stage = Directory('${root.path}/karta_vault_restore');
    if (await stage.exists()) await stage.delete(recursive: true);
    await storage.delete(key: 'karta.restore.pending');
  }

  Future<void> restore(Uint8List bytes, String password) async {
    // Restore is only offered on a fresh installation; never replace a wallet.
    final existing = await storage.readAll();
    if (existing.keys.any((key) => key.startsWith('karta.')))
      throw StateError('Já existem dados neste dispositivo.');
    final data = await BackupCodec.decode(bytes, password);
    final values = Map<String, String>.from(data['values'] as Map);
    final files = Map<String, String>.from(data['files'] as Map);
    if (values.keys.any((key) => !keys.contains(key)) ||
        values['karta.wallet_created'] != 'true' ||
        (!values.containsKey('karta.pin.v2') &&
            !RegExp(r'^\d{6}$').hasMatch(values['karta.pin'] ?? '')) ||
        files.length > 1000 ||
        files.keys.any((name) => !safeName(name)))
      throw const FormatException('Backup inválido.');
    final index =
        jsonDecode(values['karta.document_vault.index.v1'] ?? '[]') as List;
    final requiredFiles = <String>{};
    for (final item in index) {
      for (final field in ['frontFile', 'backFile', 'attachmentFile']) {
        final name = item[field] as String?;
        if (name != null) requiredFiles.add(name);
      }
    }
    if (requiredFiles.length != files.length ||
        requiredFiles.any((name) => !files.containsKey(name)))
      throw const FormatException('Backup incompleto.');
    // Authenticate all document ciphertext before making any local change.
    final packedFiles = <String, Uint8List>{};
    for (final entry in files.entries) {
      final packed = base64Decode(entry.value);
      final box = jsonDecode(utf8.decode(packed)) as Map;
      await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Decode(box['cipherText'] as String),
          nonce: base64Decode(box['nonce'] as String),
          mac: Mac(base64Decode(box['mac'] as String)),
        ),
        secretKey: SecretKey(
          base64Decode(values['karta.document_vault.key.v1']!),
        ),
      );
      packedFiles[entry.key] = packed;
    }
    final root = await _root();
    final vault = Directory('${root.path}/karta_vault');
    if (await vault.exists())
      throw StateError('Já existem ficheiros neste dispositivo.');
    final stage = Directory('${root.path}/karta_vault_restore');
    await storage.write(key: 'karta.restore.pending', value: 'true');
    try {
      await stage.create(recursive: true);
      for (final entry in packedFiles.entries) {
        await File('${stage.path}/${entry.key}')
            .writeAsBytes(entry.value, flush: true);
      }
      await stage.rename(vault.path);
      for (final entry in values.entries.where(
        (entry) => entry.key != 'karta.wallet_created',
      )) {
        await storage.write(key: entry.key, value: entry.value);
      }
      await storage.write(key: 'karta.wallet_created', value: 'true');
    } catch (_) {
      await recoverInterruptedRestore();
      rethrow;
    }
    await storage.delete(key: 'karta.restore.pending');
  }
}
