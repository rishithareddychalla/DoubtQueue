import 'package:flutter/material.dart';

import '../models/doubt.dart';
import 'status_badge.dart';

class QueueStatusCard extends StatelessWidget {
  const QueueStatusCard({
    super.key,
    required this.doubt,
    required this.refreshing,
    this.onBookmark,
    this.isBookmarked = false,
  });

  final Doubt doubt;
  final bool refreshing;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            if (doubt.isWaiting)
              _buildWaiting(context)
            else
              _buildOtherStatus(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        StatusBadge(status: doubt.status),
        const Spacer(),
        if (refreshing) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Updating', style: Theme.of(context).textTheme.labelMedium),
        ],
      ],
    );
  }

  Widget _buildWaiting(BuildContext context) {
    final theme = Theme.of(context);

    if (doubt.isSessionClosed) {
      return Column(
        children: [
          Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Session closed',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The mentor has ended this session. New questions will not be taken.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Your position',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${doubt.position ?? '-'}',
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Students ahead of you: ${doubt.studentsAhead}',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You are currently in the queue.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtherStatus(BuildContext context) {
    final theme = Theme.of(context);
    final style = statusStyleFor(doubt.status);

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: style.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: style.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(style.icon, size: 34, color: style.accent),
        ),
        const SizedBox(height: 14),
        Text(
          _message(doubt.status),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (doubt.resolutionNotes != null &&
            doubt.resolutionNotes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mentor resolution notes',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(doubt.resolutionNotes!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        if (doubt.status == 'SOLVED' && onBookmark != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: isBookmarked ? null : onBookmark,
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
              size: 18,
            ),
            label: Text(
              isBookmarked
                  ? 'Saved to Knowledge Library'
                  : 'Save to Knowledge Library',
            ),
          ),
        ],
      ],
    );
  }

  String _message(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return "It's your turn. The mentor is ready for your doubt.";
      case 'SOLVED':
        return 'Your doubt has been solved.';
      case 'SKIPPED':
        return 'Your doubt was skipped.';
      default:
        return '';
    }
  }
}
