import 'package:flutter/material.dart';

import '../learn/services/learn_service.dart';
import '../models/doubt.dart';
import '../models/intelligence.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
import 'account_screen.dart';

class MentorPortalScreen extends StatefulWidget {
  MentorPortalScreen({
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
  State<MentorPortalScreen> createState() => _MentorPortalScreenState();
}

class _MentorPortalScreenState extends State<MentorPortalScreen> {
  late int _currentTab;

  List<Session> _sessions = [];
  int? _selectedSessionId;
  List<Doubt> _queue = [];
  Map<String, int> _stats = {};
  DoubtIntelligence? _intelligence;
  Doubt? _currentDoubt;

  bool _loading = true;
  bool _busy = false;
  String? _loadError;
  String? _actionError;
  String? _notice;

  Session? get _selectedSession {
    for (final s in _sessions) {
      if (s.id == _selectedSessionId) return s;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    widget.learnService.load();
    _loadMentorSessions();
  }

  Future<void> _loadMentorSessions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      // Filter sessions for the authenticated mentor
      final sessions = await widget.api.getSessions(mine: true);
      if (!mounted) return;

      setState(() {
        _sessions = sessions;
        if (sessions.isNotEmpty) {
          // Keep current selection if valid, otherwise pick first open or first session
          if (_selectedSessionId == null ||
              !sessions.any((s) => s.id == _selectedSessionId)) {
            final open = sessions.where((s) => s.isOpen);
            _selectedSessionId =
                open.isNotEmpty ? open.first.id : sessions.first.id;
          }
        } else {
          _selectedSessionId = null;
          _queue = [];
          _currentDoubt = null;
          _stats = {};
          _intelligence = null;
        }
      });

      if (_selectedSessionId != null) {
        await _loadSessionDetails(_selectedSessionId!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load mentor sessions.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSessionDetails(int sessionId) async {
    try {
      final queue = await widget.api.getQueue(sessionId);
      final stats = await widget.api.getStats(sessionId);
      final current = await widget.api.getCurrentDoubt(sessionId);
      final intel = await widget.api.getIntelligence(sessionId);

      if (!mounted) return;
      setState(() {
        _queue = queue;
        _stats = stats;
        _currentDoubt = current;
        _intelligence = intel;
        _actionError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    } catch (_) {}
  }

  Future<void> _selectSession(int id) async {
    setState(() => _selectedSessionId = id);
    await _loadSessionDetails(id);
  }

  Future<void> _handleStartSession(String title, String mentorName) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });

    try {
      final session = await widget.api.createSession(title, mentorName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session "${session.title}" started!')),
      );
      await _loadMentorSessions();
      setState(() => _selectedSessionId = session.id);
      await _loadSessionDetails(session.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleCloseSession() async {
    final session = _selectedSession;
    if (session == null) return;

    final confirmed = await confirmAction(
      context,
      title: 'End session?',
      message:
          'Closing "${session.title}" will prevent students from joining. In-progress doubts can still be finished.',
      confirmLabel: 'End session',
    );
    if (!confirmed || !mounted) return;


    setState(() {
      _busy = true;
      _actionError = null;
    });

    try {
      await widget.api.closeSession(session.id);
      if (!mounted) return;
      await _loadMentorSessions();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleTakeNext() async {
    final session = _selectedSession;
    if (session == null) return;

    setState(() {
      _busy = true;
      _actionError = null;
    });

    try {
      final nextDoubt = await widget.api.takeNext(session.id);
      if (!mounted) return;
      setState(() {
        _currentDoubt = nextDoubt;
        _notice = 'Calling ${nextDoubt.studentName}...';
      });
      await _loadSessionDetails(session.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleMarkSolved({String? resolutionNotes}) async {
    if (_currentDoubt == null) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });

    try {
      await widget.api.markSolved(
        _currentDoubt!.id,
        resolutionNotes: resolutionNotes,
      );
      if (!mounted) return;
      setState(() {
        _currentDoubt = null;
        _notice = 'Doubt resolved.';
      });
      if (_selectedSessionId != null) {
        await _loadSessionDetails(_selectedSessionId!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleSkip() async {
    if (_currentDoubt == null) return;

    final confirmed = await confirmAction(
      context,
      title: 'Skip this student?',
      message:
          'Skip ${_currentDoubt!.studentName} and continue to the next student?',
      confirmLabel: 'Skip doubt',
    );
    if (!confirmed || !mounted) return;


    setState(() {
      _busy = true;
      _actionError = null;
    });

    try {
      await widget.api.markSkipped(_currentDoubt!.id);
      if (!mounted) return;
      setState(() {
        _currentDoubt = null;
        _notice = 'Doubt skipped.';
      });
      if (_selectedSessionId != null) {
        await _loadSessionDetails(_selectedSessionId!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildMySessionsScaffold(),
          _buildLiveQueueScaffold(),
          _buildIntelligenceScaffold(),
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
          if (index == 0 || index == 1 || index == 2) {
            if (_selectedSessionId != null) {
              _loadSessionDetails(_selectedSessionId!);
            } else {
              _loadMentorSessions();
            }
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room_rounded),
            label: 'My Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Live Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Intelligence',
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

  // TAB 0: MY SESSIONS
  Widget _buildMySessionsScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor Portal • My Sessions'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadMentorSessions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ContentWidth(
        child: _loading
            ? const LoadingView(message: 'Loading mentor sessions...')
            : ListView(
                padding: const EdgeInsets.all(pagePadding),
                children: [
                  if (_loadError != null)
                    ErrorBanner(
                      message: _loadError!,
                      onRetry: _loadMentorSessions,
                    ),
                  CreateSessionCard(
                    onCreate: _handleStartSession,
                  ),

                  const SizedBox(height: sectionGap),
                  const SectionHeader(title: 'Sessions You Manage'),
                  const SizedBox(height: itemGap),
                  if (_sessions.isEmpty)
                    const EmptyView(
                      icon: Icons.history_edu_rounded,
                      title: 'No active sessions',
                      message: 'Start a new session above to open a doubt queue for students.',
                    )
                  else
                    ..._sessions.map((s) {
                      final isSelected = s.id == _selectedSessionId;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(cardRadius),
                          side: isSelected
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        margin: const EdgeInsets.only(bottom: itemGap),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  StatusBadge(status: s.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${s.waitingCount} student${s.waitingCount == 1 ? '' : 's'} waiting',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () {
                                      _selectSession(s.id);
                                      setState(() => _currentTab = 1); // Jump to queue
                                    },
                                    child: const Text('Manage Queue'),
                                  ),
                                  const Spacer(),
                                  if (s.isOpen)
                                    OutlinedButton(
                                      onPressed: _busy ? null : () {
                                        _selectSession(s.id);
                                        _handleCloseSession();
                                      },
                                      child: const Text('End Session'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  // TAB 1: LIVE QUEUE & ACTIVE DOUBT
  Widget _buildLiveQueueScaffold() {
    final session = _selectedSession;

    return Scaffold(
      appBar: AppBar(
        title: Text(session != null ? 'Queue: ${session.title}' : 'Live Queue'),
        actions: [
          IconButton(
            onPressed: (_selectedSessionId != null && !_busy)
                ? () => _loadSessionDetails(_selectedSessionId!)
                : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Queue',
          ),
        ],
      ),
      body: ContentWidth(
        child: session == null
            ? const EmptyView(
                icon: Icons.meeting_room_outlined,
                title: 'No session selected',
                message: 'Pick or start a session in My Sessions to manage its queue.',
              )
            : ListView(
                padding: const EdgeInsets.all(pagePadding),
                children: [
                  if (_actionError != null) ...[
                    ErrorBanner(
                      message: _actionError!,
                      onRetry: () => _loadSessionDetails(session.id),
                    ),
                    const SizedBox(height: itemGap),
                  ],
                  if (_notice != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _notice!,
                              style: TextStyle(color: Colors.green.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: itemGap),
                  ],
                  // Active Doubt Section
                  if (_currentDoubt != null)
                    CurrentDoubtCard(
                      doubt: _currentDoubt!,
                      busy: _busy,
                      onSolved: ([notes]) =>
                          _handleMarkSolved(resolutionNotes: notes),
                      onSkipped: _handleSkip,
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const EmptyView(
                              icon: Icons.support_agent_rounded,
                              title: 'No doubt is currently in progress.',
                              message: 'Take the next student when you are ready.',
                            ),
                            if (session.isOpen && _queue.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _busy ? null : _handleTakeNext,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Take next student'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: sectionGap),
                  // Waiting Queue Section
                  SectionHeader(
                    title: 'Waiting Queue (${_queue.length})',
                    trailing: (session.isOpen &&
                            _currentDoubt == null &&
                            _queue.isNotEmpty)
                        ? FilledButton.icon(
                            onPressed: _busy ? null : _handleTakeNext,
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Take Next Student'),
                          )
                        : null,
                  ),
                  const SizedBox(height: itemGap),
                  if (_queue.isEmpty)
                    const EmptyView(
                      icon: Icons.done_all_rounded,
                      title: 'Queue is clear',
                      message: 'No students waiting right now.',
                    )
                  else
                    for (var i = 0; i < _queue.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: itemGap),
                        child: QueueItemCard(
                          position: i + 1,
                          doubt: _queue[i],
                        ),
                      ),

                ],
              ),
      ),
    );
  }

  // TAB 2: INTELLIGENCE & ANALYTICS
  Widget _buildIntelligenceScaffold() {
    final session = _selectedSession;

    return Scaffold(
      appBar: AppBar(
        title: Text(session != null ? 'Insights: ${session.title}' : 'Insights'),
        actions: [
          IconButton(
            onPressed: (_selectedSessionId != null && !_busy)
                ? () => _loadSessionDetails(_selectedSessionId!)
                : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: ContentWidth(
        child: session == null
            ? const EmptyView(
                icon: Icons.analytics_outlined,
                title: 'No session selected',
                message: 'Select a session from My Sessions to see analytics.',
              )
            : ListView(
                padding: const EdgeInsets.all(pagePadding),
                children: [
                  const SectionHeader(title: 'Session Overview & Queue Statistics'),
                  const SizedBox(height: itemGap),
                  StatsRow(stats: _stats),
                  const SizedBox(height: sectionGap),
                  if (_intelligence != null) ...[
                    const SectionHeader(
                      title: 'Smart Topic Intelligence & Doubt Hotspots',
                    ),
                    const SizedBox(height: itemGap),
                    TopicIntelligenceCard(intelligence: _intelligence!),
                  ],
                ],
              ),
      ),
    );
  }
}
