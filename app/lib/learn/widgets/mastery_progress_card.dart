import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../services/learn_service.dart';

class MasteryProgressCard extends StatelessWidget {
  const MasteryProgressCard({
    super.key,
    required this.service,
    this.onViewDetails,
  });

  final LearnService service;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final total = service.totalDoubtsCount;
    final mastered = service.masteredCount;
    final inReview = service.inReviewCount;
    final learning = service.learningCount;
    final percent = service.masteryPercent;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mastery & Revision Progress',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        total == 0
                            ? 'No doubts saved yet'
                            : '$mastered of $total solutions mastered ($percent%)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onViewDetails != null)
                  IconButton(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    tooltip: 'View detailed progress',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: total == 0
                    ? Container(color: const Color(0xFFE2E8F0))
                    : Row(
                        children: [
                          if (mastered > 0)
                            Expanded(
                              flex: mastered,
                              child: Container(color: const Color(0xFF10B981)),
                            ),
                          if (inReview > 0)
                            Expanded(
                              flex: inReview,
                              child: Container(color: const Color(0xFF0284C7)),
                            ),
                          if (learning > 0)
                            Expanded(
                              flex: learning,
                              child: Container(color: const Color(0xFFF59E0B)),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatPill('Mastered', mastered, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildStatPill('In Review', inReview, const Color(0xFF0284C7)),
                const SizedBox(width: 8),
                _buildStatPill('Learning', learning, const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
