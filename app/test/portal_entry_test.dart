import 'package:doubtqueue/main.dart';
import 'package:doubtqueue/models/user.dart';
import 'package:doubtqueue/screens/portal_entry_screen.dart';
import 'package:doubtqueue/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

Future<void> pumpPortal(
  WidgetTester tester, {
  FakeBackend? backend,
  AuthService? authService,
  UserRole initialRole = UserRole.student,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final fakeBackend = backend ?? FakeBackend();
  final auth = authService ?? AuthService(api: fakeBackend.api);
  await auth.init();

  await tester.pumpWidget(
    MaterialApp(
      home: PortalEntryScreen(
        authService: auth,
        initialRole: initialRole,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders PortalEntryScreen with Student and Mentor portal tabs', (tester) async {
    await pumpPortal(tester);

    expect(find.text('DoubtQueue'), findsOneWidget);
    expect(find.text('Student Portal'), findsOneWidget);
    expect(find.text('Mentor Portal'), findsOneWidget);
    expect(find.text('Student Login'), findsOneWidget);
    expect(find.text('Sign In as Student'), findsOneWidget);
    expect(find.text('Fill Demo Student Credentials'), findsOneWidget);
  });

  testWidgets('switches between Student and Mentor portal tabs', (tester) async {
    await pumpPortal(tester);

    await tester.tap(find.text('Mentor Portal'));
    await tester.pumpAndSettle();

    expect(find.text('Mentor Login'), findsOneWidget);
    expect(find.text('Sign In as Mentor'), findsOneWidget);
    expect(find.text('Fill Demo Mentor Credentials'), findsOneWidget);
  });

  testWidgets('toggles between login and registration forms for student', (tester) async {
    await pumpPortal(tester);

    expect(find.text('New student? Register'), findsOneWidget);
    await tester.tap(find.text('New student? Register'));
    await tester.pumpAndSettle();

    expect(find.text('Student Registration'), findsOneWidget);
    expect(find.text('Register as Student'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Student Login'), findsOneWidget);
  });

  testWidgets('validates required fields on student login', (tester) async {
    await pumpPortal(tester);

    await tester.tap(find.text('Sign In as Student'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('fills demo student credentials and logs in successfully', (tester) async {
    final backend = FakeBackend();
    final auth = AuthService(api: backend.api);
    await pumpPortal(tester, backend: backend, authService: auth);

    await tester.tap(find.text('Fill Demo Student Credentials'));
    await tester.pumpAndSettle();

    expect(find.text('student@doubtqueue.edu'), findsOneWidget);

    await tester.tap(find.text('Sign In as Student'));
    await tester.pumpAndSettle();

    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentRole, equals(UserRole.student));
    expect(auth.currentUser?.email, equals('student@doubtqueue.edu'));
  });

  testWidgets('rejects mentor trying to log in via student portal with clear error message', (tester) async {
    final backend = FakeBackend();
    final auth = AuthService(api: backend.api);
    await pumpPortal(tester, backend: backend, authService: auth);

    // Enter mentor credentials into student portal
    final emailField = find.widgetWithText(TextFormField, 'Student Email *');
    final passField = find.widgetWithText(TextFormField, 'Password *');

    await tester.enterText(emailField, 'mentor@doubtqueue.edu');
    await tester.enterText(passField, 'Password123!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In as Student'));
    await tester.pumpAndSettle();

    expect(auth.isAuthenticated, isFalse);
    expect(find.textContaining('Access denied: This account is registered as a Mentor. Please use the Mentor Portal.'), findsOneWidget);
  });

  testWidgets('fills demo mentor credentials and logs in successfully as mentor', (tester) async {
    final backend = FakeBackend();
    final auth = AuthService(api: backend.api);
    await pumpPortal(tester, backend: backend, authService: auth, initialRole: UserRole.mentor);

    await tester.tap(find.text('Fill Demo Mentor Credentials'));
    await tester.pumpAndSettle();

    expect(find.text('mentor@doubtqueue.edu'), findsOneWidget);

    await tester.tap(find.text('Sign In as Mentor'));
    await tester.pumpAndSettle();

    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentRole, equals(UserRole.mentor));
    expect(auth.currentUser?.name, equals('Priya Sharma'));
  });

  testWidgets('mentor registration validates authorization secret key', (tester) async {
    final backend = FakeBackend();
    final auth = AuthService(api: backend.api);
    await pumpPortal(tester, backend: backend, authService: auth, initialRole: UserRole.mentor);

    await tester.tap(find.text('New mentor? Register'));
    await tester.pumpAndSettle();

    expect(find.text('Mentor Provisioning'), findsOneWidget);
    expect(find.text('Mentor Registration Secret *'), findsOneWidget);

    // Clear secret key
    final secretField = find.widgetWithText(TextFormField, 'Mentor Registration Secret *');
    await tester.enterText(secretField, '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Provision Mentor Account'));
    await tester.pumpAndSettle();

    expect(find.text('Mentor authorization key is required'), findsOneWidget);
  });

  testWidgets('full app flow routes to student portal upon student login', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend();
    final auth = AuthService(api: backend.api);

    await tester.pumpWidget(
      DoubtQueueApp(
        api: backend.api,
        authService: auth,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Portal'), findsOneWidget);

    // Tap demo student login
    await tester.tap(find.text('Fill Demo Student Credentials'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In as Student'));
    await tester.pumpAndSettle();

    // Verify routed to Student Portal Screen
    expect(find.text('Student Portal • Sessions'), findsOneWidget);
    expect(find.text('My Doubts'), findsOneWidget);
    expect(find.text('Student Portal'), findsNothing); // exited login portal
  });
}
