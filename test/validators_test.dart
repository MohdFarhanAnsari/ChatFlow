import 'package:chatflow/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateEmail validates correctly', () {
      expect(Validators.validateEmail(''), 'Email address is required');
      expect(Validators.validateEmail(null), 'Email address is required');
      expect(Validators.validateEmail('invalid'), 'Please enter a valid email address');
      expect(Validators.validateEmail('user@'), 'Please enter a valid email address');
      expect(Validators.validateEmail('user@domain'), 'Please enter a valid email address');
      expect(Validators.validateEmail('valid.user@company.co'), isNull);
      expect(Validators.validateEmail('test@gmail.com'), isNull);
    });

    test('validatePassword validates length and presence', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters');
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('SecurePassword!123'), isNull);
    });

    test('validateConfirmPassword ensures matching passwords', () {
      expect(Validators.validateConfirmPassword('', 'secret123'), 'Please confirm your password');
      expect(Validators.validateConfirmPassword('mismatch', 'secret123'), 'Passwords do not match');
      expect(Validators.validateConfirmPassword('secret123', 'secret123'), isNull);
    });

    test('validateDisplayName checks for minimum length', () {
      expect(Validators.validateDisplayName(''), 'Full name is required');
      expect(Validators.validateDisplayName('A'), 'Name must be at least 2 characters');
      expect(Validators.validateDisplayName('Devon'), isNull);
      expect(Validators.validateDisplayName('Sarah Chen'), isNull);
    });
  });
}
