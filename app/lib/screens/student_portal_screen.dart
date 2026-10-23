import 'package:flutter/material.dart';

import '../learn/screens/learn_dashboard_screen.dart';
import '../learn/services/learn_service.dart';
import '../models/doubt.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/session_filter.dart';
import '../utils/time_format.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/content_width.dart';
import '../widgets/session_card.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';
import 'account_screen.dart';
import 'join_queue_screen.dart';
import 'my_doubt_screen.dart';

class StudentPortalScreen extends StatefulWidget {
  StudentPortalScreen({
    super.key,
    required this.api,
    required this.authService,
    LearnService? learnService,
    this.initialTab = 0,
  }) : learnService = learnService ?? LearnService();

  final ApiService api;
  final AuthService authService;
  final LearnService learnService;
  final int initialTab;

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  late int _currentTab;

  // Sessions tab state
  final _searchController = TextEditingController();
  List<Session> _sessions = [];
  bool _sessionsLoading = true;
  bool _sessionsRefreshing = false;
  String? _sessionsError;
  SessionStatusFilter _statusFilter = SessionStatusFilter.open;
  SessionSort _sort = SessionSort.newest;

  // My Doubts tab state
  List<Doubt> _myDoubts = [];
  bool _doubtsLoading = true;
  bool _doubtsRefreshing = false;
  String? _doubtsError;
  String _doubtFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    widget.learnService.load();
    _loadSessions();
    _loadMyDoubts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _sessionsRefreshing = true);
    try {
      final sessions = await widget.api.getSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _sessionsError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sessionsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sessionsError = 'Could not load sessions.');
    } finally {
      if (mounted) {
        setState(() {
          _sessionsLoading = false;
          _sessionsRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadMyDoubts() async {
    setState(() => _doubtsRefreshing = true);
    try {
      final doubts = await widget.api.getMyDoubts();
      if (!mounted) return;
      setState(() {
        _myDoubts = doubts;
        _doubtsError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _doubtsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _doubtsError = 'Could not load your doubts.');
    } finally {
      if (mounted) {
        setState(() {
          _doubtsLoading = false;
          _doubtsRefreshing = false;
        });
      }
    }
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
    _loadSessions();
    _loadMyDoubts();
  }

  Future<void> _selfResolveDoubt(Doubt doubt) async {
    final confirmed = await confirmAction(
      context,
      title: 'Self-Resolve Doubt',
      message: 'Did you solve this question yourself?',
      confirmLabel: 'Mark Solved',
    );

    if (!confirmed || !mounted) return;

    try {
      await widget.api.markSolved(doubt.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doubt marked as solved!')),
      );
      _loadMyDoubts();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildSessionsScaffold(),
          _buildMyDoubtsScaffold(),
          LearnDashboardScreen(
            service: widget.learnService,
            api: widget.api,
          ),
          AccountScreen(
            api: widget.api,
            learnService: widget.learnService,
            authService: widget.authService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
          if (index == 0) _loadSessions();
          if (index == 1) _loadMyDoubts();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: 'My Doubts',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Learn',
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

  // SESSIONS TAB
  Widget _buildSessionsScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Portal • Sessions'),
        actions: [
          IconButton(
            onPressed: _sessionsRefreshing ? null : _loadSessions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh sessions',
          ),
        ],
      ),
      body: ContentWidth(
        child: _sessionsLoading
            ? const LoadingView(message: 'Loading available sessions...')
            : RefreshIndicator(
                onRefresh: _loadSessions,
                child: _buildSessionsList(),
              ),
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(pagePadding),
      children: [
        Text(
          'Join open mentor sessions and get real-time assistance with your questions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: sectionGap),
        if (_sessionsError != null && _sessions.isEmpty)
          ErrorView(message: _sessionsError!, onRetry: _loadSessions)
        else ...[
          if (_sessionsError != null) ...[
            ErrorBanner(message: _sessionsError!, onRetry: _loadSessions),
            const SizedBox(height: itemGap),
          ],
          _buildSessionControls(),
          const SizedBox(height: sectionGap),
          ..._buildSessionResults(),
        ],
      ],
    );
  }

  Widget _buildSessionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by session topic or mentor name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: itemGap),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: const Text('Open'),
                    selected: _statusFilter == SessionStatusFilter.open,
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = SessionStatusFilter.open);
                    },
                  ),
                  FilterChip(
                    label: const Text('Closed'),
                    selected: _statusFilter == SessionStatusFilter.closed,
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = SessionStatusFilter.closed);
                    },
                  ),
                  FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == SessionStatusFilter.all,
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = SessionStatusFilter.all);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<SessionSort>(
              initialValue: _sort,
              tooltip: 'Sort sessions',
              icon: const Icon(Icons.sort_rounded),
              onSelected: (sort) => setState(() => _sort = sort),
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: SessionSort.newest,
                  child: Text('Newest first'),
                ),
                PopupMenuItem(
                  value: SessionSort.mostWaiting,
                  child: Text('Most waiting'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildSessionResults() {
    final filtered = filterSessions(
      _sessions,
      query: _searchController.text,
      status: _statusFilter,
      sort: _sort,
    );

    if (filtered.isEmpty) {
      return [
        const EmptyView(
          icon: Icons.meeting_room_outlined,
          title: 'No sessions found',
          message: 'There are currently no sessions matching your filter.',
        ),
      ];
    }

    return filtered.map((session) {
      return Padding(
        padding: const EdgeInsets.only(bottom: itemGap),
        child: SessionCard(
          session: session,
          onJoin: () => _openJoin(session),
        ),

      );
    }).toList();
  }

  // MY DOUBTS TAB
  Widget _buildMyDoubtsScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Doubts & Queue Status'),
        actions: [
          IconButton(
            onPressed: _doubtsRefreshing ? null : _loadMyDoubts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh my doubts',
          ),
        ],
      ),
      body: ContentWidth(
        child: _doubtsLoading
            ? const LoadingView(message: 'Loading your submitted doubts...')
            : RefreshIndicator(
                onRefresh: _loadMyDoubts,
                child: _buildMyDoubtsList(),
              ),
      ),
    );
  }

  Widget _buildMyDoubtsList() {
    final filtered = _myDoubts.where((d) {
      if (_doubtFilter == 'WAITING') return d.isWaiting;
      if (_doubtFilter == 'IN_PROGRESS') return d.isInProgress;
      if (_doubtFilter == 'SOLVED') return d.isSolved;
      if (_doubtFilter == 'SKIPPED') return d.isSkipped;
      return true;
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(pagePadding),
      children: [
        Text(
          'Track the status of your questions, live queue position, and mentor resolution notes.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _doubtFilter == 'ALL',
              onSelected: (val) {
                if (val) setState(() => _doubtFilter = 'ALL');
              },
            ),
            ChoiceChip(
              label: const Text('Waiting'),
              selected: _doubtFilter == 'WAITING',
              onSelected: (val) {
                if (val) setState(() => _doubtFilter = 'WAITING');
              },
            ),
            ChoiceChip(
              label: const Text('In Progress'),
              selected: _doubtFilter == 'IN_PROGRESS',
              onSelected: (val) {
                if (val) setState(() => _doubtFilter = 'IN_PROGRESS');
              },
            ),
            ChoiceChip(
              label: const Text('Solved'),
              selected: _doubtFilter == 'SOLVED',
              onSelected: (val) {
                if (val) setState(() => _doubtFilter = 'SOLVED');
              },
            ),
          ],
        ),
        const SizedBox(height: sectionGap),
        if (_doubtsError != null && _myDoubts.isEmpty)
          ErrorView(message: _doubtsError!, onRetry: _loadMyDoubts)
        else if (filtered.isEmpty)
          const EmptyView(
            icon: Icons.help_outline_rounded,
            title: 'No doubts recorded',
            message: 'You have not submitted any doubts in this category yet. Join an open session to ask a doubt!',
          )
        else
          ...filtered.map(_buildDoubtCard),
      ],
    );
  }

  Widget _buildDoubtCard(Doubt doubt) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: itemGap),
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => MyDoubtScreen(
                api: widget.api,
                doubt: doubt,
                learnService: widget.learnService,
              ),
            ),
          );
          _loadMyDoubts();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doubt.topic,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (doubt.sessionTitle != null || doubt.mentorName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Session: ${doubt.sessionTitle ?? 'Office Hours'} (Mentor: ${doubt.mentorName ?? 'Assigned'})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: doubt.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                doubt.question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              // Status specifics
              if (doubt.isWaiting) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          doubt.position != null
                              ? 'Queue Position: #${doubt.position} (${doubt.studentsAhead} ahead)'
                              : 'Waiting in queue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => _selfResolveDoubt(doubt),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 26),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Self-resolved?'),
                      ),
                    ],
                  ),
                ),
              ],
              if (doubt.isInProgress) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Currently being assisted by mentor!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (doubt.resolutionNotes != null && doubt.resolutionNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Mentor Resolution Notes:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doubt.resolutionNotes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doubt.createdAt != null
                          ? 'Asked ${timeAgo(doubt.createdAt)}'
                          : '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to view tracking >',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
