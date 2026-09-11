import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/profile_page.dart';
import 'package:karta_wallet/services/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('profile survives store recreation and wallet deletion clears it', () async {
    await SessionStore().createWallet(pin: '123456');
    await SessionStore().saveProfile(name: ' Pessoa de teste ', nationality: 'Angolana');
    expect(await SessionStore().walletName(), 'Pessoa de teste');
    expect((await SessionStore().readProfile())['nationality'], 'Angolana');
    expect(await SessionStore().verifyPin('123456'), isTrue);
    await SessionStore().deleteWallet();
    expect(await SessionStore().readProfile(), isEmpty);
  });

  testWidgets('blank name is rejected without writing profile', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ProfilePage(store: SessionStore())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar perfil'));
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Indique o nome.'), findsOneWidget);
    expect(await SessionStore().readProfile(), isEmpty);
  });
}
