import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/content_width.dart';
import '../../widgets/section_header.dart';
import '../services/learn_service.dart';
import '../widgets/mastery_progress_card.dart';
import '../widgets/saved_doubt_card.dart';
import 'knowledge_library_screen.dart';
import 'learning_progress_screen.dart';
import 'revision_session_screen.dart';

class LearnDashboardScreen extends StatefulWidget {
  const LearnDashboardScreen({
    super.key,
    required this.service,
    required this.api,
  });

  final LearnService service;
  final ApiService api;

  @override
  State<LearnDashboardScreen> createState() => _LearnDashboardScreenState();
}

class _LearnDashboardScreenState extends State<LearnDashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            KnowledgeLibraryScreen(service: widget.service, api: widget.api),
      ),
    );
  }

  void _openProgress() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningProgressScreen(service: widget.service),
      ),
    );
  }

  void _startRevision({bool forceAll = false}) {
    final deck = forceAll || widget.service.dueCount == 0
        ? widget.service.allSavedDoubts
        : widget.service.dueForRevision;

    if (deck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No solutions saved yet. Save doubts from sessions or search to start revising.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RevisionSessionScreen(service: widget.service, deck: deck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = widget.service.totalDoubtsCount;
    final due = widget.service.dueCount;
    final mastered = widget.service.masteredCount;
    final recent = widget.service.allSavedDoubts.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DoubtQueue Learn'),
        actions: [
          IconButton(
            onPressed: _openProgress,
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Progress & history',
          ),
          IconButton(
            onPressed: _openLibrary,
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Knowledge library',
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(pagePadding),
          children: [
            Row(
              children: [
                _buildMetricTile(
                  context,
                  label: 'Saved Solutions',
                  value: '$total',
                  icon: Icons.bookmark_added_rounded,
                  color: colors.primary,
                ),
                const SizedBox(width: itemGap),
                _buildMetricTile(
                  context,
                  label: 'Due for Review',
                  value: '$due',
                  icon: Icons.timer_outlined,
                  color: due > 0
                      ? const Color(0xFFD97706)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: itemGap),
                _buildMetricTile(
                  context,
                  label: 'Mastered',
                  value: '$mastered',
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: sectionGap),
            Card(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardRadius),
                side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Revision Session',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      due > 0
                          ? 'You have $due card${due == 1 ? '' : 's'} scheduled for revision today based on spaced repetition.'
                          : (total > 0
                                ? 'All caught up! No cards are currently due, but you can practice your deck anytime.'
                                : 'Bookmark solved doubts from queue sessions or discovery to start interactive revision.'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: total == 0
                            ? _openLibrary
                            : () => _startRevision(forceAll: due == 0),
                        icon: Icon(
                          total == 0
                              ? Icons.add_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          total == 0
                              ? 'Add Solutions to Start'
                              : (due > 0
                                    ? 'Start Revision ($due due)'
                                    : 'Practice Deck ($total cards)'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: sectionGap),
            MasteryProgressCard(
              service: widget.service,
              onViewDetails: _openProgress,
            ),
            const SizedBox(height: sectionGap),
            SectionHeader(
              title: 'Recently Saved',
              subtitle: 'Solutions saved to your local library',
              trailing: total > 0
                  ? TextButton(
                      onPressed: _openLibrary,
                      child: const Text('View all'),
                    )
                  : null,
            ),
            const SizedBox(height: itemGap),
            if (recent.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 36,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No solutions saved yet',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Whenever a mentor resolves a doubt, or when searching similar questions, tap bookmark to add it to your Learn library.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openLibrary,
                        icon: const Icon(Icons.travel_explore_rounded),
                        label: const Text('Discover Solutions'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              for (final doubt in recent) ...[
                SavedDoubtCard(
                  savedDoubt: doubt,
                  onEditNote: () {
                    _openLibrary();
                  },
                  onRemove: () async {
                    await widget.service.unbookmark(doubt.id);
                  },
                  onRevise: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RevisionSessionScreen(
                          service: widget.service,
                          deck: [doubt],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: itemGap),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
