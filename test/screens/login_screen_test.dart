import 'package:dreamfluenzer_erp/providers/auth_provider.dart';
import 'package:dreamfluenzer_erp/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _MockAuthProvider extends ChangeNotifier implements AppAuthProvider {
  bool _isInitialized = true;
  bool _isLoading = false;
  User? _user;
  String? mockErrorOnLogin;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isAuthenticated => _user != null;

  @override
  User? get user => _user;

  @override
  String get userEmail => _user?.email ?? '';

  void setInitialized(bool val) {
    _isInitialized = val;
    notifyListeners();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  @override
  Future<void> loginWithEmail(String email, String password) async {
    if (mockErrorOnLogin != null) {
      throw mockErrorOnLogin!;
    }
  }

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  @override
  void setStateLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createTestWidget(AppAuthProvider auth) {
    return ChangeNotifierProvider<AppAuthProvider>.value(
      value: auth,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Displays initializing indicator when not initialized', (
      tester,
    ) async {
      final mockAuth = _MockAuthProvider();
      mockAuth.setInitialized(false);

      await tester.pumpWidget(createTestWidget(mockAuth));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Initializing'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('Renders login form elements when initialized', (tester) async {
      final mockAuth = _MockAuthProvider();

      await tester.pumpWidget(createTestWidget(mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('ERP Portal'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Triggers validation errors on empty submission', (
      tester,
    ) async {
      final mockAuth = _MockAuthProvider();

      await tester.pumpWidget(createTestWidget(mockAuth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Toggles password visibility icon on tap', (tester) async {
      final mockAuth = _MockAuthProvider();

      await tester.pumpWidget(createTestWidget(mockAuth));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('Displays error message banner when login fails', (
      tester,
    ) async {
      final mockAuth = _MockAuthProvider();
      mockAuth.mockErrorOnLogin = 'Incorrect password. Please try again.';

      await tester.pumpWidget(createTestWidget(mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'admin@agency.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrongpassword',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Incorrect password. Please try again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
