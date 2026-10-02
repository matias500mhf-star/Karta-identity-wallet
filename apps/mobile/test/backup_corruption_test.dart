import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/backup_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('backup export refuses a corrupted credential index', () async {
    final root = await Directory.systemTemp.createTemp(
      'karta-corrupt-credential-backup-test',
    );
    addTearDown(() => root.delete(recursive: true));

    FlutterSecureStorage.setMockInitialValues({
      'karta.wallet_created': 'true',
      'karta.local_credentials.v1': '{broken-json',
      'karta.document_vault.index.v1': '[]',
    });

    await expectLater(
      BackupStore(directory: root).export('correct-horse-battery-staple'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('credenciais locais precisam de recuperação'),
        ),
      ),
    );
  });
}
