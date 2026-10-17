import 'package:doubtqueue/learn/models/revision_card.dart';
import 'package:doubtqueue/learn/models/revision_session.dart';
import 'package:doubtqueue/learn/services/learn_service.dart';
import 'package:doubtqueue/learn/storage/memory_learn_storage.dart';
import 'package:doubtqueue/models/doubt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryLearnStorage storage;
  late LearnService service;

  setUp(() {
    storage = MemoryLearnStorage();
    service = LearnService(storage: storage);
  });

  Doubt sampleDoubt({
    int id = 1,
    String topic = 'Flutter',
    String question = 'How do widgets rebuild in Flutter?',
    String? notes,
  }) {
    return Doubt(
      id: id,
      sessionId: 10,
      topic: topic,
      question: question,
      status: 'SOLVED',
      resolutionNotes: notes ?? 'By calling setState to mark element dirty.',
    );
  }

  test('loads cleanly when storage is empty', () async {
    await service.load();
    expect(service.isLoaded, isTrue);
    expect(service.totalDoubtsCount, 0);
    expect(service.dueCount, 0);
    expect(service.masteredCount, 0);
    expect(service.allSavedDoubts, isEmpty);
  });

  test('recovers gracefully from corrupted storage json', () async {
    storage = MemoryLearnStorage({
      'doubtqueue_learn_saved_doubts_v1': '{corrupted-json...',
    });
    service = LearnService(storage: storage);
    await service.load();

    expect(service.isLoaded, isTrue);
    expect(service.totalDoubtsCount, 0);
  });

  test('bookmarks and unbookmarks a doubt correctly', () async {
    await service.load();
    final doubt = sampleDoubt(id: 42);

    expect(service.isBookmarked(42), isFalse);

    final saved = await service.bookmark(
      doubt,
      personalNotes: 'Remember setState!',
    );
    expect(service.isBookmarked(42), isTrue);
    expect(service.totalDoubtsCount, 1);
    expect(saved.personalNotes, 'Remember setState!');
    expect(saved.hasPersonalNotes, isTrue);

    // Persisted to storage
    final rawJson = await storage.read('doubtqueue_learn_saved_doubts_v1');
    expect(rawJson, contains('doubt_42_'));
    expect(rawJson, contains('Remember setState!'));

    // Unbookmark
    await service.unbookmark(saved.id);
    expect(service.isBookmarked(42), isFalse);
    expect(service.totalDoubtsCount, 0);
  });

  test('updates personal notes and tags', () async {
    await service.load();
    final saved = await service.bookmark(sampleDoubt(id: 101));

    await service.updatePersonalNotes(saved.id, 'Updated takeaway note');
    await service.updateTags(saved.id, ['Exam', 'Tricky']);

    final updated = service.allSavedDoubts.first;
    expect(updated.personalNotes, 'Updated takeaway note');
    expect(updated.tags, ['Exam', 'Tricky']);
    expect(service.allTags, ['Exam', 'Tricky']);
  });

  test(
    'spaced repetition rating calculations (Needs Revision, Good, Easy)',
    () async {
      await service.load();
      final now = DateTime(2026, 1, 1, 10, 0);
      final saved = await service.bookmark(sampleDoubt(id: 5), now: now);

      // Initial state: Level 1, interval 1d, due immediately
      expect(saved.revision.level, 1);
      expect(saved.revision.intervalDays, 1);
      expect(saved.revision.isDue(now), isTrue);

      // 1. Rate Good: level increases to 2, interval 3 days
      final reviewed1 = await service.recordCardReview(
        saved.id,
        RevisionRating.good,
        now: now,
      );
      expect(reviewed1!.revision.level, 2);
      expect(reviewed1.revision.intervalDays, 3);
      expect(reviewed1.revision.reviewCount, 1);
      expect(reviewed1.revision.successCount, 1);
      expect(reviewed1.revision.isDue(now), isFalse);
      expect(
        reviewed1.revision.isDue(now.add(const Duration(days: 4))),
        isTrue,
      );

      // 2. Rate Needs Revision: resets level to 1, interval 1 day
      final reviewed2 = await service.recordCardReview(
        saved.id,
        RevisionRating.needsRevision,
        now: now.add(const Duration(days: 4)),
      );
      expect(reviewed2!.revision.level, 1);
      expect(reviewed2.revision.intervalDays, 1);
      expect(reviewed2.revision.reviewCount, 2);
      expect(reviewed2.revision.successCount, 1);
      expect(reviewed2.revision.isMastered, isFalse);

      // 3. Rate Easy: advances by 2 levels (1 -> 3), interval 7 days
      final reviewed3 = await service.recordCardReview(
        saved.id,
        RevisionRating.easy,
        now: now.add(const Duration(days: 5)),
      );
      expect(reviewed3!.revision.level, 3);
      expect(reviewed3.revision.intervalDays, 7);
      expect(reviewed3.revision.reviewCount, 3);
      expect(reviewed3.revision.successCount, 2);
    },
  );

  test(
    'mastery calculation requires level >= 3 and retention >= 75%',
    () async {
      await service.load();
      final now = DateTime(2026, 1, 1);
      final saved = await service.bookmark(sampleDoubt(id: 10), now: now);

      // Review Good 3 times
      var current = saved;
      for (var i = 0; i < 3; i++) {
        current = (await service.recordCardReview(
          current.id,
          RevisionRating.good,
          now: now.add(Duration(days: i * 3)),
        ))!;
      }

      expect(current.revision.level, 4);
      expect(current.revision.reviewCount, 3);
      expect(current.revision.successCount, 3);
      expect(current.revision.retentionPercent, 100);
      expect(current.revision.isMastered, isTrue);
      expect(service.masteredCount, 1);
      expect(service.masteryPercent, 100);
    },
  );

  test(
    'search filters across topic, question, answer, personal notes, and tags',
    () async {
      await service.load();
      final d1 = await service.bookmark(
        sampleDoubt(
          id: 1,
          topic: 'Arrays',
          question: 'How to sort numeric items?',
        ),
      );
      await service.updatePersonalNotes(
        d1.id,
        'Use foreach loops for associative keys',
      );
      await service.updateTags(d1.id, ['PHP']);

      final d2 = await service.bookmark(
        sampleDoubt(
          id: 2,
          topic: 'Widgets',
          question: 'Stateful vs Stateless lifecycle',
        ),
      );
      await service.updateTags(d2.id, ['Flutter']);

      expect(service.search(query: 'associative'), hasLength(1));
      expect(service.search(query: 'associative').first.id, d1.id);

      expect(service.search(query: 'Widgets'), hasLength(1));
      expect(service.search(tag: 'Flutter'), hasLength(1));
      expect(service.search(tag: 'PHP'), hasLength(1));
      expect(service.search(topic: 'Arrays'), hasLength(1));
      expect(service.search(query: 'nonexistent'), isEmpty);
    },
  );

  test('records and returns revision sessions history', () async {
    await service.load();
    final session = RevisionSession(
      id: 'session_test_1',
      completedAt: DateTime.now(),
      cardsReviewed: 5,
      rememberedCount: 4,
      needsRevisionCount: 1,
      reviewedDoubtIds: ['d1', 'd2'],
    );

    await service.recordSession(session);
    expect(service.allSessions, hasLength(1));
    expect(service.allSessions.first.cardsReviewed, 5);
    expect(service.allSessions.first.successPercent, 80);

    // Persisted to storage
    final rawSessions = await storage.read('doubtqueue_learn_sessions_v1');
    expect(rawSessions, contains('session_test_1'));
  });

  test('topicStats correctly groups and computes retention', () async {
    await service.load();
    final now = DateTime.now();

    final d1 = await service.bookmark(
      sampleDoubt(id: 1, topic: 'Async'),
      now: now,
    );
    await service.recordCardReview(d1.id, RevisionRating.easy, now: now);

    final d2 = await service.bookmark(
      sampleDoubt(id: 2, topic: 'Async'),
      now: now,
    );
    await service.recordCardReview(d2.id, RevisionRating.good, now: now);

    await service.bookmark(sampleDoubt(id: 3, topic: 'Widgets'), now: now);

    final stats = service.topicStats;
    expect(stats.containsKey('Async'), isTrue);
    expect(stats.containsKey('Widgets'), isTrue);
    expect(stats['Async']!.totalCount, 2);
    expect(stats['Widgets']!.totalCount, 1);
  });
}
