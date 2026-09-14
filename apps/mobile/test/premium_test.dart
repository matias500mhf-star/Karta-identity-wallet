import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/brand_theme.dart';
import 'package:karta_wallet/premium_widgets.dart';
import 'package:karta_wallet/document_vault_page.dart';
import 'package:karta_wallet/services/document_store.dart';

class FakeDocuments extends DocumentStore {
  @override
  Future<List<VaultDocument>> list() async => [
    VaultDocument(id: '1', type: 'Passaporte', title: 'Viagem familiar', createdAt: DateTime(2026)),
    VaultDocument(id: '2', type: 'Certidão', title: 'Registo pessoal', createdAt: DateTime(2026)),
  ];
}

void main() {
  testWidgets('premium card and actions fit a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = false;
    await tester.pumpWidget(MaterialApp(theme: HmatiasBrand.theme, home: MediaQuery(
      data: const MediaQueryData(size: Size(320, 740), textScaler: TextScaler.linear(1.6)),
      child: Scaffold(body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const WalletHero(name: 'Uma carteira com um nome bastante comprido', credentialCount: 12),
          KartaActionPair(
            first: KartaAction(icon: Icons.folder, title: 'Documentos', subtitle: 'Consultar as suas cópias', onTap: () => tapped = true),
            second: KartaAction(icon: Icons.qr_code, title: 'Partilhar por QR', subtitle: 'Escolha os seus dados', onTap: () {}),
          ),
        ]),
      ))),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Documentos'));
    await tester.tap(find.text('Documentos'));
    expect(tapped, isTrue);
  });

  testWidgets('document search combines text and type filters and recovers from no results', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: HmatiasBrand.theme,
      home: Scaffold(body: DocumentVaultPage(store: FakeDocuments()))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'VIAGEM');
    await tester.pumpAndSettle();
    expect(find.text('1 de 2 documentos'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Certidão'));
    await tester.pumpAndSettle();
    expect(find.text('Sem resultados'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('1 de 2 documentos'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    expect(find.text('2 de 2 documentos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
