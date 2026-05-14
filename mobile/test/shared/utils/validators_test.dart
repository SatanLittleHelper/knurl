import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/utils/validators.dart';

void main() {
  group('validators', () {
    test('validateEmail returns null for a valid email', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('validateEmail returns null for a trimmed valid email', () {
      expect(validateEmail('  user@example.com  '), isNull);
    });

    test('validateEmail returns an error for empty string', () {
      expect(validateEmail(''), 'Введите email');
    });

    test('validateEmail returns an error for null', () {
      expect(validateEmail(null), 'Введите email');
    });

    test('validateEmail returns an error for missing @', () {
      expect(validateEmail('notanemail'), 'Введите корректный email');
    });

    test('validateEmail returns an error for whitespace-only input', () {
      expect(validateEmail('   '), 'Введите email');
    });

    test('validatePassword returns null for a non-empty password', () {
      expect(validatePassword('secret'), isNull);
    });

    test('validatePassword returns null for whitespace-only input', () {
      expect(validatePassword('   '), isNull);
    });

    test('validatePassword returns an error for empty string', () {
      expect(validatePassword(''), 'Введите пароль');
    });

    test('validatePassword returns an error for null', () {
      expect(validatePassword(null), 'Введите пароль');
    });
  });
}
