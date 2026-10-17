import 'package:flutter/material.dart';

import '../learn/screens/learn_dashboard_screen.dart';
import '../learn/services/learn_service.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/session_filter.dart';
import '../widgets/content_width.dart';
import '../widgets/session_card.dart';
import '../widgets/state_views.dart';
import 'account_screen.dart';
import 'join_queue_screen.dart';
import 'mentor_screen.dart';

class SessionListScreen extends StatefulWidget {
  SessionListScreen({super.key, required this.api, LearnService? learnService})
    : learnService = learnService ?? LearnService();

  final ApiService api;
  final LearnService learnService;

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final _searchController = TextEditingController();
  List<Session> _sessions = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  SessionStatusFilter _statusFilter = SessionStatusFilter.open;
  SessionSort _sort = SessionSort.newest;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    widget.learnService.load();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _refreshing = true);
    try {
      final sessions = await widget.api.getSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _openJoin(Session session) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => JoinQueueScreen(
          api: widget.api,
          session: session,
          learnService: widget.learnService,
        ),
      ),
    );
    if (!mounted) return;
    _load();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildSessionsScaffold(),
          LearnDashboardScreen(service: widget.learnService, api: widget.api),
          MentorScreen(api: widget.api),
          AccountScreen(api: widget.api, learnService: widget.learnService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
          if (index == 0) {
            _load();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Mentor',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DoubtQueue'),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ContentWidth(
        child: _loading
            ? const LoadingView(message: 'Loading sessions...')
            : RefreshIndicator(onRefresh: _load, child: _buildList()),
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(pagePadding),
      children: [
        Text(
          'Join a mentor session and get help with your doubts.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: sectionGap),
        if (_error != null && _sessions.isEmpty)
          ErrorView(message: _error!, onRetry: _load)
        else ...[
          if (_error != null) ...[
            ErrorBanner(message: _error!, onRetry: _load),
            const SizedBox(height: itemGap),
          ],
          _buildControls(),
          const SizedBox(height: sectionGap),
          ..._buildResults(),
        ],
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by session or mentor name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
                  ),
          ),
        ),
        const SizedBox(height: itemGap),
        Wrap(
          spacing: 16,
          runSpacing: itemGap,
          children: [_buildStatusFilter(), _buildSortControl()],
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return SegmentedButton<SessionStatusFilter>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: SessionStatusFilter.open, label: Text('Open')),
        ButtonSegment(value: SessionStatusFilter.closed, label: Text('Closed')),
        ButtonSegment(value: SessionStatusFilter.all, label: Text('All')),
      ],
      selected: {_statusFilter},
      onSelectionChanged: (selection) {
        setState(() => _statusFilter = selection.first);
      },
    );
  }

  Widget _buildSortControl() {
    return SegmentedButton<SessionSort>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: SessionSort.newest, label: Text('Newest')),
        ButtonSegment(
          value: SessionSort.mostWaiting,
          label: Text('Most waiting'),
        ),
      ],
      selected: {_sort},
      onSelectionChanged: (selection) {
        setState(() => _sort = selection.first);
      },
    );
  }

  List<Widget> _buildResults() {
    final sessions = filterSessions(
      _sessions,
      query: _searchController.text,
      status: _statusFilter,
      sort: _sort,
    );

    if (sessions.isEmpty) {
      return [_buildEmptyState()];
    }

    return [
      for (final session in sessions) ...[
        SessionCard(session: session, onJoin: () => _openJoin(session)),
        const SizedBox(height: itemGap),
      ],
    ];
  }

  Widget _buildEmptyState() {
    if (_searchController.text.trim().isNotEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: 'No sessions match your search',
        message: 'Try a different session or mentor name.',
        actionLabel: 'Clear search',
        onAction: _clearSearch,
      );
    }

    if (_statusFilter == SessionStatusFilter.closed) {
      return const EmptyView(
        icon: Icons.lock_outline,
        title: 'No closed sessions',
        message: 'Sessions that have ended will appear here.',
      );
    }

    return EmptyView(
      icon: Icons.event_busy,
      title: 'No open sessions right now',
      message: 'Check again later or ask your mentor to start a session.',
      actionLabel: 'Refresh',
      onAction: _load,
    );
  }
}
