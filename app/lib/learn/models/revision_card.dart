import 'dart:math';

enum RevisionRating { needsRevision, good, easy }

class RevisionCard {
  const RevisionCard({
    this.level = 1,
    this.reviewCount = 0,
    this.successCount = 0,
    this.lastReviewedAt,
    required this.nextReviewDue,
    this.intervalDays = 1,
  });

  factory RevisionCard.initial({DateTime? now}) {
    final current = now ?? DateTime.now();
    return RevisionCard(
      level: 1,
      reviewCount: 0,
      successCount: 0,
      lastReviewedAt: null,
      nextReviewDue: current,
      intervalDays: 1,
    );
  }

  factory RevisionCard.fromJson(Map<String, dynamic> json) {
    return RevisionCard(
      level: (json['level'] as num?)?.toInt() ?? 1,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      successCount: (json['success_count'] as num?)?.toInt() ?? 0,
      lastReviewedAt: json['last_reviewed_at'] != null
          ? DateTime.tryParse(json['last_reviewed_at'] as String)
          : null,
      nextReviewDue: json['next_review_due'] != null
          ? (DateTime.tryParse(json['next_review_due'] as String) ??
                DateTime.now())
          : DateTime.now(),
      intervalDays: (json['interval_days'] as num?)?.toInt() ?? 1,
    );
  }

  final int level;
  final int reviewCount;
  final int successCount;
  final DateTime? lastReviewedAt;
  final DateTime nextReviewDue;
  final int intervalDays;

  bool isDue([DateTime? now]) {
    final reference = now ?? DateTime.now();
    return reference.isAfter(nextReviewDue) ||
        reference.isAtSameMomentAs(nextReviewDue);
  }

  bool get isMastered {
    if (level < 3 || reviewCount == 0) return false;
    return (successCount / reviewCount) >= 0.75;
  }

  double get retentionRate =>
      reviewCount > 0 ? (successCount / reviewCount) : 0.0;
  int get retentionPercent => (retentionRate * 100).round();

  RevisionCard recordReview(RevisionRating rating, {DateTime? now}) {
    final reviewTime = now ?? DateTime.now();
    final newReviewCount = reviewCount + 1;

    switch (rating) {
      case RevisionRating.needsRevision:
        return RevisionCard(
          level: 1,
          reviewCount: newReviewCount,
          successCount: successCount,
          lastReviewedAt: reviewTime,
          intervalDays: 1,
          nextReviewDue: reviewTime.add(const Duration(days: 1)),
        );

      case RevisionRating.good:
        final newLevel = min(5, level + 1);
        final newInterval = _intervalForLevel(newLevel);
        return RevisionCard(
          level: newLevel,
          reviewCount: newReviewCount,
          successCount: successCount + 1,
          lastReviewedAt: reviewTime,
          intervalDays: newInterval,
          nextReviewDue: reviewTime.add(Duration(days: newInterval)),
        );

      case RevisionRating.easy:
        final newLevel = min(5, level + 2);
        final newInterval = _intervalForLevel(newLevel);
        return RevisionCard(
          level: newLevel,
          reviewCount: newReviewCount,
          successCount: successCount + 1,
          lastReviewedAt: reviewTime,
          intervalDays: newInterval,
          nextReviewDue: reviewTime.add(Duration(days: newInterval)),
        );
    }
  }

  static int _intervalForLevel(int lvl) {
    switch (lvl) {
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 7;
      case 4:
        return 14;
      case 5:
      default:
        return 30;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'review_count': reviewCount,
      'success_count': successCount,
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'next_review_due': nextReviewDue.toIso8601String(),
      'interval_days': intervalDays,
    };
  }
}
