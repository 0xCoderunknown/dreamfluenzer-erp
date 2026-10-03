// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'config/app_config.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// In this FOSS release, credentials are dynamically resolved via [AppConfig]:
/// - Real credentials: loaded from `assets/config/config.json` (gitignored).
/// - Demo fallback: loaded from `assets/config/config.demo.json` (public demo).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AppConfig.firebaseOptions;
      default:
        return AppConfig.firebaseOptions;
    }
  }

  static FirebaseOptions get web => AppConfig.firebaseOptions;
}
