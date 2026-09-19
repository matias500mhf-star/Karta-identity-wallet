import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/document_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pendingKey = 'karta.document_vault.pending_delete.v1';
  const indexKey = 'karta.document_vault.index.v1';

  VaultDocument document() => VaultDocument(
        id: 'doc-1',
        type: 'Passaporte',
        title: 'Passaporte',
        createdAt: DateTime.utc(2026, 9, 19),
        frontFile: 'doc-1-front.karta',
        attachmentFile: 'doc-1-attachment.karta',
      );

  test('remove commits the index and deletes the encrypted files', () async {
    final root = await Directory.systemTemp.createTemp('karta-delete-test');
    addTearDown(() => root.delete(recursive: true));
    final vault = await Directory('${root.path}/karta_vault').create();
    final item = document();
    final front = File('${vault.path}/${item.frontFile!}');
    final attachment = File('${vault.path}/${item.attachmentFile!}');
    await front.writeAsString('encrypted-front');
    await attachment.writeAsString('encrypted-attachment');
    FlutterSecureStorage.setMockInitialValues({
      indexKey: jsonEncode([item.toJson()]),
    });

    final store = DocumentStore(directory: root);
    await store.remove(item);

    expect(await store.list(), isEmpty);
    expect(await front.exists(), isFalse);
    expect(await attachment.exists(), isFalse);
    expect(
      await const FlutterSecureStorage().read(key: pendingKey),
      isNull,
    );
  });

  test('recovery completes file deletion after an index commit', () async {
    final root = await Directory.systemTemp.createTemp('karta-delete-recover');
    addTearDown(() => root.delete(recursive: true));
    final vault = await Directory('${root.path}/karta_vault').create();
    final file = File('${vault.path}/doc-1-front.karta');
    await file.writeAsString('encrypted-front');
    FlutterSecureStorage.setMockInitialValues({
      indexKey: '[]',
      pendingKey: jsonEncode({
        'id': 'doc-1',
        'files': ['doc-1-front.karta'],
      }),
    });

    final store = DocumentStore(directory: root);
    expect(await store.list(), isEmpty);
    expect(await file.exists(), isFalse);
    expect(
      await const FlutterSecureStorage().read(key: pendingKey),
      isNull,
    );
  });

  test('recovery cancels a deletion that never committed to the index', () async {
    final root = await Directory.systemTemp.createTemp('karta-delete-cancel');
    addTearDown(() => root.delete(recursive: true));
    final vault = await Directory('${root.path}/karta_vault').create();
    final item = document();
    final file = File('${vault.path}/${item.frontFile!}');
    await file.writeAsString('encrypted-front');
    FlutterSecureStorage.setMockInitialValues({
      indexKey: jsonEncode([item.toJson()]),
      pendingKey: jsonEncode({
        'id': item.id,
        'files': [item.frontFile],
      }),
    });

    final store = DocumentStore(directory: root);
    final items = await store.list();

    expect(items.map((entry) => entry.id), contains(item.id));
    expect(await file.exists(), isTrue);
    expect(
      await const FlutterSecureStorage().read(key: pendingKey),
      isNull,
    );
  });
}
