import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/screens/my_doubt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<FakeBackend> pumpMyDoubt(WidgetTester tester, {int ahead = 2}) async {
  final backend = FakeBackend();
  for (var i = 0; i < ahead; i++) {
    backend.addDoubt(1, 'Student$i');
  }
  final mine = backend.addDoubt(1, 'Asha');
  final doubt = Doubt.fromJson({...mine, 'position': ahead + 1});

  await tester.pumpWidget(
    MaterialApp(
      home: MyDoubtScreen(api: backend.api, doubt: doubt),
    ),
  );
  return backend;
}

void main() {
  testWidgets('shows position, students ahead and the doubt details', (
    tester,
  ) async {
    await pumpMyDoubt(tester);

    expect(find.text('Your position'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Students ahead of you: 2'), findsOneWidget);
    expect(find.text('You are currently in the queue.'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('Arrays'), findsOneWidget);
    expect(find.text('How do loops work for Asha?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refreshes every 10 seconds and updates the position', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester);

    backend.doubts.first['status'] = 'SOLVED';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Students ahead of you: 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the turn message when the mentor takes the doubt', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester, ahead: 0);

    backend.doubts.last['status'] = 'IN_PROGRESS';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(
      find.text("It's your turn. The mentor is ready for your doubt."),
      findsOneWidget,
    );
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Your position'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('solved doubts show a message and stop refreshing', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester, ahead: 0);

    backend.doubts.last['status'] = 'SOLVED';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Your doubt has been solved.'), findsOneWidget);
    expect(find.text('Students ahead of you: 0'), findsNothing);

    backend.failRequests = true;
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Your doubt has been solved.'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });

  testWidgets('skipped doubts show the skipped message', (tester) async {
    final backend = await pumpMyDoubt(tester, ahead: 0);

    backend.doubts.last['status'] = 'SKIPPED';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Your doubt was skipped.'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
  });

  testWidgets('keeps the last status and shows an error when refresh fails', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester);

    backend.failRequests = true;
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Students ahead of you: 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows mentor resolution notes when available', (tester) async {
    final backend = await pumpMyDoubt(tester, ahead: 0);

    backend.doubts.last['status'] = 'SOLVED';
    backend.doubts.last['resolution_notes'] =
        'Remember that widgets rebuild from scratch.';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Your doubt has been solved.'), findsOneWidget);
    expect(find.text('Mentor resolution notes'), findsOneWidget);
    expect(
      find.text('Remember that widgets rebuild from scratch.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows session closed status and stops polling when session is closed',
    (tester) async {
      final backend = await pumpMyDoubt(tester, ahead: 1);

      backend.sessions.first['status'] = 'CLOSED';
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(find.text('Session closed'), findsOneWidget);
      expect(
        find.text(
          'The mentor has ended this session. New questions will not be taken.',
        ),
        findsOneWidget,
      );

      backend.failRequests = true;
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Something went wrong'), findsNothing);
    },
  );
}
