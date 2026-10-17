import '../../models/doubt.dart';
import 'revision_card.dart';

class SavedDoubt {
  const SavedDoubt({
    required this.id,
    this.backendDoubtId,
    this.sessionId,
    required this.topic,
    required this.question,
    required this.answer,
    this.personalNotes,
    this.tags = const [],
    required this.savedAt,
    this.lastViewedAt,
    required this.revision,
  });

  factory SavedDoubt.fromDoubt(
    Doubt doubt, {
    String? personalNotes,
    List<String> tags = const [],
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final answerText =
        (doubt.resolutionNotes != null &&
            doubt.resolutionNotes!.trim().isNotEmpty)
        ? doubt.resolutionNotes!.trim()
        : 'Solution discussed during mentor session.';

    return SavedDoubt(
      id: 'doubt_${doubt.id}_${timestamp.millisecondsSinceEpoch}',
      backendDoubtId: doubt.id,
      sessionId: doubt.sessionId,
      topic: doubt.topic.trim().isNotEmpty ? doubt.topic.trim() : 'General',
      question: doubt.question.trim(),
      answer: answerText,
      personalNotes: personalNotes?.trim(),
      tags: tags,
      savedAt: timestamp,
      lastViewedAt: timestamp,
      revision: RevisionCard.initial(now: timestamp),
    );
  }

  factory SavedDoubt.fromJson(Map<String, dynamic> json) {
    return SavedDoubt(
      id: json['id'] as String,
      backendDoubtId: (json['backend_doubt_id'] as num?)?.toInt(),
      sessionId: (json['session_id'] as num?)?.toInt(),
      topic: (json['topic'] as String?) ?? 'General',
      question: (json['question'] as String?) ?? '',
      answer: (json['answer'] as String?) ?? '',
      personalNotes: json['personal_notes'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      savedAt:
          DateTime.tryParse(json['saved_at'] as String? ?? '') ??
          DateTime.now(),
      lastViewedAt: json['last_viewed_at'] != null
          ? DateTime.tryParse(json['last_viewed_at'] as String)
          : null,
      revision: json['revision'] != null
          ? RevisionCard.fromJson(json['revision'] as Map<String, dynamic>)
          : RevisionCard.initial(),
    );
  }

  final String id;
  final int? backendDoubtId;
  final int? sessionId;
  final String topic;
  final String question;
  final String answer;
  final String? personalNotes;
  final List<String> tags;
  final DateTime savedAt;
  final DateTime? lastViewedAt;
  final RevisionCard revision;

  bool get hasPersonalNotes =>
      personalNotes != null && personalNotes!.trim().isNotEmpty;

  SavedDoubt copyWith({
    String? topic,
    String? question,
    String? answer,
    String? personalNotes,
    List<String>? tags,
    DateTime? lastViewedAt,
    RevisionCard? revision,
  }) {
    return SavedDoubt(
      id: id,
      backendDoubtId: backendDoubtId,
      sessionId: sessionId,
      topic: topic ?? this.topic,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      personalNotes: personalNotes ?? this.personalNotes,
      tags: tags ?? this.tags,
      savedAt: savedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      revision: revision ?? this.revision,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backend_doubt_id': backendDoubtId,
      'session_id': sessionId,
      'topic': topic,
      'question': question,
      'answer': answer,
      'personal_notes': personalNotes,
      'tags': tags,
      'saved_at': savedAt.toIso8601String(),
      'last_viewed_at': lastViewedAt?.toIso8601String(),
      'revision': revision.toJson(),
    };
  }
}
