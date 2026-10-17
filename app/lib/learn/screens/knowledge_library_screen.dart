import 'package:flutter/material.dart';

import '../../models/doubt.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/content_width.dart';
import '../../widgets/state_views.dart';
import '../models/saved_doubt.dart';
import '../services/learn_service.dart';
import '../widgets/edit_note_dialog.dart';
import '../widgets/saved_doubt_card.dart';
import 'revision_session_screen.dart';

class KnowledgeLibraryScreen extends StatefulWidget {
  const KnowledgeLibraryScreen({
    super.key,
    required this.service,
    required this.api,
  });

  final LearnService service;
  final ApiService api;

  @override
  State<KnowledgeLibraryScreen> createState() => _KnowledgeLibraryScreenState();
}

class _KnowledgeLibraryScreenState extends State<KnowledgeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTag = 'all';

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _openEditNoteDialog(SavedDoubt doubt) {
    showDialog<void>(
      context: context,
      builder: (_) => EditNoteDialog(
        savedDoubt: doubt,
        onSave: (notes, tags) async {
          await widget.service.updatePersonalNotes(doubt.id, notes);
          await widget.service.updateTags(doubt.id, tags);
        },
      ),
    );
  }

  Future<void> _removeDoubt(SavedDoubt doubt) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove from Knowledge Library?',
      message: 'This solution and its revision history will be removed from your device.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;

    await widget.service.unbookmark(doubt.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Removed from library.')));
  }

  void _reviseSingle(SavedDoubt doubt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RevisionSessionScreen(service: widget.service, deck: [doubt]),
      ),
    );
  }

  void _openDiscoverSolutionsModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DiscoverSolutionsSheet(api: widget.api, service: widget.service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doubts = widget.service.search(
      query: _searchController.text,
      tag: _selectedTag == 'all' ? null : _selectedTag,
    );
    final tags = widget.service.allTags;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Library'),
        actions: [
          IconButton(
            onPressed: _openDiscoverSolutionsModal,
            icon: const Icon(Icons.travel_explore_rounded),
            tooltip: 'Discover & add solutions',
          ),
        ],
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                pagePadding,
                pagePadding,
                pagePadding,
                8,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search questions, answers, notes, tags...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (tags.isNotEmpty) ...[
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: pagePadding),
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedTag == 'all',
                      onSelected: (_) => setState(() => _selectedTag = 'all'),
                    ),
                    const SizedBox(width: 8),
                    for (final tag in tags) ...[
                      FilterChip(
                        label: Text('#$tag'),
                        selected: _selectedTag == tag,
                        onSelected: (_) => setState(() => _selectedTag = tag),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: doubts.isEmpty
                  ? EmptyView(
                      icon: Icons.auto_stories_outlined,
                      title: widget.service.totalDoubtsCount == 0
                          ? 'Your Knowledge Library is empty'
                          : 'No matching solutions found',
                      message: widget.service.totalDoubtsCount == 0
                          ? 'Save solved doubts from mentor sessions or tap the discover icon above to add reference solutions.'
                          : 'Try modifying your search query or tag filter.',
                      actionLabel: widget.service.totalDoubtsCount == 0
                          ? 'Discover Solved Solutions'
                          : null,
                      onAction: widget.service.totalDoubtsCount == 0
                          ? _openDiscoverSolutionsModal
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(pagePadding),
                      itemCount: doubts.length,
                      itemBuilder: (context, index) {
                        final doubt = doubts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: itemGap),
                          child: SavedDoubtCard(
                            savedDoubt: doubt,
                            onEditNote: () => _openEditNoteDialog(doubt),
                            onRemove: () => _removeDoubt(doubt),
                            onRevise: () => _reviseSingle(doubt),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDiscoverSolutionsModal,
        icon: const Icon(Icons.bookmark_add_rounded),
        label: const Text('Add Solutions'),
      ),
    );
  }
}

class _DiscoverSolutionsSheet extends StatefulWidget {
  const _DiscoverSolutionsSheet({required this.api, required this.service});

  final ApiService api;
  final LearnService service;

  @override
  State<_DiscoverSolutionsSheet> createState() =>
      _DiscoverSolutionsSheetState();
}

class _DiscoverSolutionsSheetState extends State<_DiscoverSolutionsSheet> {
  final _queryController = TextEditingController();
  List<Doubt> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final res = await widget.api.searchSolvedDoubts(query);
      if (!mounted) return;
      setState(() {
        _results = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = 'Could not fetch solved doubts. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _toggleBookmark(Doubt doubt) async {
    final isSaved = widget.service.isBookmarked(doubt.id);
    if (isSaved) {
      await widget.service.unbookmarkByBackendId(doubt.id);
    } else {
      await widget.service.bookmark(doubt);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.travel_explore_rounded, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Discover Solved Solutions',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        hintText: 'Search by topic or question (e.g. Arrays, Async)...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _searching ? null : _search,
                    child: _searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Search'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _results.isEmpty && !_searching
                    ? const Center(
                        child: Text(
                          'Search for topics or questions to discover solved doubts and bookmark them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final doubt = _results[i];
                          final isSaved = widget.service.isBookmarked(doubt.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                doubt.question,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Topic: ${doubt.topic}',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (doubt.resolutionNotes != null &&
                                      doubt.resolutionNotes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      doubt.resolutionNotes!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_add_outlined,
                                  color: isSaved ? colors.primary : null,
                                ),
                                onPressed: () => _toggleBookmark(doubt),
                                tooltip: isSaved
                                    ? 'Remove bookmark'
                                    : 'Save to library',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
