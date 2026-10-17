import 'package:flutter/material.dart';

class StatusStyle {
  const StatusStyle({
    required this.label,
    required this.icon,
    required this.accent,
    required this.background,
    required this.text,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color text;
}

StatusStyle statusStyleFor(String status) {
  switch (status) {
    case 'WAITING':
      return const StatusStyle(
        label: 'Waiting',
        icon: Icons.hourglass_top_rounded,
        accent: Color(0xFF0284C7),
        background: Color(0xFFF0F9FF),
        text: Color(0xFF0369A1),
      );
    case 'IN_PROGRESS':
      return const StatusStyle(
        label: 'In progress',
        icon: Icons.play_circle_fill_rounded,
        accent: Color(0xFFD97706),
        background: Color(0xFFFFFBEB),
        text: Color(0xFFB45309),
      );
    case 'SOLVED':
      return const StatusStyle(
        label: 'Solved',
        icon: Icons.check_circle_rounded,
        accent: Color(0xFF059669),
        background: Color(0xFFECFDF5),
        text: Color(0xFF047857),
      );
    case 'SKIPPED':
      return const StatusStyle(
        label: 'Skipped',
        icon: Icons.skip_next_rounded,
        accent: Color(0xFF64748B),
        background: Color(0xFFF1F5F9),
        text: Color(0xFF475569),
      );
    case 'CLOSED':
      return const StatusStyle(
        label: 'Closed',
        icon: Icons.lock_outline_rounded,
        accent: Color(0xFFE11D48),
        background: Color(0xFFFFF1F2),
        text: Color(0xFFBE123C),
      );
    case 'OPEN':
      return const StatusStyle(
        label: 'Open',
        icon: Icons.fiber_manual_record_rounded,
        accent: Color(0xFF059669),
        background: Color(0xFFECFDF5),
        text: Color(0xFF047857),
      );
    default:
      return StatusStyle(
        label: status,
        icon: Icons.help_outline_rounded,
        accent: const Color(0xFF64748B),
        background: const Color(0xFFF1F5F9),
        text: const Color(0xFF475569),
      );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: style.accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.accent),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: style.text,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
