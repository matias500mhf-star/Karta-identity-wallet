import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/document_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corrupted document index cannot be overwritten by a new document', () async {
    final root = await Directory.systemTemp.createTemp('karta-corrupt-index-test');
    addTearDown(() => root.delete(recursive: true));

    FlutterSecureStorage.setMockInitialValues({
      'karta.document_vault.index.v1': '{broken-json',
    });

    final store = DocumentStore(directory: root);
    expect(await store.list(), isEmpty);

    await expectLater(
      store.add(
        type: 'Passaporte',
        title: 'Novo passaporte',
        frontBytes: Uint8List.fromList([1, 2, 3]),
      ),
      throwsA(isA<StateError>()),
    );

    const secure = FlutterSecureStorage();
    expect(
      await secure.read(key: 'karta.document_vault.index.v1'),
      '{broken-json',
    );
    expect(await Directory('${root.path}/karta_vault').exists(), isFalse);
  });
}
