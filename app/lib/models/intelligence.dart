class TopicInsight {
  const TopicInsight({
    required this.topic,
    required this.normalizedTopic,
    required this.totalDoubts,
    required this.solvedCount,
    required this.skippedCount,
    required this.waitingCount,
    required this.inProgressCount,
    required this.unresolvedRate,
    required this.isHotspot,
  });

  factory TopicInsight.fromJson(Map<String, dynamic> json) {
    return TopicInsight(
      topic: json['topic'] as String,
      normalizedTopic: json['normalized_topic'] as String,
      totalDoubts: json['total_doubts'] as int,
      solvedCount: json['solved_count'] as int,
      skippedCount: json['skipped_count'] as int,
      waitingCount: json['waiting_count'] as int,
      inProgressCount: json['in_progress_count'] as int,
      unresolvedRate: (json['unresolved_rate'] as num).toDouble(),
      isHotspot: json['is_hotspot'] as bool,
    );
  }

  final String topic;
  final String normalizedTopic;
  final int totalDoubts;
  final int solvedCount;
  final int skippedCount;
  final int waitingCount;
  final int inProgressCount;
  final double unresolvedRate;
  final bool isHotspot;

  int get unresolvedPercent => (unresolvedRate * 100).round();
}

class SolvedReference {
  const SolvedReference({
    required this.id,
    required this.topic,
    required this.question,
    required this.resolutionNotes,
  });

  factory SolvedReference.fromJson(Map<String, dynamic> json) {
    return SolvedReference(
      id: json['id'] as int,
      topic: json['topic'] as String,
      question: json['question'] as String,
      resolutionNotes: (json['resolution_notes'] as String?) ?? '',
    );
  }

  final int id;
  final String topic;
  final String question;
  final String resolutionNotes;
}

class DoubtIntelligence {
  const DoubtIntelligence({
    required this.sessionId,
    required this.sessionTitle,
    required this.totalTopics,
    required this.recurringTopics,
    required this.hotspots,
    required this.topSolutions,
  });

  factory DoubtIntelligence.fromJson(Map<String, dynamic> json) {
    return DoubtIntelligence(
      sessionId: json['session_id'] as int,
      sessionTitle: (json['session_title'] as String?) ?? '',
      totalTopics: json['total_topics'] as int,
      recurringTopics:
          (json['recurring_topics'] as List<dynamic>?)
              ?.map(
                (item) => TopicInsight.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      hotspots:
          (json['hotspots'] as List<dynamic>?)
              ?.map(
                (item) => TopicInsight.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      topSolutions:
          (json['top_solutions'] as List<dynamic>?)
              ?.map(
                (item) =>
                    SolvedReference.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  final int sessionId;
  final String sessionTitle;
  final int totalTopics;
  final List<TopicInsight> recurringTopics;
  final List<TopicInsight> hotspots;
  final List<SolvedReference> topSolutions;

  bool get hasHotspots => hotspots.isNotEmpty;
}
