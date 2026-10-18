import 'package:doubtqueue/learn/services/learn_service.dart';
import 'package:doubtqueue/learn/storage/memory_learn_storage.dart';
import 'package:doubtqueue/models/user.dart';
import 'package:doubtqueue/screens/mentor_portal_screen.dart';
import 'package:doubtqueue/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

Future<void> pumpMentorPortal(
  WidgetTester tester, {
  FakeBackend? backend,
  AuthService? authService,
  int initialTab = 0,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final fakeBackend = backend ?? FakeBackend(
    sessions: [
      FakeBackend.openSession(1, 'PHP Basics Doubt Session', mentor: 'Priya Sharma'),
    ],
  );
  final auth = authService ?? AuthService(api: fakeBackend.api);
  await auth.init();

  // Log in as mentor
  await auth.login(
    email: 'mentor@doubtqueue.edu',
    password: 'Password123!',
    portalRole: UserRole.mentor,
  );

  final learnService = LearnService(storage: MemoryLearnStorage());
  await learnService.load();

  await tester.pumpWidget(
    MaterialApp(
      home: MentorPortalScreen(
        api: fakeBackend.api,
        authService: auth,
        learnService: learnService,
        initialTab: initialTab,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders MentorPortalScreen with My Sessions tab by default', (tester) async {
    final backend = FakeBackend(
      sessions: [
        FakeBackend.openSession(1, 'Algorithms & Data Structures', mentor: 'Priya Sharma'),
      ],
    );

    await pumpMentorPortal(tester, backend: backend);

    expect(find.text('Mentor Portal • My Sessions'), findsOneWidget);
    expect(find.text('Algorithms & Data Structures'), findsOneWidget);
    expect(find.text('Sessions You Manage'), findsOneWidget);
    expect(find.text('Manage Queue'), findsOneWidget);
    expect(find.text('My Sessions'), findsOneWidget);
    expect(find.text('Live Queue'), findsOneWidget);
    expect(find.text('Intelligence'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });

  testWidgets('switches between bottom navigation tabs', (tester) async {
    final backend = FakeBackend();
    await pumpMentorPortal(tester, backend: backend);

    // Switch to Live Queue
    await tester.tap(find.text('Live Queue'));
    await tester.pumpAndSettle();
    expect(find.text('Queue: PHP Basics Doubt Session'), findsOneWidget);

    // Switch to Intelligence
    await tester.tap(find.text('Intelligence'));
    await tester.pumpAndSettle();
    expect(find.text('Insights: PHP Basics Doubt Session'), findsOneWidget);
    expect(find.text('Session Overview & Queue Statistics'), findsOneWidget);

    // Switch to Account
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Preferences & System'), findsOneWidget);
  });

  testWidgets('taking next student moves waiting doubt to active current doubt', (tester) async {
    final backend = FakeBackend();
    final d = backend.addDoubt(1, 'Asha');
    d['topic'] = 'Hash Maps';
    d['question'] = 'How do collisions get resolved?';

    await pumpMentorPortal(tester, backend: backend, initialTab: 1);

    expect(find.text('Waiting Queue (1)'), findsOneWidget);
    expect(find.text('No doubt is currently in progress.'), findsOneWidget);

    // Tap "Take next student"
    await tester.tap(find.text('Take next student'));
    await tester.pumpAndSettle();

    // Now Asha is in progress
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Hash Maps'), findsOneWidget);
    expect(find.text('How do collisions get resolved?'), findsOneWidget);
    expect(find.text('Mark solved'), findsOneWidget);
    expect(find.text('Queue is clear'), findsOneWidget);
  });

  testWidgets('mentor marks active doubt as solved with resolution notes', (tester) async {
    final backend = FakeBackend();
    final d = backend.addDoubt(1, 'Asha', status: 'IN_PROGRESS');
    d['topic'] = 'Hash Maps';
    d['question'] = 'How do collisions get resolved?';

    await pumpMentorPortal(tester, backend: backend, initialTab: 1);

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Mark solved'), findsOneWidget);

    final notesField = find.widgetWithText(TextField, 'Resolution notes (optional)');
    await tester.enterText(notesField, 'Explained chaining and open addressing with linear probing.');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark solved'));
    await tester.pumpAndSettle();

    expect(backend.doubts.first['status'], equals('SOLVED'));
    expect(backend.doubts.first['resolution_notes'], contains('Explained chaining'));
    expect(find.text('No doubt is currently in progress.'), findsOneWidget);
  });

  testWidgets('intelligence tab displays topic stats and intelligence card', (tester) async {
    final backend = FakeBackend();
    backend.addDoubt(1, 'Student1', status: 'SOLVED', resolutionNotes: 'Solution 1');
    backend.addDoubt(1, 'Student2', status: 'SOLVED', resolutionNotes: 'Solution 2');

    await pumpMentorPortal(tester, backend: backend, initialTab: 2);

    expect(find.text('Session Overview & Queue Statistics'), findsOneWidget);
    expect(find.text('Smart Topic Intelligence & Doubt Hotspots'), findsOneWidget);
  });
}
