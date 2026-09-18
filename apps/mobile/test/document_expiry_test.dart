import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/document_store.dart';

void main() {
  group('VaultDocument expiry metadata', () {
    test('old document JSON remains compatible without expiry fields', () {
      final document = VaultDocument.fromJson({
        'id': 'legacy-1',
        'type': 'Passaporte',
        'title': 'Meu passaporte',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(document.issuedAt, isNull);
      expect(document.expiresAt, isNull);
      expect(document.expiryState(now: DateTime.utc(2026, 9, 18)),
          DocumentExpiryState.unknown);
    });

    test('issue and expiry dates survive JSON round trip', () {
      final original = VaultDocument(
        id: 'doc-1',
        type: 'Bilhete de Identidade',
        title: 'BI',
        createdAt: DateTime.utc(2026, 9, 18),
        issuedAt: DateTime.utc(2025, 2, 10),
        expiresAt: DateTime.utc(2030, 2, 10),
      );

      final restored = VaultDocument.fromJson(original.toJson());

      expect(restored.issuedAt, DateTime.utc(2025, 2, 10));
      expect(restored.expiresAt, DateTime.utc(2030, 2, 10));
    });

    test('reports expired documents', () {
      final document = VaultDocument(
        id: 'doc-expired',
        type: 'Passaporte',
        title: 'Passaporte',
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 9, 17),
      );

      expect(document.expiryState(now: DateTime.utc(2026, 9, 18)),
          DocumentExpiryState.expired);
      expect(document.daysUntilExpiry(now: DateTime.utc(2026, 9, 18)), -1);
    });

    test('reports documents expiring inside the 90 day attention window', () {
      final document = VaultDocument(
        id: 'doc-soon',
        type: 'Carta de Condução',
        title: 'Carta',
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 11, 1),
      );

      expect(document.expiryState(now: DateTime.utc(2026, 9, 18)),
          DocumentExpiryState.expiringSoon);
      expect(document.daysUntilExpiry(now: DateTime.utc(2026, 9, 18)), 44);
    });

    test('reports documents outside the attention window as valid', () {
      final document = VaultDocument(
        id: 'doc-valid',
        type: 'Passaporte',
        title: 'Passaporte',
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2027, 9, 18),
      );

      expect(document.expiryState(now: DateTime.utc(2026, 9, 18)),
          DocumentExpiryState.valid);
      expect(document.daysUntilExpiry(now: DateTime.utc(2026, 9, 18)), 365);
    });
  });
}
