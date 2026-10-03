import 'package:dreamfluenzer_erp/config/agency_config.dart';
import 'package:dreamfluenzer_erp/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig & Dynamic AgencyConfig Tests', () {
    test('Fallback to defaultDemoOptions when uninitialized', () {
      expect(AppConfig.defaultDemoOptions.projectId, equals('demo-dreamfluenzer'));
      expect(AppConfig.defaultDemoOptions.apiKey, contains('DEMO'));
    });

    test('AgencyConfig initializes properly from config map', () {
      final customMap = {
        'agencyName': 'TEST_AGENCY',
        'portalTitle': 'Test ERP Portal',
        'legalEntity': 'Test Legal Org',
        'bankName': 'HDFC Bank',
        'accountNumber': '1122334455',
        'upiId': 'test@upi',
        'loginRequired': true,
      };

      AgencyConfig.initFromMap(customMap);

      expect(AgencyConfig.agencyName, equals('TEST_AGENCY'));
      expect(AgencyConfig.portalTitle, equals('Test ERP Portal'));
      expect(AgencyConfig.legalEntity, equals('Test Legal Org'));
      expect(AgencyConfig.bankName, equals('HDFC Bank'));
      expect(AgencyConfig.accountNumber, equals('1122334455'));
      expect(AgencyConfig.upiId, equals('test@upi'));
      expect(AgencyConfig.loginRequired, isTrue);
    });

    test('AgencyConfig handles null gracefully without throwing', () {
      expect(() => AgencyConfig.initFromMap(null), returnsNormally);
    });
  });
}
