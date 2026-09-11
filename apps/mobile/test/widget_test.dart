import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/credential_store.dart';

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
