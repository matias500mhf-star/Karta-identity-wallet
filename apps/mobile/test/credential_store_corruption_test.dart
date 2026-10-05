import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/credential_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();

  test('corrupted credential index cannot be treated as an empty list', () async {
    FlutterSecureStorage.setMockInitialValues({
      'karta.local_credentials.v1': '{broken-json',
    });

    final store = CredentialStore();
    await expectLater(store.list(), throwsStateError);

    await expectLater(
      store.add(
        type: 'Passaporte',
        issuer: 'Entidade',
        reference: 'ABC123',
      ),
      throwsStateError,
    );

    expect(
      await storage.read(key: 'karta.local_credentials.v1'),
      '{broken-json',
    );
  });
}
