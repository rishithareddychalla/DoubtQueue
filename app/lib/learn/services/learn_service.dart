import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/doubt.dart';
import '../models/revision_card.dart';
import '../models/revision_session.dart';
import '../models/saved_doubt.dart';
import '../storage/learn_storage.dart';
import '../storage/preferences_learn_storage.dart';

class TopicMasteryStats {
  const TopicMasteryStats({
    required this.topic,
    required this.totalCount,
    required this.masteredCount,
    required this.dueCount,
    required this.averageRetention,
  });

  final String topic;
  final int totalCount;
  final int masteredCount;
  final int dueCount;
  final double averageRetention;

  int get masteryPercent =>
      totalCount > 0 ? ((masteredCount / totalCount) * 100).round() : 0;
  int get retentionPercent => (averageRetention * 100).round();
}

class LearnService extends ChangeNotifier {
  LearnService({LearnStorage? storage})
    : _storage = storage ?? const PreferencesLearnStorage();

  static const String _storageKeyDoubts = 'doubtqueue_learn_saved_doubts_v1';
  static const String _storageKeySessions = 'doubtqueue_learn_sessions_v1';

  final LearnStorage _storage;

  final List<SavedDoubt> _savedDoubts = [];
  final List<RevisionSession> _sessions = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<SavedDoubt> get allSavedDoubts => List.unmodifiable(_savedDoubts);
  List<RevisionSession> get allSessions => List.unmodifiable(_sessions);

