import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'agency_config.dart';

/// Central application configuration service.
///
/// Implements dual-tier configuration:
/// 1. Primary: `assets/config/config.json` (gitignored, contains real local credentials).
/// 2. Fallback: `assets/config/config.demo.json` (committed, contains open-source demo placeholders).
class AppConfig {
  static late FirebaseOptions _firebaseOptions;
  static bool _isDemoMode = false;
  static bool _isLoaded = false;

  static FirebaseOptions get firebaseOptions {
    if (!_isLoaded) {
      return defaultDemoOptions;
    }
    return _firebaseOptions;
  }

  static bool get isDemoMode => _isDemoMode;

  static const FirebaseOptions defaultDemoOptions = FirebaseOptions(
    apiKey: 'AIzaSyDEMO_PLACEHOLDER_KEY_DO_NOT_USE',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-dreamfluenzer',
    authDomain: 'demo-dreamfluenzer.firebaseapp.com',
    storageBucket: 'demo-dreamfluenzer.appspot.com',
  );

  /// Loads configuration asynchronously during application bootstrap.
  static Future<void> load() async {
    Map<String, dynamic>? configData;

    // 1. Attempt to load private real config
    try {
      final jsonStr = await rootBundle.loadString('assets/config/config.json');
      configData = jsonDecode(jsonStr) as Map<String, dynamic>;
      _isDemoMode = false;
      debugPrint(
        '[AppConfig] Loaded real private config from assets/config/config.json',
      );
    } catch (_) {
      // 2. Fall back to public demo config for open-source contributors
      try {
        final demoStr = await rootBundle.loadString(
          'assets/config/config.demo.json',
        );
        configData = jsonDecode(demoStr) as Map<String, dynamic>;
        _isDemoMode = true;
        debugPrint(
          '[AppConfig] Private config not found. Running in DEMO mode with assets/config/config.demo.json',
        );
      } catch (e) {
        debugPrint('[AppConfig] Failed to load config asset: $e');
        _isDemoMode = true;
      }
    }

    final fb = configData?['firebase'] as Map<String, dynamic>?;
    if (fb != null && fb['apiKey'] != null) {
      _firebaseOptions = FirebaseOptions(
        apiKey: fb['apiKey'] as String? ?? defaultDemoOptions.apiKey,
        appId: fb['appId'] as String? ?? defaultDemoOptions.appId,
        messagingSenderId:
            fb['messagingSenderId'] as String? ??
            defaultDemoOptions.messagingSenderId,
        projectId: fb['projectId'] as String? ?? defaultDemoOptions.projectId,
        authDomain:
            fb['authDomain'] as String? ?? defaultDemoOptions.authDomain,
        storageBucket:
            fb['storageBucket'] as String? ?? defaultDemoOptions.storageBucket,
        measurementId: fb['measurementId'] as String?,
      );
    } else {
      _firebaseOptions = defaultDemoOptions;
    }

    // Initialize dynamic AgencyConfig values
    final agency = configData?['agency'] as Map<String, dynamic>?;
    AgencyConfig.initFromMap(agency);

    _isLoaded = true;
  }
}
