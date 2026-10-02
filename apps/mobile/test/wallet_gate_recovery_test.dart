import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/main.dart';
import 'package:karta_wallet/services/backup_store.dart';
import 'package:karta_wallet/services/session_store.dart';

class _FailingBackupStore extends BackupStore {
  @override
  Future<void> recoverInterruptedRestore() async {
    throw StateError('simulated restore recovery failure');
  }
}

class _FreshSessionStore extends SessionStore {
  @override
  Future<bool> walletCreated() async => false;
}

void main() {
  testWidgets(
    'wallet gate surfaces startup recovery failure instead of spinning forever',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WalletGate(
            sessionStore: _FreshSessionStore(),
            backupStore: _FailingBackupStore(),
          ),
        ),
      );

      for (var i = 0;
          i < 20 &&
              find.text('A KARTA precisa de atenção').evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('A KARTA precisa de atenção'), findsOneWidget);
      expect(
        find.textContaining('Nenhum dado foi alterado'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
