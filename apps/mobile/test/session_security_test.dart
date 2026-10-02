import 'package:flutter_test/flutter_test.dart';
import 'package:karta_wallet/services/session_store.dart';

void main() {
  test('constant-time legacy PIN comparison accepts only exact matches', () {
    expect(constantTimeStringEquals('123456', '123456'), isTrue);
    expect(constantTimeStringEquals('123456', '123457'), isFalse);
    expect(constantTimeStringEquals('12345', '123456'), isFalse);
  });
}
