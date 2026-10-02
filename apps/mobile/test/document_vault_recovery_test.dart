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
      // Do not use pumpAndSettle here: CircularProgressIndicator is intentionally
      // present while the async secure-storage read is in flight, so a global
      // settle can wait on an indeterminate animation. Pump a bounded number
      // of frames and then assert the recovery state explicitly.
      for (var i = 0;
          i < 40 &&
              find.text('O cofre precisa de recuperação').evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

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
