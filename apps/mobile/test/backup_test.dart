import 'dart:convert';
import 'dart:io';

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
      FlutterSecureStorage.setMockInitialValues({
        'karta.wallet_created': 'true',
        'karta.pin': '123456',
        'karta.profile.v1': jsonEncode({'name': 'Pessoa de teste'}),
        'karta.biometric.enabled': 'true',
      });
      final store = BackupStore(directory: root);
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
      await store.restore(bytes, 'palavra-passe de teste');
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
