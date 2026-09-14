import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:karta_wallet/qr_page.dart';
import 'package:karta_wallet/services/qr_payload.dart';

void main() {
  test('QR round trip preserves selected Unicode data only', () {
    final raw = KartaQr.encode({'name': 'Pessoa de teste — Aimée'});
    expect(KartaQr.decode(raw), {'name': 'Pessoa de teste — Aimée'});
    expect(raw.contains('nationality'), isFalse);
  });

  test('rejects links, unsupported assertions, versions and oversized data', () {
    for (final raw in [
      'https://example.com',
      jsonEncode({'format': 'karta-share', 'version': 2, 'data': {'name': 'Teste'}}),
      jsonEncode({'format': 'karta-share', 'version': 1, 'data': {'verified': 'true'}}),
      jsonEncode({'format': 'karta-share', 'version': 1, 'data': {'sha256': 'fake'}}),
      'x' * 1801,
    ]) {
      expect(() => KartaQr.decode(raw), throwsFormatException);
    }
    expect(() => KartaQr.encode({}), throwsFormatException);
  });

  test('file comparison uses SHA-256 of original bytes', () async {
    expect(await KartaQr.fingerprint(utf8.encode('abc')),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    expect(await KartaQr.fingerprint([1]), isNot(await KartaQr.fingerprint([2])));
  });

  testWidgets('sharing starts with no fields and changing selection removes QR', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QrSharePage(fields: {
      'name': 'Pessoa teste', 'nationality': 'Angolana',
    })));
    expect(find.byType(QrImageView), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gerar QR')).onPressed, isNull);
    await tester.tap(find.text('Nome'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerar QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.tap(find.text('Nacionalidade'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
  });
}
