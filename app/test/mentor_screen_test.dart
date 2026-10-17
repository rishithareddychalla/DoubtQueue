import 'package:doubtqueue/screens/mentor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

FakeBackend backendWithQueue({int waiting = 2}) {
  final backend = FakeBackend();
  for (final name in ['Asha', 'Ben', 'Chitra'].take(waiting)) {
    backend.addDoubt(1, name);
  }
  return backend;
}

Future<void> pumpMentor(WidgetTester tester, FakeBackend backend) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: MentorScreen(api: backend.api)));
  await tester.pumpAndSettle();
}

Future<void> selectSession(WidgetTester tester) async {
  await tester.tap(find.text('Session & Stats'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButton<int>));
  await tester.pumpAndSettle();
  await tester.tap(
    find.textContaining('PHP Basics Doubt Session (Priya)').last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Queue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows an empty state and the start form without sessions', (
    tester,
  ) async {
    await pumpMentor(tester, FakeBackend(sessions: []));

    expect(find.text('Mentor dashboard'), findsOneWidget);
    expect(find.text('Start a session'), findsOneWidget);
    expect(find.text('No open sessions'), findsOneWidget);
    expect(find.text('Statistics'), findsNothing);
  });

  testWidgets('shows an error state when the dashboard cannot load', (
    tester,
  ) async {
    final backend = FakeBackend()..failRequests = true;
    await pumpMentor(tester, backend);

    expect(find.text('Could not load this page'), findsOneWidget);

    backend.failRequests = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Session & Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Start a session'), findsOneWidget);
  });

  testWidgets('shows statistics and the waiting queue for a session', (
    tester,
  ) async {
    final backend = backendWithQueue();
    backend.addDoubt(1, 'Dev', status: 'SOLVED');
    await pumpMentor(tester, backend);

    await selectSession(tester);
    await tester.tap(find.text('Session & Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Waiting'), findsWidgets);
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.text('Queue'));
    await tester.pumpAndSettle();

    expect(find.text('2 waiting'), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('No doubt is currently in progress.'), findsOneWidget);
  });

  testWidgets('shows an empty queue state', (tester) async {
    await pumpMentor(tester, backendWithQueue(waiting: 0));

    await selectSession(tester);

    expect(find.text('No students are waiting.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Take next student'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('take next shows the current doubt and mark solved clears it', (
    tester,
  ) async {
    final backend = backendWithQueue();
    await pumpMentor(tester, backend);
    await selectSession(tester);

    await tester.tap(find.text('Take next student'));
    await tester.pumpAndSettle();

    expect(find.text('asha@example.com'), findsOneWidget);
    expect(find.text('Mark solved'), findsOneWidget);
    expect(find.text('Take next student'), findsNothing);
    expect(backend.doubts.first['status'], 'IN_PROGRESS');
    expect(find.text('1 waiting'), findsOneWidget);

    await tester.tap(find.text('Mark solved'));
    await tester.pumpAndSettle();

    expect(backend.doubts.first['status'], 'SOLVED');
    expect(find.text('No doubt is currently in progress.'), findsOneWidget);
  });

  testWidgets('skipping asks for confirmation first', (tester) async {
    final backend = backendWithQueue();
    await pumpMentor(tester, backend);
    await selectSession(tester);
    await tester.tap(find.text('Take next student'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Skip this doubt?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(backend.doubts.first['status'], 'IN_PROGRESS');

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip doubt'));
    await tester.pumpAndSettle();
    expect(backend.doubts.first['status'], 'SKIPPED');
  });

  testWidgets('closing a session asks for confirmation first', (tester) async {
    final backend = backendWithQueue();
    await pumpMentor(tester, backend);
    await selectSession(tester);
    await tester.tap(find.text('Session & Stats'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close session'));
    await tester.pumpAndSettle();
    expect(find.text('Close this session?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(backend.sessions.first['status'], 'OPEN');

    await tester.tap(find.text('Close session'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Close session'));
    await tester.pumpAndSettle();

    expect(backend.sessions.first['status'], 'CLOSED');
    expect(find.text('PHP Basics Doubt Session was closed.'), findsOneWidget);
    expect(find.text('No open sessions'), findsOneWidget);
  });

  testWidgets('creating a session validates, shows feedback and selects it', (
    tester,
  ) async {
    final backend = FakeBackend(sessions: []);
    await pumpMentor(tester, backend);

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a session title'), findsOneWidget);
    expect(find.text('Enter your name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Dart Basics');
    await tester.enterText(find.byType(TextFormField).at(1), 'Meera');
    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    expect(backend.sessions, hasLength(1));
    await tester.tap(find.text('Session & Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Session created. It is selected below.'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Dart Basics (Meera)'), findsOneWidget);
  });

  testWidgets('the queue refresh button loads new students', (tester) async {
    final backend = backendWithQueue(waiting: 1);
    await pumpMentor(tester, backend);
    await selectSession(tester);
    expect(find.text('Ben'), findsNothing);

    backend.addDoubt(1, 'Ben');
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('2 waiting'), findsOneWidget);
  });

  testWidgets('restores in-progress doubt when session is loaded', (
    tester,
  ) async {
    final backend = FakeBackend();
    final doubt = backend.addDoubt(1, 'Asha', status: 'IN_PROGRESS');
    doubt['started_at'] = '2026-01-01 10:15:00';

    await pumpMentor(tester, backend);
    await selectSession(tester);

    expect(find.text('asha@example.com'), findsOneWidget);
    expect(find.text('Mark solved'), findsOneWidget);
    expect(find.text('No doubt is currently in progress.'), findsNothing);
  });

  testWidgets('mentor can attach resolution notes when marking solved', (
    tester,
  ) async {
    final backend = backendWithQueue();
    await pumpMentor(tester, backend);
    await selectSession(tester);

    await tester.tap(find.text('Take next student'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Resolution notes (optional)'),
      'Explain that arrays use integer indices.',
    );
    await tester.tap(find.text('Mark solved'));
    await tester.pumpAndSettle();

    expect(backend.doubts.first['status'], 'SOLVED');
    expect(
      backend.doubts.first['resolution_notes'],
      'Explain that arrays use integer indices.',
    );
  });

  testWidgets('shows topic intelligence and hotspots in session & stats tab', (
    tester,
  ) async {
    final backend = FakeBackend();
    final d1 = backend.addDoubt(1, 'Asha', status: 'SOLVED');
    d1['topic'] = 'Arrays';
    d1['resolution_notes'] = 'Use foreach loops.';

    final d2 = backend.addDoubt(1, 'Ben', status: 'SKIPPED');
    d2['topic'] = 'Async';

    final d3 = backend.addDoubt(1, 'Carl', status: 'SKIPPED');
    d3['topic'] = 'Async';

    await pumpMentor(tester, backend);
    await selectSession(tester);

    // Switch to Session & Stats tab
    await tester.tap(find.text('Session & Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Doubt Intelligence'), findsOneWidget);
    expect(find.text('Doubt Intelligence & Hotspots'), findsOneWidget);
    expect(find.text('Recurring Topics'), findsOneWidget);
    expect(find.text('Arrays'), findsWidgets);
    expect(find.text('Async'), findsWidgets);
    expect(find.textContaining('Hotspot: "Async"'), findsOneWidget);
    expect(find.text('Reference Solutions'), findsOneWidget);
    expect(find.text('Use foreach loops.'), findsOneWidget);
  });
}
