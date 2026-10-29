import 'package:dreamfluenzer_erp/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators — Indian Phone Validation', () {
    test('Rejects null and empty phone', () {
      expect(Validators.validatePhone(null), 'Phone number is required');
      expect(Validators.validatePhone('   '), 'Phone number is required');
    });

    test('Validates 10-digit number', () {
      expect(Validators.validatePhone('9876543210'), isNull);
    });

    test('Handles +91 prefix and dashes', () {
      expect(Validators.validatePhone('+91 98765-43210'), isNull);
      expect(Validators.validatePhone('919876543210'), isNull);
    });

    test('Rejects invalid digit lengths', () {
      expect(
        Validators.validatePhone('98765'),
        'Enter a valid 10-digit number',
      );
      expect(
        Validators.validatePhone('1234567890123'),
        'Enter a valid 10-digit number',
      );
    });
  });

  group('Validators — Email Validation', () {
    test('Rejects empty email', () {
      expect(Validators.validateEmail(''), 'Email is required');
    });

    test('Accepts valid email formats', () {
      expect(Validators.validateEmail('operator@dreamfluenzer.com'), isNull);
      expect(Validators.validateEmail('test.lead+ops@agency.co.in'), isNull);
    });

    test('Rejects malformed emails', () {
      expect(
        Validators.validateEmail('notanemail'),
        'Enter a valid email address',
      );
      expect(Validators.validateEmail('user@'), 'Enter a valid email address');
      expect(
        Validators.validateEmail('@domain.com'),
        'Enter a valid email address',
      );
    });
  });

  group('Validators — Instagram Handle Validation', () {
    test('Rejects empty handle', () {
      expect(Validators.validateInstagramHandle(''), 'Handle is required');
    });

    test('Accepts valid handles with or without @', () {
      expect(Validators.validateInstagramHandle('@fashion_guru'), isNull);
      expect(Validators.validateInstagramHandle('tech.reviewer'), isNull);
    });

    test('Rejects handles starting/ending with dot or consecutive dots', () {
      expect(
        Validators.validateInstagramHandle('.invalid'),
        'Invalid handle format',
      );
      expect(
        Validators.validateInstagramHandle('invalid.'),
        'Invalid handle format',
      );
      expect(
        Validators.validateInstagramHandle('in..valid'),
        'Invalid handle format',
      );
    });
  });

  group('Validators — UPI ID Validation (Optional field)', () {
    test('Allows null and empty UPI (optional by default)', () {
      expect(Validators.validateUpi(null), isNull);
      expect(Validators.validateUpi(''), isNull);
    });

    test('Accepts standard UPI formats', () {
      expect(Validators.validateUpi('creator@oksbi'), isNull);
      expect(Validators.validateUpi('agency.finance@icici'), isNull);
    });

    test('Rejects malformed UPI handles', () {
      expect(
        Validators.validateUpi('invalidupi'),
        'Enter a valid UPI ID (e.g. name@bank)',
      );
    });
  });

  group('Validators — Required Field and Optional Wrapper', () {
    test('validateRequired works correctly', () {
      expect(
        Validators.validateRequired('', 'Client Name'),
        'Client Name is required',
      );
      expect(Validators.validateRequired('Acme Corp', 'Client Name'), isNull);
    });

    test('optional wrapper allows empty input', () {
      final optionalEmail = Validators.optional(Validators.validateEmail);
      expect(optionalEmail(''), isNull);
      expect(optionalEmail('valid@example.com'), isNull);
      expect(optionalEmail('notanemail'), 'Enter a valid email address');
    });
  });
}
