import 'package:doubtqueue/models/session.dart';
import 'package:doubtqueue/screens/join_queue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<FakeBackend> pumpJoin(WidgetTester tester, {bool closed = false}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final backend = FakeBackend();
  if (closed) {
    backend.sessions.first['status'] = 'CLOSED';
  }
  final session = Session.fromJson({
    ...backend.sessions.first,
    'waiting_count': 0,
  });

  await tester.pumpWidget(
    MaterialApp(
      home: JoinQueueScreen(api: backend.api, session: session),
    ),
  );
  return backend;
}

Future<void> fillForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Asha');
  await tester.enterText(fields.at(1), 'asha@example.com');
  await tester.enterText(fields.at(2), 'Arrays');
  await tester.enterText(fields.at(3), 'How do loops work?');
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.byIcon(Icons.login));
  await tester.tap(find.byIcon(Icons.login));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows validation messages for an empty form', (tester) async {
    await pumpJoin(tester);

    await submit(tester);

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter a topic'), findsOneWidget);
    expect(find.text('Enter your question'), findsOneWidget);
  });

  testWidgets('rejects an email without an at sign', (tester) async {
    await pumpJoin(tester);
    await fillForm(tester);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'asha.example.com',
    );

    await submit(tester);

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('joining opens the my doubt screen with the queue position', (
    tester,
  ) async {
    await pumpJoin(tester);
    await fillForm(tester);

    await submit(tester);

    expect(find.text('My doubt'), findsOneWidget);
    expect(find.text('Your position'), findsOneWidget);
    expect(find.text('Students ahead of you: 0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the API message when the session is closed', (
    tester,
  ) async {
    await pumpJoin(tester, closed: true);
    await fillForm(tester);

    await submit(tester);

    expect(find.text('Session with id 1 is closed'), findsOneWidget);
    expect(find.text('Join queue'), findsWidgets);
  });

  testWidgets('suggests similar solved questions and allows self-resolution', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final backend = FakeBackend();
    backend.addDoubt(
      1,
      'Senior Student',
      status: 'SOLVED',
      resolutionNotes: r'Use foreach ($array as $key => $val) in PHP.',
    );
    final session = Session.fromJson({
      ...backend.sessions.first,
      'waiting_count': 0,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: JoinQueueScreen(api: backend.api, session: session),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(2), 'Arrays');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Similar solved questions found'), findsOneWidget);
    expect(
      find.text(r'Use foreach ($array as $key => $val) in PHP.'),
      findsOneWidget,
    );
    expect(find.text('85% match'), findsOneWidget);

    expect(find.text('This solved my doubt!'), findsOneWidget);

    await tester.tap(find.text('This solved my doubt!'));
    await tester.pump();

    expect(
      find.text('Great! Glad you found an answer to your doubt.'),
      findsOneWidget,
    );
  });
}
