class RevisionSession {
  const RevisionSession({
    required this.id,
    required this.completedAt,
    required this.cardsReviewed,
    required this.rememberedCount,
    required this.needsRevisionCount,
    this.reviewedDoubtIds = const [],
  });

  factory RevisionSession.fromJson(Map<String, dynamic> json) {
    return RevisionSession(
      id: json['id'] as String,
      completedAt:
          DateTime.tryParse(json['completed_at'] as String? ?? '') ??
          DateTime.now(),
      cardsReviewed: (json['cards_reviewed'] as num?)?.toInt() ?? 0,
      rememberedCount: (json['remembered_count'] as num?)?.toInt() ?? 0,
      needsRevisionCount: (json['needs_revision_count'] as num?)?.toInt() ?? 0,
      reviewedDoubtIds:
          (json['reviewed_doubt_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  final String id;
  final DateTime completedAt;
  final int cardsReviewed;
  final int rememberedCount;
  final int needsRevisionCount;
  final List<String> reviewedDoubtIds;

  double get successRate =>
      cardsReviewed > 0 ? (rememberedCount / cardsReviewed) : 0.0;
  int get successPercent => (successRate * 100).round();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completed_at': completedAt.toIso8601String(),
      'cards_reviewed': cardsReviewed,
      'remembered_count': rememberedCount,
      'needs_revision_count': needsRevisionCount,
      'reviewed_doubt_ids': reviewedDoubtIds,
    };
  }
}
