import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'status_badge.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session, required this.onJoin});

  final Session session;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: session.isOpen
              ? colors.primary.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: session.isOpen ? 1.6 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(context),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: 'Mentor: ${session.mentorName}',
            ),
            _InfoRow(
              icon: Icons.groups_outlined,
              text: _waitingText(session.waitingCount),
            ),
            if (session.createdAt != null)
              _InfoRow(
                icon: Icons.schedule_rounded,
                text: 'Started ${timeAgo(session.createdAt)}',
              ),
            const SizedBox(height: 16),
            _buildAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            session.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.2,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(status: session.status),
      ],
    );
  }

  Widget _buildAction(BuildContext context) {
    if (session.isOpen) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onJoin,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Join queue'),
        ),
      );
    }

    return Text(
      'This session has ended.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: const Color(0xFF64748B),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _waitingText(int count) {
    if (count == 0) {
      return 'No students waiting';
    }
    return count == 1 ? '1 student waiting' : '$count students waiting';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
