import 'package:doubtqueue/learn/services/learn_service.dart';
import 'package:doubtqueue/learn/storage/memory_learn_storage.dart';
import 'package:doubtqueue/models/user.dart';
import 'package:doubtqueue/screens/student_portal_screen.dart';
import 'package:doubtqueue/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

Future<void> pumpStudentPortal(
  WidgetTester tester, {
  FakeBackend? backend,
  AuthService? authService,
  int initialTab = 0,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final fakeBackend = backend ?? FakeBackend();
  final auth = authService ?? AuthService(api: fakeBackend.api);
  await auth.init();

  // Log in as student
  await auth.login(
    email: 'student@doubtqueue.edu',
    password: 'Password123!',
    portalRole: UserRole.student,
  );

  final learnService = LearnService(storage: MemoryLearnStorage());
  await learnService.load();

  await tester.pumpWidget(
    MaterialApp(
      home: StudentPortalScreen(
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
  testWidgets('renders StudentPortalScreen with Sessions tab as default', (tester) async {
    final backend = FakeBackend(
      sessions: [
        FakeBackend.openSession(1, 'PHP Basics Doubt Session'),
      ],
    );

    await pumpStudentPortal(tester, backend: backend);

    expect(find.text('Student Portal • Sessions'), findsOneWidget);
    expect(find.text('PHP Basics Doubt Session'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('My Doubts'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });

  testWidgets('switches between bottom navigation tabs', (tester) async {
    final backend = FakeBackend();
    await pumpStudentPortal(tester, backend: backend);

    // Switch to My Doubts
    await tester.tap(find.text('My Doubts'));
    await tester.pumpAndSettle();
    expect(find.text('My Doubts & Queue Status'), findsOneWidget);

    // Switch to Learn
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('DoubtQueue Learn'), findsOneWidget);

    // Switch to Account
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Preferences & System'), findsOneWidget);
  });

  testWidgets('displays student doubts in My Doubts tab with queue position and resolution notes', (tester) async {
    final backend = FakeBackend();
    // Add waiting doubt
    final d1 = backend.addDoubt(1, 'Arjun');
    d1['topic'] = 'Binary Search Trees';
    d1['question'] = 'How do rotations work in AVL trees?';

    // Add solved doubt with mentor notes
    final d2 = backend.addDoubt(1, 'Arjun', status: 'SOLVED', resolutionNotes: 'Explained left-right rotation cases.');
    d2['topic'] = 'SQL Joins';
    d2['question'] = 'Difference between INNER and LEFT JOIN?';

    await pumpStudentPortal(tester, backend: backend, initialTab: 1);

    expect(find.text('My Doubts & Queue Status'), findsOneWidget);
    expect(find.text('Binary Search Trees'), findsOneWidget);
    expect(find.text('SQL Joins'), findsOneWidget);

    // Verify queue position indicator on waiting doubt
    expect(find.textContaining('Queue Position: #1'), findsOneWidget);

    // Verify mentor resolution notes on solved doubt
    expect(find.text('Mentor Resolution Notes:'), findsOneWidget);
    expect(find.text('Explained left-right rotation cases.'), findsOneWidget);
  });

  testWidgets('filters doubts in My Doubts tab by status chips', (tester) async {
    final backend = FakeBackend();
    final d1 = backend.addDoubt(1, 'Arjun');
    d1['topic'] = 'Binary Search Trees';

    final d2 = backend.addDoubt(1, 'Arjun', status: 'SOLVED', resolutionNotes: 'Solved!');
    d2['topic'] = 'SQL Joins';

    await pumpStudentPortal(tester, backend: backend, initialTab: 1);

    expect(find.text('Binary Search Trees'), findsOneWidget);
    expect(find.text('SQL Joins'), findsOneWidget);

    // Tap Waiting filter
    await tester.tap(find.widgetWithText(ChoiceChip, 'Waiting'));
    await tester.pumpAndSettle();

    expect(find.text('Binary Search Trees'), findsOneWidget);
    expect(find.text('SQL Joins'), findsNothing);

    // Tap Solved filter
    await tester.tap(find.widgetWithText(ChoiceChip, 'Solved'));
    await tester.pumpAndSettle();

    expect(find.text('Binary Search Trees'), findsNothing);
    expect(find.text('SQL Joins'), findsOneWidget);
  });

  testWidgets('allows student to self-resolve their waiting doubt', (tester) async {
    final backend = FakeBackend();
    final d1 = backend.addDoubt(1, 'Arjun');
    d1['topic'] = 'Binary Search Trees';
    d1['question'] = 'How do rotations work?';

    await pumpStudentPortal(tester, backend: backend, initialTab: 1);

    expect(find.text('Self-resolved?'), findsOneWidget);
    await tester.tap(find.text('Self-resolved?'));
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Self-Resolve Doubt'), findsOneWidget);
    expect(find.text('Mark Solved'), findsOneWidget);

    await tester.tap(find.text('Mark Solved'));
    await tester.pumpAndSettle();

    expect(backend.doubts.first['status'], equals('SOLVED'));
    expect(find.text('Doubt marked as solved!'), findsOneWidget);
  });
}
