import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/backup_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'backup authenticates password and restores only into an empty wallet',
    () async {
      final root = await Directory.systemTemp.createTemp('karta-backup-test');
      addTearDown(() => root.delete(recursive: true));
      final source = await Directory('${root.path}/source').create();
      final target = await Directory('${root.path}/target').create();
      final vault = await Directory('${source.path}/karta_vault').create();
      final key = List<int>.filled(32, 42);
      final box = await AesGcm.with256bits().encrypt(
        utf8.encode('%PDF test document'),
        secretKey: SecretKey(key),
      );
      final packed = utf8.encode(
        jsonEncode({
          'cipherText': base64Encode(box.cipherText),
          'nonce': base64Encode(box.nonce),
          'mac': base64Encode(box.mac.bytes),
        }),
      );
      await File('${vault.path}/123-attachment.karta').writeAsBytes(packed);
      FlutterSecureStorage.setMockInitialValues({
        'karta.document_vault.key.v1': base64Encode(key),
        'karta.document_vault.index.v1': jsonEncode([
          {'id': '123', 'attachmentFile': '123-attachment.karta'},
        ]),
        'karta.wallet_created': 'true',
        'karta.pin': '123456',
        'karta.profile.v1': jsonEncode({'name': 'Pessoa de teste'}),
        'karta.biometric.enabled': 'true',
      });
      final store = BackupStore(directory: source);
      final bytes = await store.export('palavra-passe de teste');
      expect(utf8.decode(bytes).contains('Pessoa de teste'), isFalse);
      await expectLater(
        BackupCodec.decode(bytes, 'palavra errada'),
        throwsA(anything),
      );
      await expectLater(
        store.restore(bytes, 'palavra-passe de teste'),
        throwsStateError,
      );
      FlutterSecureStorage.setMockInitialValues({});
      await BackupStore(directory: target)
          .restore(bytes, 'palavra-passe de teste');
      expect(
        await File('${target.path}/karta_vault/123-attachment.karta')
            .readAsBytes(),
        packed,
      );
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'karta.wallet_created'), 'true');
      expect(
        await storage.read(key: 'karta.profile.v1'),
        contains('Pessoa de teste'),
      );
      expect(await storage.read(key: 'karta.biometric.enabled'), isNull);
      expect(await storage.read(key: 'karta.restore.pending'), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('interrupted restore rolls back staging data without marking a wallet complete', () async {
    final root = await Directory.systemTemp.createTemp('karta-restore-test');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/karta_vault').create();
    FlutterSecureStorage.setMockInitialValues({
      'karta.restore.pending': 'true',
      'karta.pin': '123456',
    });
    await BackupStore(directory: root).recoverInterruptedRestore();
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    expect(await Directory('${root.path}/karta_vault').exists(), isFalse);
  });
}
