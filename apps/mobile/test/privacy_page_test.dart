import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/privacy_page.dart';

void main() {
  testWidgets('privacy page exposes the required KARTA disclosures', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyPage()),
    );

    expect(find.text('Política de Privacidade da KARTA'), findsOneWidget);
    expect(find.textContaining('HMATIAS – Prestação de Serviços SU, LDA'), findsWidgets);
    expect(find.text('1. Dados guardados localmente'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('5. Conta e backup online opcional'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('5. Conta e backup online opcional'), findsOneWidget);
    expect(find.textContaining('backup cifrado'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('9. Contacto'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('geral@comercialhmatiasps.com'), findsOneWidget);
    expect(
      find.textContaining('comercialhmatiasps.com/karta-privacidade.html'),
      findsOneWidget,
    );
  });
}
