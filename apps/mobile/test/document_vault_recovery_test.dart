import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/document_vault_page.dart';
import 'package:karta_wallet/services/document_store.dart';

class _CorruptDocumentStore extends DocumentStore {
  @override
  Future<List<VaultDocument>> list() async => const [];

  @override
  bool get hasIndexCorruption => true;
}

void main() {
  testWidgets(
    'corrupted vault index surfaces recovery state and disables adding documents',
    (tester) async {
      final store = _CorruptDocumentStore();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentVaultPage(store: store)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

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
