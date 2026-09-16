import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karta_wallet/services/api_service.dart';
import 'package:karta_wallet/services/qr_payload.dart';
import 'package:karta_wallet/online_page.dart';

void main() {
  test('rejects insecure origins before sending credentials', () async {
    var called = false;
    final api = ApiService(
      baseUrl: 'http://example.invalid/api/v1',
      client: MockClient((r) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      api.login('test@example.invalid', 'secret'),
      throwsA(isA<ApiException>()),
    );
    expect(called, isFalse);
    api.close();
  });
  test('uses versioned endpoints, disables redirects and transports ciphertext only', () async {
    final bytes = Uint8List.fromList(utf8.encode('{"ciphertext":"fixture"}'));
    final digest = await KartaQr.fingerprint(bytes);
    final api = ApiService(
      baseUrl: 'https://example.invalid/api/v1/',
      client: MockClient((r) async {
        expect(r.followRedirects, isFalse);
        if (r.url.path.endsWith('/auth/login'))
          return http.Response('{"accessToken":"test-token"}', 201);
        expect(r.headers['Authorization'], 'Bearer test-token');
        expect(r.url.path, '/api/v1/backups/latest');
        if (r.method == 'PUT') {
          expect(r.bodyBytes, bytes);
          expect(r.headers['Content-Type'], 'application/octet-stream');
          return http.Response(
            jsonEncode({'digest': digest, 'size': bytes.length}),
            200,
          );
        }
        return http.Response.bytes(
          bytes,
          200,
          headers: {'x-content-sha256': digest},
        );
      }),
    );
    await api.login('test@example.invalid', 'account-password');
    await api.upload(bytes);
    expect(await api.download(), bytes);
    api.close();
  });
  test(
    'expires the local session on 401 and rejects changed downloads',
    () async {
      final api = ApiService(
        baseUrl: 'https://example.invalid/api/v1',
        client: MockClient((r) async => http.Response('denied', 401)),
      );
      api.accessToken = 'expired';
      await expectLater(api.metadata(), throwsA(isA<ApiException>()));
      expect(api.accessToken, isNull);
      api.close();
      final changed = ApiService(
        baseUrl: 'https://example.invalid/api/v1',
        client: MockClient(
          (r) async => http.Response(
            'changed',
            200,
            headers: {'x-content-sha256': 'incorrect'},
          ),
        ),
      );
      await expectLater(changed.download(), throwsA(isA<ApiException>()));
      changed.close();
    },
  );
  testWidgets('unconfigured beta clearly keeps online controls unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnlinePage()));
    expect(find.text('Serviço online em preparação'), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
