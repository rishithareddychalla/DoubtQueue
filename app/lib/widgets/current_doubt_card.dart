import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'status_badge.dart';

class CurrentDoubtCard extends StatefulWidget {
  const CurrentDoubtCard({
    super.key,
    required this.doubt,
    required this.busy,
    required this.onSolved,
    required this.onSkipped,
  });

  final Doubt doubt;
  final bool busy;
  final void Function([String? notes]) onSolved;
  final VoidCallback onSkipped;

  @override
  State<CurrentDoubtCard> createState() => _CurrentDoubtCardState();
}

class _CurrentDoubtCardState extends State<CurrentDoubtCard> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSolved() {
    final text = _notesController.text.trim();
    widget.onSolved(text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final doubt = widget.doubt;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: colors.primary, width: 1.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(theme),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  child: Text(
                    doubt.studentName.isNotEmpty
                        ? doubt.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doubt.studentName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        doubt.studentEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    doubt.topic,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doubt.question,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution notes (optional)',
                hintText: 'Add an answer or key takeaway for the student...',
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(ThemeData theme) {
    final doubt = widget.doubt;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusBadge(status: doubt.status),
        if (doubt.startedAt != null)
          Text(
            'Started ${timeAgo(doubt.startedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: widget.busy ? null : _handleSolved,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text('Mark solved'),
        ),
        OutlinedButton.icon(
          onPressed: widget.busy ? null : widget.onSkipped,
          icon: const Icon(Icons.skip_next_rounded, size: 18),
          label: const Text('Skip'),
        ),
      ],
    );
  }
}
