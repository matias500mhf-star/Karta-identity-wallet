import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/main.dart';
import 'package:karta_wallet/services/session_store.dart';

class _FailingCreateSessionStore extends SessionStore {
  @override
  Future<void> createWallet({
    required String pin,
    String name = 'A minha KARTA',
  }) async {
    throw StateError('simulated secure-storage failure');
  }
}

void main() {
  testWidgets(
    'wallet creation failure is recoverable and never confirms the PIN',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreatePinPage(store: _FailingCreateSessionStore()),
        ),
      );

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));

      await tester.enterText(fields.at(0), '123456');
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.text('Criar carteira'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.textContaining('Não foi possível criar a carteira com segurança'),
        findsOneWidget,
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Criar carteira'),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'onboarding remains explicitly Alpha while using production-grade local wording',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: WelcomePage(store: SessionStore())),
      );

      expect(find.text('KARTA Alpha 0.9 · HMATIAS'), findsOneWidget);
      expect(
        find.text('Credenciais locais sob o seu controlo'),
        findsOneWidget,
      );
      expect(find.textContaining('credenciais de teste'), findsNothing);
      expect(
        find.text('Compreendo como a KARTA funciona nesta versão.'),
        findsOneWidget,
      );
    },
  );
}