  Future<void> load() async {
    try {
      final doubtsJson = await _storage.read(_storageKeyDoubts);
      _savedDoubts.clear();
      if (doubtsJson != null && doubtsJson.trim().isNotEmpty) {
        final decoded = jsonDecode(doubtsJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _savedDoubts.add(SavedDoubt.fromJson(item));
          }
        }
      }

      final sessionsJson = await _storage.read(_storageKeySessions);
      _sessions.clear();
      if (sessionsJson != null && sessionsJson.trim().isNotEmpty) {
        final decoded = jsonDecode(sessionsJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _sessions.add(RevisionSession.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading DoubtQueue Learn local storage: $e');
      // Graceful fallback to clean state on corrupted data
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  bool isBookmarked(int backendDoubtId) {
    return _savedDoubts.any((d) => d.backendDoubtId == backendDoubtId);
  }

  SavedDoubt? findByBackendId(int backendDoubtId) {
    for (final d in _savedDoubts) {
      if (d.backendDoubtId == backendDoubtId) return d;
    }
    return null;
  }

  Future<SavedDoubt> bookmark(
    Doubt doubt, {
    String? personalNotes,
    List<String> tags = const [],
    DateTime? now,
  }) async {
    final existing = findByBackendId(doubt.id);
    if (existing != null) {
      return existing;
    }

    final saved = SavedDoubt.fromDoubt(
      doubt,
      personalNotes: personalNotes,
      tags: tags,
      now: now,
    );

    _savedDoubts.insert(0, saved);
    await _persistDoubts();
    notifyListeners();
    return saved;
  }

  Future<void> unbookmark(String savedDoubtId) async {
    _savedDoubts.removeWhere((d) => d.id == savedDoubtId);
    await _persistDoubts();
    notifyListeners();
  }

  Future<void> unbookmarkByBackendId(int backendDoubtId) async {
    _savedDoubts.removeWhere((d) => d.backendDoubtId == backendDoubtId);
    await _persistDoubts();
    notifyListeners();
  }

  Future<SavedDoubt?> updatePersonalNotes(
    String savedDoubtId,
    String? notes,
  ) async {
    final index = _savedDoubts.indexWhere((d) => d.id == savedDoubtId);
    if (index == -1) return null;

    final updated = _savedDoubts[index].copyWith(personalNotes: notes);
    _savedDoubts[index] = updated;
    await _persistDoubts();
    notifyListeners();
    return updated;
  }

  Future<SavedDoubt?> updateTags(String savedDoubtId, List<String> tags) async {
    final index = _savedDoubts.indexWhere((d) => d.id == savedDoubtId);
    if (index == -1) return null;

    final updated = _savedDoubts[index].copyWith(tags: tags);
    _savedDoubts[index] = updated;
    await _persistDoubts();
    notifyListeners();
    return updated;
  }

  Future<SavedDoubt?> recordCardReview(
    String savedDoubtId,
    RevisionRating rating, {
    DateTime? now,
  }) async {
    final index = _savedDoubts.indexWhere((d) => d.id == savedDoubtId);
    if (index == -1) return null;

    final current = _savedDoubts[index];
    final updatedCard = current.revision.recordReview(rating, now: now);
    final updated = current.copyWith(
      revision: updatedCard,
      lastViewedAt: now ?? DateTime.now(),
    );

    _savedDoubts[index] = updated;
    await _persistDoubts();
    notifyListeners();
    return updated;
  }

  Future<RevisionSession> recordSession(RevisionSession session) async {
    _sessions.insert(0, session);
    await _persistSessions();
    notifyListeners();
    return session;
  }

  List<SavedDoubt> get dueForRevision {
    final now = DateTime.now();
    return _savedDoubts.where((d) => d.revision.isDue(now)).toList();
  }

  List<SavedDoubt> search({String? query, String? tag, String? topic}) {
    final cleanQuery = query?.trim().toLowerCase();
    final cleanTag = tag?.trim().toLowerCase();
    final cleanTopic = topic?.trim().toLowerCase();

    return _savedDoubts.where((doubt) {
      if (cleanTopic != null && cleanTopic.isNotEmpty && cleanTopic != 'all') {
        if (doubt.topic.trim().toLowerCase() != cleanTopic) return false;
      }

      if (cleanTag != null && cleanTag.isNotEmpty && cleanTag != 'all') {
        final hasTag = doubt.tags.any(
          (t) => t.trim().toLowerCase() == cleanTag,
        );
        if (!hasTag) return false;
      }

      if (cleanQuery != null && cleanQuery.isNotEmpty) {
        final matchesTopic = doubt.topic.toLowerCase().contains(cleanQuery);
        final matchesQuestion = doubt.question.toLowerCase().contains(
          cleanQuery,
        );
        final matchesAnswer = doubt.answer.toLowerCase().contains(cleanQuery);
        final matchesNotes =
            doubt.personalNotes?.toLowerCase().contains(cleanQuery) ?? false;
        final matchesTags = doubt.tags.any(
          (t) => t.toLowerCase().contains(cleanQuery),
        );

        return matchesTopic ||
            matchesQuestion ||
            matchesAnswer ||
            matchesNotes ||
            matchesTags;
      }

      return true;
    }).toList();
  }

  List<String> get allTags {
    final set = <String>{};
    for (final d in _savedDoubts) {
      set.addAll(d.tags.map((t) => t.trim()).where((t) => t.isNotEmpty));
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get allTopics {
    final set = <String>{};
    for (final d in _savedDoubts) {
      if (d.topic.trim().isNotEmpty) {
        set.add(d.topic.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  int get totalDoubtsCount => _savedDoubts.length;
  int get masteredCount =>
      _savedDoubts.where((d) => d.revision.isMastered).length;
  int get inReviewCount =>
      _savedDoubts.where((d) => d.revision.level == 2).length;
  int get learningCount =>
      _savedDoubts.where((d) => d.revision.level == 1).length;
  int get dueCount => dueForRevision.length;

  double get masteryPercentage =>
      totalDoubtsCount > 0 ? (masteredCount / totalDoubtsCount) : 0.0;
  int get masteryPercent => (masteryPercentage * 100).round();

  Map<String, TopicMasteryStats> get topicStats {
    final grouped = <String, List<SavedDoubt>>{};
    for (final d in _savedDoubts) {
      final t = d.topic.trim();
      grouped.putIfAbsent(t, () => []).add(d);
    }

    final result = <String, TopicMasteryStats>{};
    final now = DateTime.now();

    grouped.forEach((topic, doubts) {
      final total = doubts.length;
      final mastered = doubts.where((d) => d.revision.isMastered).length;
      final due = doubts.where((d) => d.revision.isDue(now)).length;
      final avgRetention = doubts.isEmpty
          ? 0.0
          : doubts
                    .map((d) => d.revision.retentionRate)
                    .reduce((a, b) => a + b) /
                total;

      result[topic] = TopicMasteryStats(
        topic: topic,
        totalCount: total,
        masteredCount: mastered,
        dueCount: due,
        averageRetention: avgRetention,
      );
    });

    return result;
  }

  Future<void> _persistDoubts() async {
    final list = _savedDoubts.map((d) => d.toJson()).toList();
    await _storage.write(_storageKeyDoubts, jsonEncode(list));
  }

  Future<void> _persistSessions() async {
    final list = _sessions.map((s) => s.toJson()).toList();
    await _storage.write(_storageKeySessions, jsonEncode(list));
  }
}
