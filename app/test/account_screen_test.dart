import 'package:doubtqueue/learn/services/learn_service.dart';
import 'package:doubtqueue/learn/storage/memory_learn_storage.dart';
import 'package:doubtqueue/screens/account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

Future<void> pumpAccountScreen(
  WidgetTester tester, {
  FakeBackend? backend,
  LearnService? service,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final fakeBackend = backend ?? FakeBackend();
  final learnService = service ?? LearnService(storage: MemoryLearnStorage());
  await learnService.load();

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
      ),
      home: AccountScreen(api: fakeBackend.api, learnService: learnService),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders profile details and sections when logged in', (
    tester,
  ) async {
    await pumpAccountScreen(tester);

    // Profile card elements
    expect(find.text('Arjun Sharma'), findsOneWidget);
    expect(find.text('arjun.sharma@doubtqueue.edu'), findsOneWidget);
    expect(find.text('Computer Science & Engineering'), findsOneWidget);
    expect(find.text('Student • Active'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Sections
    expect(find.text('Learning & Doubts Overview'), findsOneWidget);
    expect(find.text('Knowledge Library'), findsOneWidget);
    expect(find.text('Learning Analytics & Progress'), findsOneWidget);
    expect(find.text('Preferences & System'), findsOneWidget);
    expect(find.text('Remember My Info'), findsOneWidget);
    expect(find.text('About DoubtQueue'), findsOneWidget);
    expect(find.text('v1.0.0 (GSoC Edition)'), findsOneWidget);
    expect(find.text('Backend API Server'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Project Overview'), findsOneWidget);
  });

  testWidgets('edit profile updates student name, email and role', (
    tester,
  ) async {
    await pumpAccountScreen(tester);

    // Open edit dialog
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(
      find.text('Edit Profile'),
      findsNWidgets(2),
    ); // Button + Dialog title
    expect(find.text('Save Changes'), findsOneWidget);

    // Enter updated details
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Rhea Roy');
    await tester.enterText(textFields.at(1), 'rhea.roy@doubtqueue.edu');
    await tester.enterText(textFields.at(2), 'Data Science & AI');

    // Save
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify profile updated
    expect(find.text('Rhea Roy'), findsOneWidget);
    expect(find.text('rhea.roy@doubtqueue.edu'), findsOneWidget);
    expect(find.text('Data Science & AI'), findsOneWidget);
    expect(find.text('Profile updated successfully.'), findsOneWidget);
  });

  testWidgets('edit profile validation flags empty or invalid inputs', (
    tester,
  ) async {
    await pumpAccountScreen(tester);

    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '');
    await tester.enterText(textFields.at(1), 'invalid-email');

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter a valid email'), findsOneWidget);

    // Cancel to dismiss
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('log out workflow prompts confirmation and enters guest mode', (
    tester,
  ) async {
    await pumpAccountScreen(tester);

    // Tap Log Out
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Log Out of DoubtQueue?'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to log out? Your local learning progress, notes, and revision history will remain safe on this device.',
      ),
      findsOneWidget,
    );

    // Cancel first
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Arjun Sharma'), findsOneWidget);

    // Tap Log Out again and confirm
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    // In confirmAction, confirmLabel is 'Log Out'
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();

    // Verify Guest Mode
    expect(find.text('You have been logged out.'), findsOneWidget);
    expect(find.text('Guest Account'), findsOneWidget);
    expect(find.text('Guest Mode'), findsOneWidget);
    expect(find.text('Not signed in • Offline Mode'), findsOneWidget);
    expect(find.text('Sign In / Log In'), findsOneWidget);
  });

  testWidgets('log in workflow from guest mode restores profile', (
    tester,
  ) async {
    await pumpAccountScreen(tester);

    // Log out first
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In / Log In'), findsOneWidget);

    // Tap Sign In
    await tester.tap(find.text('Sign In / Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In to DoubtQueue'), findsOneWidget);
    expect(find.text('Use Demo Student'), findsOneWidget);

    // Quick fill demo student
    await tester.tap(find.text('Use Demo Student'));
    await tester.pumpAndSettle();

    // Tap Log In in dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Check restored
    expect(find.text('Welcome back, Arjun Sharma!'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Arjun Sharma'), findsOneWidget);
    expect(find.text('Student • Active'), findsOneWidget);
  });

  testWidgets('backend connection test queries API and displays success', (
    tester,
  ) async {
    final backend = FakeBackend();
    await pumpAccountScreen(tester, backend: backend);

    await tester.ensureVisible(find.text('Test'));
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();

    expect(
      find.text('Connected to backend: 1 sessions retrieved successfully.'),
      findsOneWidget,
    );
  });

  testWidgets('project overview opens information modal', (tester) async {
    await pumpAccountScreen(tester);

    await tester.ensureVisible(find.text('Project Overview'));
    await tester.tap(find.text('Project Overview'));
    await tester.pumpAndSettle();

    expect(find.text('About DoubtQueue'), findsWidgets);
    expect(find.text('Core Features:'), findsOneWidget);
    expect(find.text('Architecture:'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Core Features:'), findsNothing);
  });

  testWidgets(
    'edit profile works when user is mentor without dropdown assertion error',
    (tester) async {
      SharedPreferences.setMockInitialValues({'account_role': 'Mentor'});
      final fakeBackend = FakeBackend();
      final learnService = LearnService(storage: MemoryLearnStorage());
      await learnService.load();

      await tester.pumpWidget(
        MaterialApp(
          home: AccountScreen(api: fakeBackend.api, learnService: learnService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
}
