import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/session_store.dart';
import 'package:karta_wallet/session_guard.dart';
import 'package:karta_wallet/services/qr_payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  test('legacy PIN migrates only on successful authentication', () async {
    FlutterSecureStorage.setMockInitialValues({
      'karta.pin': '123456',
      'karta.wallet_created': 'true',
    });
    final store = SessionStore();
    expect(await store.verifyPin('654321'), isFalse);
    expect(await storage.read(key: 'karta.pin'), '123456');
    expect(await store.verifyPin('123456'), isTrue);
    expect(await storage.read(key: 'karta.pin'), isNull);
    final record =
        jsonDecode((await storage.read(key: 'karta.pin.v2'))!) as Map;
    expect(base64Decode(record['salt'] as String), hasLength(16));
    expect(await SessionStore().verifyPin('123456'), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('failed PIN attempts persist across store recreation', () async {
    FlutterSecureStorage.setMockInitialValues({'karta.pin': '123456'});
    for (var i = 0; i < 5; i++) {
      expect(await SessionStore().verifyPin('000000'), isFalse);
    }
    await expectLater(SessionStore().verifyPin('123456'), throwsStateError);
    expect(await storage.read(key: 'karta.pin'), '123456');
  });

  test('external QR content is distinct from malformed KARTA data', () {
    expect(QrReadResult.parse('https://example.com').isLink, isTrue);
    expect(
      QrReadResult.parse('BEGIN:VCARD\nFN:Teste\nEND:VCARD').text,
      contains('Teste'),
    );
    expect(QrReadResult.parse('javascript:alert(1)').isLink, isFalse);
    expect(
      QrReadResult.parse('{"format":"karta-share","version":9,"data":{}}')
          .error,
      isNotNull,
    );
    expect(
      QrReadResult.parse(' \uFEFF${KartaQr.encode({'name': 'Aimée'})} ')
          .fields?['name'],
      'Aimée',
    );
    expect(QrReadResult.parse('x' * 9000).error, isNotNull);
  });

  testWidgets(
    'background lock covers an existing route and preserves it after unlock',
    (tester) async {
      SessionSecurity.reset();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => SessionGuard(
            lockPageBuilder: (unlock) => Scaffold(
              body: TextButton(
                onPressed: unlock,
                child: const Text('Unlock test'),
              ),
            ),
            child: child!,
          ),
          home: const Scaffold(body: Text('Private document')),
        ),
      );
      SessionSecurity.unlock();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Unlock test'), findsOneWidget);
      expect(SessionSecurity.locked.value, isTrue);
      await tester.tap(find.text('Unlock test'));
      await tester.pumpAndSettle();
      expect(find.text('Unlock test'), findsNothing);
      expect(find.text('Private document'), findsOneWidget);
      await tester.pump(const Duration(minutes: 5));
      expect(SessionSecurity.locked.value, isTrue);
      await tester.pumpWidget(const SizedBox());
      SessionSecurity.reset();
    },
  );
}
