class Validators {
  /// Validates standard 10-digit Indian phone numbers
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Strip common formatting
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If it starts with +91, remove it to check the core 10 digits
    String coreDigits = cleanPhone;
    if (cleanPhone.startsWith('+91')) {
      coreDigits = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
      coreDigits = cleanPhone.substring(2);
    }

    // Final check: Must be exactly 10 digits now
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(coreDigits)) {
      return 'Enter a valid 10-digit number';
    }
    return null;
  }

  /// Validates standard email addresses
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Hardened Instagram Handle Validation
  static String? validateInstagramHandle(String? value) {
    if (value == null || value.trim().isEmpty) return 'Handle is required';

    final clean = value.replaceAll('@', '').trim();

    if (clean.length > 30) return 'Max 30 characters';

    // Hardened Regex:
    // No consecutive dots, no starting/ending with dots
    final igRegex = RegExp(r'^(?!.*\.\.)(?!^\.)(?!.*\.$)[a-zA-Z0-9._]+$');

    if (!igRegex.hasMatch(clean)) {
      return 'Invalid handle format';
    }
    return null;
  }

  /// Validates standard UPI IDs
  static String? validateUpi(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional field

    final upiRegex = RegExp(r'^[\w.-]+@[\w.-]+$');
    if (!upiRegex.hasMatch(value.trim())) {
      return 'Enter a valid UPI ID (e.g. name@bank)';
    }
    return null;
  }

  /// Generic required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// central wrapper to make any standard formatted validator cleanly optional
  static String? Function(String?) optional(
    String? Function(String?) baseValidator,
  ) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return baseValidator(value);
    };
  }
}
