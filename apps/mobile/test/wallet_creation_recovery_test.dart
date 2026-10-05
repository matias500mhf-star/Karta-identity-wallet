import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();

  test('interrupted wallet creation clears incomplete identity state', () async {
    FlutterSecureStorage.setMockInitialValues({
      'karta.wallet_create.pending': 'true',
      'karta.wallet_name': 'Incomplete wallet',
      'karta.pin.v2': '{"salt":"stale","hash":"stale"}',
      'karta.pin': '123456',
    });

    expect(await SessionStore().walletCreated(), isFalse);
    expect(await storage.read(key: 'karta.wallet_create.pending'), isNull);
    expect(await storage.read(key: 'karta.wallet_name'), isNull);
    expect(await storage.read(key: 'karta.pin.v2'), isNull);
    expect(await storage.read(key: 'karta.pin'), isNull);
  });

  test('completed wallet survives a stale creation marker', () async {
    FlutterSecureStorage.setMockInitialValues({
      'karta.wallet_create.pending': 'true',
      'karta.wallet_created': 'true',
      'karta.wallet_name': 'A minha KARTA',
      'karta.pin.v2': '{"salt":"kept","hash":"kept"}',
    });

    expect(await SessionStore().walletCreated(), isTrue);
    expect(await storage.read(key: 'karta.wallet_create.pending'), isNull);
    expect(await storage.read(key: 'karta.wallet_name'), 'A minha KARTA');
    expect(await storage.read(key: 'karta.pin.v2'), isNotNull);
  });
}
