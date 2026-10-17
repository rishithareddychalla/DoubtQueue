import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/models/session.dart';
import 'package:doubtqueue/screens/join_queue_screen.dart';
import 'package:doubtqueue/screens/mentor_screen.dart';
import 'package:doubtqueue/screens/my_doubt_screen.dart';
import 'package:doubtqueue/screens/session_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

const widths = [360.0, 390.0, 600.0, 820.0, 1024.0, 1440.0];

FakeBackend busyBackend() {
  final backend = FakeBackend(
    sessions: [
      FakeBackend.openSession(1, 'PHP Basics Doubt Session'),
      FakeBackend.openSession(2, 'Flutter Layout Session', mentor: 'Arjun'),
    ],
  );
  backend.addDoubt(1, 'Asha');
  backend.addDoubt(1, 'Ben');
  backend.addDoubt(1, 'Chitra');
  return backend;
}

Future<void> pumpAtWidth(
  WidgetTester tester,
  double width,
  Widget screen, {
  double height = 900,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  // Layout problems such as overflow are reported as test exceptions.
  // The test font is wider than real fonts, so these checks are strict.
  for (final width in widths) {
    group('at ${width.toInt()}px', () {
      testWidgets('session list fits', (tester) async {
        await pumpAtWidth(
          tester,
          width,
          SessionListScreen(api: busyBackend().api),
        );

        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Join queue'), findsWidgets);
      });

      testWidgets('join queue form fits', (tester) async {
        final session = Session.fromJson({
          ...FakeBackend.openSession(1, 'PHP Basics Doubt Session'),
          'waiting_count': 3,
        });
        await pumpAtWidth(
          tester,
          width,
          JoinQueueScreen(api: busyBackend().api, session: session),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('my doubt screen fits', (tester) async {
        final backend = busyBackend();
        final doubt = Doubt.fromJson({...backend.doubts.last, 'position': 3});
        await pumpAtWidth(
          tester,
          width,
          MyDoubtScreen(api: backend.api, doubt: doubt),
        );

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('mentor dashboard fits', (tester) async {
        await pumpAtWidth(
          tester,
          width,
          MentorScreen(api: busyBackend().api),
          height: 3000,
        );

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
        await tester.tap(find.text('Take next student'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Mark solved'), findsOneWidget);
      });
    });
  }
}
