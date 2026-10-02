import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/security_page.dart';
import 'package:karta_wallet/services/biometric_service.dart';
import 'package:karta_wallet/services/session_store.dart';

class _SecurityStore extends SessionStore {
  @override
  Future<bool> biometricEnabled() async => false;
}

class _FlakyBiometric extends BiometricService {
  var calls = 0;

  @override
  Future<bool> available() async {
    calls += 1;
    if (calls == 1) {
      throw StateError('simulated platform failure');
    }
    return false;
  }
}

void main() {
  testWidgets(
    'security page surfaces load failure and recovers on retry',
    (tester) async {
      final biometric = _FlakyBiometric();

      await tester.pumpWidget(
        MaterialApp(
          home: SecurityPage(
            store: _SecurityStore(),
            biometricService: biometric,
          ),
        ),
      );

      for (var i = 0;
          i < 20 &&
              find.text('Não foi possível verificar a segurança').evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.text('Não foi possível verificar a segurança'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Nenhuma configuração foi alterada'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tentar novamente'));
      for (var i = 0;
          i < 20 &&
              find.text('Biometria desativada').evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Não foi possível verificar a segurança'), findsNothing);
      expect(find.text('Biometria desativada'), findsOneWidget);
      expect(biometric.calls, 2);
    },
  );
}
