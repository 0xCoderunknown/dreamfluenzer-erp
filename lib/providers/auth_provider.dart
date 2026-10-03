import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  // ─── INITIALIZATION STATE ───
  bool _isInitialized = false;

  AppAuthProvider() {
    _auth.authStateChanges().listen(
      (User? user) {
        _user = user;
        _isInitialized = true;
        _isLoading = false;
        Future.microtask(() => notifyListeners());
      },
      onError: (err) {
        debugPrint('[AppAuthProvider] Auth state stream error: $err');
        _isInitialized = true;
        _isLoading = false;
        Future.microtask(() => notifyListeners());
      },
    );
  }

  User? get user => _user;

  bool get isAuthenticated => _user != null;

  bool get isLoading => _isLoading;

  bool get isInitialized =>
      _isInitialized; // Exposing initial token status check

  String get userEmail => _user?.email ?? '';

  // ─── AUTH ACTIONS ───
  Future<void> loginWithEmail(String email, String password) async {
    try {
      setStateLoading(true);
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setStateLoading(false);
      throw _mapAuthError(e.code);
    } catch (e) {
      setStateLoading(false);
      throw 'An unexpected error occurred. Please check your connection.';
    }
  }

  Future<void> logout() async {
    setStateLoading(true);
    await _auth.signOut();
    _user = null;
    setStateLoading(false);
  }

  void setStateLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential': // Modern Firebase Auth unified error key
        return 'No account exists with this email address or password mismatch.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-disabled':
        return 'This account has been deactivated by the administrator.';
      case 'network-request-failed':
        return 'System timeout. Check your internet connection.';
      default:
        return 'Authentication failed: $code';
    }
  }
}
