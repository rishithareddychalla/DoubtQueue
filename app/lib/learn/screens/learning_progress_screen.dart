import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/content_width.dart';
import '../../widgets/section_header.dart';
import '../services/learn_service.dart';
import '../widgets/mastery_progress_card.dart';

class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({super.key, required this.service});

  final LearnService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final topicStats = service.topicStats.values.toList();
    final sessions = service.allSessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Progress')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(pagePadding),
          children: [
            MasteryProgressCard(service: service),
            const SizedBox(height: sectionGap),
            const SectionHeader(
              title: 'Topic Performance',
              subtitle: 'Retention and mastery across different subject topics',
            ),
            const SizedBox(height: itemGap),
            if (topicStats.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No topic stats yet. Save doubts from sessions to track topic mastery.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              for (final stat in topicStats) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              stat.topic,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: stat.masteryPercent >= 75
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${stat.masteryPercent}% Mastered',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: stat.masteryPercent >= 75
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stat.totalCount > 0
                                ? (stat.masteredCount / stat.totalCount)
                                : 0,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              stat.masteryPercent >= 75
                                  ? const Color(0xFF10B981)
                                  : colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${stat.totalCount} saved • ${stat.masteredCount} mastered',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (stat.dueCount > 0)
                              Text(
                                '${stat.dueCount} due for review',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: itemGap),
              ],
            ],
            const SizedBox(height: sectionGap),
            const SectionHeader(
              title: 'Revision History',
              subtitle: 'Recent flashcard practice sessions',
            ),
            const SizedBox(height: itemGap),
            if (sessions.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No revision sessions completed yet. Start a session to build your review streak.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              for (final s in sessions.take(10)) ...[
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: s.successPercent >= 75
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        s.successPercent >= 75
                            ? Icons.check_circle_outline
                            : Icons.refresh,
                        color: s.successPercent >= 75
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    title: Text(
                      '${s.cardsReviewed} cards reviewed',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${s.rememberedCount} remembered • ${s.needsRevisionCount} needed work\n${timeAgo(s.completedAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),

                    trailing: Text(
                      '${s.successPercent}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: s.successPercent >= 75
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: itemGap),
              ],
            ],
            const SizedBox(height: sectionGap),
            _buildMethodologyCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodologyCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'How Mastery is Calculated',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'DoubtQueue Learn uses an adaptive interval-based spaced repetition schedule (Leitner system):\n'
              '• Level 1 (1 day): Newly saved or missed questions.\n'
              '• Level 2 (3 days): Successfully recalled once.\n'
              '• Level 3 (7 days): Retained across multiple intervals (Mastery achieved at ≥75% success).\n'
              '• Level 4 (14 days) & Level 5 (30 days): Long-term durable memory.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
