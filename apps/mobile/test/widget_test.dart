import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/credential_store.dart';
import 'package:karta_wallet/services/session_store.dart';

void main() {
  test('KARTA test environment is healthy', () {
    expect(1 + 1, 2);
  });

  test('local credential round-trips through JSON', () {
    final createdAt = DateTime.utc(2026, 9, 11, 13, 0);
    final credential = LocalCredential(
      id: 'cred-001',
      type: 'Passaporte',
      issuer: 'Entidade de teste',
      reference: 'P1234567',
      createdAt: createdAt,
    );

    final restored = LocalCredential.fromJson(credential.toJson());

    expect(restored.id, credential.id);
    expect(restored.type, credential.type);
    expect(restored.issuer, credential.issuer);
    expect(restored.reference, credential.reference);
    expect(restored.createdAt, createdAt);
  });
}


  test('PIN verifier is deterministic for one salt and changes with another', () async {
    final a = await derivePinVerifier(
      pin: '123456',
      salt: List<int>.filled(16, 7),
    );
    final b = await derivePinVerifier(
      pin: '123456',
      salt: List<int>.filled(16, 7),
    );
    final c = await derivePinVerifier(
      pin: '123456',
      salt: List<int>.filled(16, 8),
    );

    expect(a, b);
    expect(a == c, false);
    expect(a.contains('123456'), false);
  });

  test('constant-time PIN verifier comparison rejects different values', () {
    expect(constantTimeStringEquals('abc123', 'abc123'), true);
    expect(constantTimeStringEquals('abc123', 'abc124'), false);
    expect(constantTimeStringEquals('short', 'longer'), false);
  });
