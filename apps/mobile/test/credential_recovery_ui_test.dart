import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/main.dart';
import 'package:karta_wallet/services/credential_store.dart';
import 'package:karta_wallet/services/session_store.dart';

class _NamedSessionStore extends SessionStore {
  @override
  Future<String> walletName() async => 'Carteira de teste';
}

class _CorruptCredentialStore extends CredentialStore {
  @override
  Future<List<LocalCredential>> list() async {
    throw StateError('corrupt credential index');
  }
}

void main() {
  testWidgets(
    'wallet surfaces credential recovery state and disables new credentials',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WalletPage(
            store: _NamedSessionStore(),
            credentialStore: _CorruptCredentialStore(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.scrollUntilVisible(
        find.text('As credenciais precisam de recuperação'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('As credenciais precisam de recuperação'),
        findsOneWidget,
      );
      expect(
        find.textContaining('backup anterior válido'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Adicionar credencial local'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final addButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Adicionar credencial local'),
      );
      expect(addButton.onPressed, isNull);
    },
  );
}
