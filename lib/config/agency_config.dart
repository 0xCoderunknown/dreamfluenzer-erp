/// Agency configuration — the only file human operators need to edit.
///
/// These are generic FOSS-safe defaults. When the app boots, [AppConfig.load]
/// overrides these fields dynamically from:
///   - `assets/config/config.json`  (private, gitignored — your real credentials)
///   - `assets/config/config.demo.json` (public demo fallback for new contributors)
///
/// New contributor? Copy `assets/config/config.demo.json` to `assets/config/config.json`
/// and fill in your own agency details. Never commit config.json.
class AgencyConfig {
  // ─── BRAND & PORTAL IDENTITY ───
  static String agencyName = 'MY AGENCY';
  static String portalTitle = 'Agency ERP';
  static String legalEntity = 'My Agency Pvt Ltd';
  static String location = 'City, State, Country';
  static const String defaultCity = 'City';
  static String websiteUrl = 'myagency.com';

  // ─── ADMIN PROFILE & GREETINGS ───
  static String adminDisplayName = 'Agency Admin';
  static String adminGreetingName = 'Admin';

  // ─── AUTHENTICATION GATE ───
  // Set to true to require a login screen, or false to completely bypass login.
  static bool loginRequired = false;

  // ─── BILLING & COMPLIANCE ───
  static String bankName = 'Commercial Bank';
  static String accountNumber = '000000000000';
  static String ifscCode = 'DEMO0000000';
  static String upiId = 'agency@demo';
  static String gstNumber = '18XXXXX0000X1Z5';

  /// Initializes agency configuration from loaded configuration dictionary.
  static void initFromMap(Map<String, dynamic>? data) {
    if (data == null) return;
    agencyName = data['agencyName'] as String? ?? agencyName;
    portalTitle = data['portalTitle'] as String? ?? portalTitle;
    legalEntity = data['legalEntity'] as String? ?? legalEntity;
    location = data['location'] as String? ?? location;
    websiteUrl = data['websiteUrl'] as String? ?? websiteUrl;
    adminDisplayName = data['adminDisplayName'] as String? ?? adminDisplayName;
    adminGreetingName =
        data['adminGreetingName'] as String? ?? adminGreetingName;
    if (data['loginRequired'] != null) {
      loginRequired = data['loginRequired'] as bool;
    }
    bankName = data['bankName'] as String? ?? bankName;
    accountNumber = data['accountNumber'] as String? ?? accountNumber;
    ifscCode = data['ifscCode'] as String? ?? ifscCode;
    upiId = data['upiId'] as String? ?? upiId;
    gstNumber = data['gstNumber'] as String? ?? gstNumber;
  }
}
