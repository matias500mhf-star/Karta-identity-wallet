import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/main.dart';
import 'package:karta_wallet/brand_theme.dart';

void main() {
  testWidgets('KARTA brand renders on a narrow phone', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KartaApp());
    await tester.pumpAndSettle();

    expect(find.byType(KartaMark), findsOneWidget);
    expect(find.text('KARTA'), findsOneWidget);
    expect(find.text('IDENTITY WALLET'), findsOneWidget);
    expect(find.text('Um produto HMATIAS'), findsOneWidget);
    expect(
      find.text('Os teus documentos. A tua identidade. Sob o teu controlo.'),
      findsOneWidget,
    );
    expect(
      Theme.of(tester.element(find.byType(KartaBrandHeader))).colorScheme.primary,
      HmatiasBrand.blue,
    );
    expect(tester.takeException(), isNull);
  });
}
