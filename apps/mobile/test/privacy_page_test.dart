import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/privacy_page.dart';

void main() {
  testWidgets('privacy page exposes local, online and deletion disclosures', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: KartaPrivacyPage()),
    );

    expect(find.text('Privacidade e controlo dos seus dados'), findsOneWidget);
    expect(find.text('Dados no dispositivo'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Política pública e eliminação fora da app'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.textContaining('comercialhmatiasps.com/karta-privacidade.html'),
      findsOneWidget,
    );
    expect(
      find.textContaining('comercialhmatiasps.com/karta-eliminar-conta.html'),
      findsOneWidget,
    );
  });
}
