import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/saved_doubt.dart';

class SavedDoubtCard extends StatelessWidget {
  const SavedDoubtCard({
    super.key,
    required this.savedDoubt,
    required this.onEditNote,
    required this.onRemove,
    this.onRevise,
  });

  final SavedDoubt savedDoubt;
  final VoidCallback onEditNote;
  final VoidCallback onRemove;
  final VoidCallback? onRevise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rev = savedDoubt.revision;
    final isDue = rev.isDue();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: isDue
              ? colors.primary.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: isDue ? 1.5 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    savedDoubt.topic,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: rev.isMastered
                        ? const Color(0xFFDCFCE7)
                        : (isDue
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rev.isMastered
                        ? 'Mastered'
                        : (isDue
                              ? 'Due for review'
                              : 'Level ${rev.level} • in ${rev.intervalDays}d'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: rev.isMastered
                          ? const Color(0xFF166534)
                          : (isDue
                                ? const Color(0xFF92400E)
                                : const Color(0xFF475569)),
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') onEditNote();
                    if (val == 'remove') onRemove();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Edit note & tags')),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_remove_outlined,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Remove from library',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Q: ${savedDoubt.question}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 15,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mentor Solution',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    savedDoubt.answer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            if (savedDoubt.hasPersonalNotes) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Personal Note',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      savedDoubt.personalNotes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (savedDoubt.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in savedDoubt.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditNote,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: Text(
                    savedDoubt.hasPersonalNotes ? 'Edit note' : 'Add note',
                  ),
                ),
                if (onRevise != null) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: onRevise,
                    icon: const Icon(Icons.fitness_center_rounded, size: 16),
                    label: const Text('Revise'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
