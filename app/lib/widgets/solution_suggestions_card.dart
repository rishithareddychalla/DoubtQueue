import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../theme/app_theme.dart';

class SolutionSuggestionsCard extends StatelessWidget {
  const SolutionSuggestionsCard({
    super.key,
    required this.suggestions,
    required this.onSolvedSelf,
    this.onBookmark,
    this.isBookmarked,
  });

  final List<Doubt> suggestions;
  final VoidCallback onSolvedSelf;
  final void Function(Doubt doubt)? onBookmark;
  final bool Function(Doubt doubt)? isBookmarked;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: colors.secondary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: colors.secondary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Similar solved questions found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'A mentor already answered similar questions. Check if this answers your doubt:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final doubt in suggestions) ...[
              _SuggestionItem(
                doubt: doubt,
                onBookmark: onBookmark != null
                    ? () => onBookmark!(doubt)
                    : null,
                isBookmarked: isBookmarked != null && isBookmarked!(doubt),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onSolvedSelf,
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                label: const Text('This solved my doubt!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({
    required this.doubt,
    this.onBookmark,
    this.isBookmarked = false,
  });

  final Doubt doubt;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  doubt.topic,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (doubt.similarityScore != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(doubt.similarityScore! * 100).round()}% match',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Q: ${doubt.question}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onBookmark != null) ...[
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                    size: 20,
                    color: isBookmarked
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  onPressed: onBookmark,
                  tooltip: isBookmarked
                      ? 'Saved in library'
                      : 'Save to library',
                ),
              ],
            ],
          ),

          if (doubt.resolutionNotes != null &&
              doubt.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mentor Answer:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doubt.resolutionNotes!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
