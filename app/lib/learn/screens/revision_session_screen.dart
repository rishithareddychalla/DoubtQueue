import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/content_width.dart';
import '../models/revision_card.dart';
import '../models/revision_session.dart';
import '../models/saved_doubt.dart';
import '../services/learn_service.dart';
import '../widgets/flashcard_view.dart';

class RevisionSessionScreen extends StatefulWidget {
  const RevisionSessionScreen({
    super.key,
    required this.service,
    required this.deck,
  });

  final LearnService service;
  final List<SavedDoubt> deck;

  @override
  State<RevisionSessionScreen> createState() => _RevisionSessionScreenState();
}

class _RevisionSessionScreenState extends State<RevisionSessionScreen> {
  int _currentIndex = 0;
  int _rememberedCount = 0;
  int _needsRevisionCount = 0;
  final List<String> _reviewedIds = [];
  bool _sessionComplete = false;

  Future<void> _onRating(RevisionRating rating) async {
    final doubt = widget.deck[_currentIndex];
    _reviewedIds.add(doubt.id);

    if (rating == RevisionRating.needsRevision) {
      _needsRevisionCount++;
    } else {
      _rememberedCount++;
    }

    await widget.service.recordCardReview(doubt.id, rating);

    if (_currentIndex + 1 < widget.deck.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      final session = RevisionSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        completedAt: DateTime.now(),
        cardsReviewed: widget.deck.length,
        rememberedCount: _rememberedCount,
        needsRevisionCount: _needsRevisionCount,
        reviewedDoubtIds: _reviewedIds,
      );

      await widget.service.recordSession(session);

      if (!mounted) return;
      setState(() {
        _sessionComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionComplete ? 'Revision Summary' : 'Revision Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.all(pagePadding),
          child: _sessionComplete
              ? _buildSummary(context)
              : _buildActiveSession(context),
        ),
      ),
    );
  }

  Widget _buildActiveSession(BuildContext context) {
    if (widget.deck.isEmpty) {
      return const Center(child: Text('No cards available for revision.'));
    }

    final currentCard = widget.deck[_currentIndex];

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / widget.deck.length,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FlashcardView(
            savedDoubt: currentCard,
            currentIndex: _currentIndex,
            totalCards: widget.deck.length,
            onRating: _onRating,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.deck.length;
    final successPercent = total > 0
        ? ((_rememberedCount / total) * 100).round()
        : 0;

    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Session Completed!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Great job keeping your knowledge fresh.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSummaryMetric(
                    'Reviewed',
                    '$total',
                    const Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryMetric(
                    'Remembered',
                    '$_rememberedCount',
                    const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryMetric(
                    'Needs Work',
                    '$_needsRevisionCount',
                    const Color(0xFFE11D48),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Session Retention: $successPercent%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
