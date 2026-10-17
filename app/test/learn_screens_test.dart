import 'package:doubtqueue/learn/models/revision_card.dart';
import 'package:doubtqueue/learn/models/revision_session.dart';
import 'package:doubtqueue/learn/screens/knowledge_library_screen.dart';
import 'package:doubtqueue/learn/screens/learn_dashboard_screen.dart';
import 'package:doubtqueue/learn/screens/learning_progress_screen.dart';
import 'package:doubtqueue/learn/screens/revision_session_screen.dart';
import 'package:doubtqueue/learn/services/learn_service.dart';
import 'package:doubtqueue/learn/storage/memory_learn_storage.dart';
import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/widgets/queue_status_card.dart';
import 'package:doubtqueue/widgets/solution_suggestions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Doubt createSampleDoubt({
  int id = 1,
  String topic = 'Flutter',
  String question = 'How does hot reload work?',
  String notes = 'Injects updated source code files into the running Dart VM.',
}) {
  return Doubt(
    id: id,
    sessionId: 10,
    topic: topic,
    question: question,
    status: 'SOLVED',
    resolutionNotes: notes,
  );
}

Future<void> pumpScreen(WidgetTester tester, {required Widget screen}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeBackend backend;
  late MemoryLearnStorage storage;
  late LearnService learnService;

  setUp(() async {
    backend = FakeBackend();
    storage = MemoryLearnStorage();
    learnService = LearnService(storage: storage);
    await learnService.load();
  });

  group('LearnDashboardScreen', () {
    testWidgets('renders empty state when library is empty', (tester) async {
      await pumpScreen(
        tester,
        screen: LearnDashboardScreen(service: learnService, api: backend.api),
      );

      expect(find.text('DoubtQueue Learn'), findsOneWidget);
      expect(find.text('No solutions saved yet'), findsOneWidget);
      expect(find.text('Add Solutions to Start'), findsOneWidget);
      expect(find.text('Saved Solutions'), findsOneWidget);
      expect(find.text('Due for Review'), findsOneWidget);
      expect(find.text('Mastered'), findsWidgets);
    });

    testWidgets(
      'renders metrics, mastery card, and recent doubts when populated',
      (tester) async {
        await learnService.bookmark(
          createSampleDoubt(
            id: 1,
            topic: 'Flutter',
            question: 'What is a BuildContext?',
          ),
        );
        await learnService.bookmark(
          createSampleDoubt(
            id: 2,
            topic: 'Dart',
            question: 'What is sound null safety?',
          ),
        );

        await pumpScreen(
          tester,
          screen: LearnDashboardScreen(service: learnService, api: backend.api),
        );

        expect(find.text('Daily Revision Session'), findsOneWidget);
        expect(find.text('Start Revision (2 due)'), findsOneWidget);
        expect(find.text('Mastery & Revision Progress'), findsOneWidget);
        expect(find.text('Recently Saved'), findsOneWidget);
        expect(find.text('Q: What is a BuildContext?'), findsOneWidget);
        expect(find.text('Q: What is sound null safety?'), findsOneWidget);
      },
    );

    testWidgets('navigates to Knowledge Library screen on app bar action tap', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        screen: LearnDashboardScreen(service: learnService, api: backend.api),
      );

      await tester.tap(find.byTooltip('Knowledge library'));
      await tester.pumpAndSettle();

      expect(find.text('Knowledge Library'), findsOneWidget);
      expect(find.byType(KnowledgeLibraryScreen), findsOneWidget);
    });

    testWidgets(
      'navigates to Learning Analytics screen on app bar action tap',
      (tester) async {
        await pumpScreen(
          tester,
          screen: LearnDashboardScreen(service: learnService, api: backend.api),
        );

        await tester.tap(find.byTooltip('Progress & history'));
        await tester.pumpAndSettle();

        expect(find.text('Learning Progress'), findsOneWidget);
        expect(find.byType(LearningProgressScreen), findsOneWidget);
      },
    );
  });

  group('KnowledgeLibraryScreen', () {
    testWidgets('lists doubts and filters by search query and tags', (
      tester,
    ) async {
      final d1 = await learnService.bookmark(
        createSampleDoubt(
          id: 1,
          topic: 'Flutter',
          question: 'How do Keys work?',
        ),
      );
      await learnService.updateTags(d1.id, ['Widgets']);

      final d2 = await learnService.bookmark(
        createSampleDoubt(
          id: 2,
          topic: 'Database',
          question: 'Explain SQL indexing',
        ),
      );
      await learnService.updateTags(d2.id, ['SQL']);

      await pumpScreen(
        tester,
        screen: KnowledgeLibraryScreen(service: learnService, api: backend.api),
      );

      expect(find.text('Q: How do Keys work?'), findsOneWidget);
      expect(find.text('Q: Explain SQL indexing'), findsOneWidget);

      // Search query filtering
      await tester.enterText(find.byType(TextField), 'indexing');
      await tester.pumpAndSettle();

      expect(find.text('Q: Explain SQL indexing'), findsOneWidget);
      expect(find.text('Q: How do Keys work?'), findsNothing);

      // Clear search query
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Tag chip filtering
      await tester.tap(find.widgetWithText(FilterChip, '#Widgets'));
      await tester.pumpAndSettle();

      expect(find.text('Q: How do Keys work?'), findsOneWidget);
      expect(find.text('Q: Explain SQL indexing'), findsNothing);
    });

    testWidgets('opens edit notes dialog and updates notes', (tester) async {
      await learnService.bookmark(
        createSampleDoubt(
          id: 1,
          topic: 'Flutter',
          question: 'What is InheritedWidget?',
        ),
      );

      await pumpScreen(
        tester,
        screen: KnowledgeLibraryScreen(service: learnService, api: backend.api),
      );

      // Tap 'Add note' button on SavedDoubtCard
      await tester.tap(find.text('Add note'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Notes & Tags'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(
        textFields.first,
        'Remember Provider wraps this internally',
      );
      await tester.enterText(textFields.last, 'architecture');
      await tester.tap(find.byTooltip('Add tag'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Remember Provider wraps this internally'),
        findsOneWidget,
      );
      expect(find.text('#architecture'), findsOneWidget);
    });

    testWidgets('unbookmarks doubt when remove menu item is tapped', (
      tester,
    ) async {
      await learnService.bookmark(
        createSampleDoubt(
          id: 1,
          topic: 'Flutter',
          question: 'What is InheritedWidget?',
        ),
      );

      await pumpScreen(
        tester,
        screen: KnowledgeLibraryScreen(service: learnService, api: backend.api),
      );

      expect(find.text('Q: What is InheritedWidget?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Remove from library'), findsOneWidget);
      await tester.tap(find.text('Remove from library'));
      await tester.pumpAndSettle();

      expect(find.text('Remove from Knowledge Library?'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Q: What is InheritedWidget?'), findsNothing);
      expect(find.text('Your Knowledge Library is empty'), findsOneWidget);
    });
  });

  group('RevisionSessionScreen', () {
    testWidgets('flips card and rates items until session completes', (
      tester,
    ) async {
      final doubt = await learnService.bookmark(
        createSampleDoubt(
          id: 1,
          topic: 'Flutter',
          question: 'What does setState do?',
          notes: 'Marks the element dirty and schedules build next frame.',
        ),
      );

      await pumpScreen(
        tester,
        screen: RevisionSessionScreen(service: learnService, deck: [doubt]),
      );

      expect(find.text('What does setState do?'), findsOneWidget);
      expect(find.text('Try answering in your head first!'), findsOneWidget);
      expect(find.text('Reveal Solution'), findsOneWidget);
      expect(
        find.text('Marks the element dirty and schedules build next frame.'),
        findsNothing,
      );

      // Reveal Solution
      await tester.tap(find.text('Reveal Solution'));
      await tester.pumpAndSettle();

      expect(find.text('MENTOR SOLUTION'), findsOneWidget);
      expect(
        find.text('Marks the element dirty and schedules build next frame.'),
        findsOneWidget,
      );
      expect(find.text('Needs Work'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);

      // Rate card as Good
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();

      // Session complete screen
      expect(find.text('Session Completed!'), findsOneWidget);
      expect(find.text('Session Retention: 100%'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);
      expect(find.text('Back to Dashboard'), findsOneWidget);

      // Verify learnService recorded session
      expect(learnService.allSessions, hasLength(1));
      expect(learnService.allSessions.first.cardsReviewed, 1);
      expect(learnService.allSessions.first.rememberedCount, 1);
    });
  });

  group('LearningProgressScreen', () {
    testWidgets(
      'renders mastery breakdown, topic metrics, and leitner methodology',
      (tester) async {
        final d = await learnService.bookmark(
          createSampleDoubt(
            id: 1,
            topic: 'Dart',
            question: 'What is a Future?',
          ),
        );

        // Rate card to create review history
        await learnService.recordCardReview(d.id, RevisionRating.easy);
        await learnService.recordSession(
          RevisionSession(
            id: 'test_session_id',
            completedAt: DateTime.now(),
            cardsReviewed: 1,
            rememberedCount: 1,
            needsRevisionCount: 0,
            reviewedDoubtIds: [d.id],
          ),
        );

        await pumpScreen(
          tester,
          screen: LearningProgressScreen(service: learnService),
        );

        expect(find.text('Learning Progress'), findsOneWidget);
        expect(find.text('Mastery & Revision Progress'), findsOneWidget);
        expect(find.text('Topic Performance'), findsOneWidget);
        expect(find.text('Dart'), findsOneWidget);
        expect(find.text('Revision History'), findsOneWidget);
        expect(find.text('1 cards reviewed'), findsOneWidget);
        expect(find.text('How Mastery is Calculated'), findsOneWidget);
      },
    );
  });

  group('Integrations with SolutionSuggestionsCard and QueueStatusCard', () {
    testWidgets('SolutionSuggestionsCard bookmark button works correctly', (
      tester,
    ) async {
      bool bookmarked = false;
      final doubt = createSampleDoubt(
        id: 42,
        question: 'Suggested Solution Doubt',
      );

      await pumpScreen(
        tester,
        screen: Scaffold(
          body: SolutionSuggestionsCard(
            suggestions: [doubt],
            isBookmarked: (d) => bookmarked,
            onBookmark: (d) {
              bookmarked = true;
            },
            onSolvedSelf: () {},
          ),
        ),
      );

      expect(find.text('Q: Suggested Solution Doubt'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_add_outlined));
      await tester.pumpAndSettle();

      expect(bookmarked, isTrue);
    });

    testWidgets(
      'QueueStatusCard shows Save to Knowledge Library button when SOLVED',
      (tester) async {
        bool bookmarkCalled = false;
        final solvedDoubt = createSampleDoubt(
          id: 99,
          notes: 'Detailed answer provided',
        );

        await pumpScreen(
          tester,
          screen: Scaffold(
            body: QueueStatusCard(
              doubt: solvedDoubt,
              refreshing: false,
              isBookmarked: false,
              onBookmark: () {
                bookmarkCalled = true;
              },
            ),
          ),
        );

        expect(find.text('Save to Knowledge Library'), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);

        await tester.tap(find.text('Save to Knowledge Library'));
        await tester.pumpAndSettle();

        expect(bookmarkCalled, isTrue);
      },
    );
  });
}
