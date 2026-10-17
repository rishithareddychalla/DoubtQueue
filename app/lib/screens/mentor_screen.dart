import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../models/intelligence.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/content_width.dart';
import '../widgets/create_session_card.dart';
import '../widgets/current_doubt_card.dart';
import '../widgets/queue_item_card.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';
import '../widgets/stats_row.dart';
import '../widgets/status_badge.dart';
import '../widgets/topic_intelligence_card.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Session> _sessions = [];
  int? _selectedId;
  List<Doubt> _queue = [];
  Map<String, int> _stats = {};
  DoubtIntelligence? _intelligence;
  Doubt? _current;

  bool _loading = true;
  bool _busy = false;
  String? _loadError;
  String? _actionError;
  String? _notice;

  int _tabIndex = 0;

  Session? get _selected {
    for (final session in _sessions) {
      if (session.id == _selectedId) return session;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabControllerChanged);
    _loadFirstTime();
  }

  void _onTabControllerChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabIndex != _tabController.index) {
      setState(() {
        _tabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_tabIndex != index) {
      setState(() => _tabIndex = index);
    }
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  Future<void> _loadFirstTime() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _loadSessions();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _actionError = null;
      _notice = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _loadSessions({int? selectId}) async {
    final sessions = await widget.api.getSessions(status: 'OPEN');
    final wanted = selectId ?? _selectedId;
    final stillOpen = sessions.any((s) => s.id == wanted);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _selectedId = stillOpen
          ? wanted
          : (sessions.isNotEmpty ? sessions.first.id : null);
      if (_selectedId == null) {
        _tabIndex = 1;
        if (_tabController.index != 1) {
          _tabController.index = 1;
        }
      }
    });
    if (_selectedId != null) {
      await _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    final id = _selectedId!;
    final current = await widget.api.getCurrentDoubt(id);
    final queue = await widget.api.getQueue(id);
    final stats = await widget.api.getStats(id);
    DoubtIntelligence? intelligence;
    try {
      intelligence = await widget.api.getIntelligence(id);
    } catch (_) {
      // Non-blocking background fetch
    }
    if (!mounted) return;
    setState(() {
      _current = current;
      _queue = queue;
      _stats = stats;
      _intelligence = intelligence;
    });
  }

  Future<void> _createSession(String title, String mentorName) async {
    final session = await widget.api.createSession(title, mentorName);
    setState(() {
      _current = null;
      _intelligence = null;
      _switchTab(0);
    });
    await _loadSessions(selectId: session.id);
  }

  Future<void> _selectSession(int? id) async {
    if (id == null || id == _selectedId) return;
    setState(() {
      _selectedId = id;
      _current = null;
      _queue = [];
      _stats = {};
      _intelligence = null;
      _switchTab(0);
    });
    await _run(_loadDetails);
  }

  Future<void> _takeNext() async {
    await _run(() async {
      final doubt = await widget.api.takeNext(_selectedId!);
      setState(() => _current = doubt);
      await _loadDetails();
    });
  }

  Future<void> _markSolved([String? notes]) async {
    final id = _current!.id;
    await _run(() async {
      await widget.api.markSolved(id, resolutionNotes: notes);
      setState(() => _current = null);
      await _loadDetails();
    });
  }

  Future<void> _skip() async {
    final confirmed = await confirmAction(
      context,
      title: 'Skip this doubt?',
      message: 'The student will see that their doubt was skipped.',
      confirmLabel: 'Skip doubt',
    );
    if (!confirmed) return;

    final id = _current!.id;
    await _run(() async {
      await widget.api.markSkipped(id);
      setState(() => _current = null);
      await _loadDetails();
    });
  }

  Future<void> _closeSession() async {
    final confirmed = await confirmAction(
      context,
      title: 'Close this session?',
      message: 'Students will not be able to join it any more.',
      confirmLabel: 'Close session',
    );
    if (!confirmed) return;

    final title = _selected?.title ?? 'Session';
    await _run(() async {
      await widget.api.closeSession(_selectedId!);
      _current = null;
      await _loadSessions();
      setState(() {
        _notice = '$title was closed.';
        _switchTab(1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor dashboard'),
        actions: [
          IconButton(
            onPressed: _busy || _loading ? null : () => _run(_loadSessions),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: _switchTab,
          indicatorColor: colors.primary,
          indicatorWeight: 3,
          labelColor: colors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: _queue.isNotEmpty,
                label: Text('${_queue.length}'),
                child: Icon(
                  _tabIndex == 0
                      ? Icons.people_rounded
                      : Icons.people_outline_rounded,
                  size: 20,
                ),
              ),
              text: 'Queue',
            ),
            Tab(
              icon: Icon(
                _tabIndex == 1
                    ? Icons.insights_rounded
                    : Icons.insights_outlined,
                size: 20,
              ),
              text: 'Session & Stats',
            ),
          ],
        ),
      ),
      body: ContentWidth(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Loading dashboard...');
    }
    if (_loadError != null) {
      return ErrorView(message: _loadError!, onRetry: _loadFirstTime);
    }

    return Column(
      children: [
        if (_busy)
          const SizedBox(height: 3, child: LinearProgressIndicator())
        else
          const SizedBox(height: 3),
        if (_actionError != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: pagePadding,
              vertical: 6,
            ),
            child: ErrorBanner(message: _actionError!),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: pagePadding,
              vertical: 6,
            ),
            child: SuccessBanner(message: _notice!),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildQueueTab(), _buildSessionAndStatsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildQueueTab() {
    final session = _selected;

    if (session == null) {
      return ListView(
        padding: const EdgeInsets.all(pagePadding),
        children: [
          Card(
            child: EmptyView(
              icon: Icons.meeting_room_outlined,
              title: 'No active session selected',
              message: 'Select an open session or create a new one to manage the doubt queue.',
              actionLabel: 'Go to Session & Stats',
              onAction: () => _switchTab(1),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(pagePadding),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hub_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: session.status),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        ..._buildCurrentSection(),
        const SizedBox(height: sectionGap),
        ..._buildQueueSection(),
      ],
    );
  }

  Widget _buildSessionAndStatsTab() {
    final session = _selected;

    return ListView(
      padding: const EdgeInsets.all(pagePadding),
      children: [
        CreateSessionCard(onCreate: _createSession),
        const SizedBox(height: sectionGap),
        const SectionHeader(title: 'Session'),
        const SizedBox(height: itemGap),
        if (_sessions.isEmpty)
          const Card(
            child: EmptyView(
              icon: Icons.event_busy,
              title: 'No open sessions',
              message: 'Start a session above to open a queue for students.',
            ),
          )
        else
          _buildSessionPicker(),
        if (session != null) ...[
          const SizedBox(height: sectionGap),
          const SectionHeader(title: 'Statistics'),
          const SizedBox(height: itemGap),
          StatsRow(stats: _stats),
          if (_intelligence != null) ...[
            const SizedBox(height: sectionGap),
            const SectionHeader(title: 'Doubt Intelligence'),
            const SizedBox(height: itemGap),
            TopicIntelligenceCard(intelligence: _intelligence!),
          ],
        ],
      ],
    );
  }

  Widget _buildSessionPicker() {
    final session = _selected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session != null) ...[
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.hub_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: session.status),
                ],
              ),
              const SizedBox(height: 14),
            ],
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Open session',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedId,
                  isExpanded: true,
                  hint: const Text('Select a session'),
                  items: [
                    for (final item in _sessions)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.title} (${item.mentorName})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                  onChanged: _busy ? null : _selectSession,
                ),
              ),
            ),
            if (session != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _closeSession,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE11D48),
                      side: const BorderSide(
                        color: Color(0xFFFECDD3),
                        width: 1.2,
                      ),
                    ),
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: const Text('Close session'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCurrentSection() {
    final current = _current;

    return [
      const SectionHeader(title: 'Current doubt'),
      const SizedBox(height: itemGap),
      if (current != null)
        CurrentDoubtCard(
          doubt: current,
          busy: _busy,
          onSolved: _markSolved,
          onSkipped: _skip,
        )
      else
        _buildNoCurrentDoubt(),
    ];
  }

  Widget _buildNoCurrentDoubt() {
    final hasWaiting = _queue.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: hasWaiting
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: hasWaiting ? 1.6 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const EmptyView(
              icon: Icons.support_agent_rounded,
              title: 'No doubt is currently in progress.',
              message: 'Take the next student when you are ready.',
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy || !hasWaiting ? null : _takeNext,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Take next student'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQueueSection() {
    return [
      SectionHeader(
        title: 'Waiting queue',
        subtitle: '${_queue.length} waiting',
        trailing: TextButton.icon(
          onPressed: _busy ? null : () => _run(_loadDetails),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ),
      const SizedBox(height: itemGap),
      if (_queue.isEmpty)
        const Card(
          child: EmptyView(
            icon: Icons.groups_outlined,
            title: 'No students are waiting.',
            message: 'New questions will appear here when students join.',
          ),
        )
      else
        for (var i = 0; i < _queue.length; i++) ...[
          QueueItemCard(position: i + 1, doubt: _queue[i]),
          const SizedBox(height: itemGap),
        ],
    ];
  }
}
