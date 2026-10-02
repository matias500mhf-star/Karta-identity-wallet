import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/document_vault_page.dart';
import 'package:karta_wallet/services/document_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'corrupted vault index surfaces recovery state and disables adding documents',
    (tester) async {
      final root = await Directory.systemTemp.createTemp(
        'karta-vault-recovery-ui-test',
      );
      addTearDown(() => root.delete(recursive: true));

      FlutterSecureStorage.setMockInitialValues({
        'karta.document_vault.index.v1': '{broken-json',
      });

      final store = DocumentStore(directory: root);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentVaultPage(store: store)),
        ),
      );
      await tester.pumpAndSettle();

      expect(store.hasIndexCorruption, isTrue);
      expect(find.text('O cofre precisa de recuperação'), findsOneWidget);
      expect(find.textContaining('backup cifrado válido'), findsOneWidget);
      expect(find.text('O seu cofre está pronto'), findsNothing);

      final addButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Adicionar documento'),
      );
      expect(addButton.onPressed, isNull);
    },
  );
}
