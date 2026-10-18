import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learn/screens/knowledge_library_screen.dart';
import '../learn/screens/learning_progress_screen.dart';
import '../learn/services/learn_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/content_width.dart';
import '../widgets/section_header.dart';

import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.api,
    required this.learnService,
    this.authService,
  });

  final ApiService api;
  final LearnService learnService;
  final AuthService? authService;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}


class _AccountScreenState extends State<AccountScreen> {
  static const _prefLoggedInKey = 'account_is_logged_in';
  static const _prefNameKey = 'account_student_name';
  static const _prefEmailKey = 'account_student_email';
  static const _prefDeptKey = 'account_department';
  static const _prefRoleKey = 'account_role';
  static const _prefRememberKey = 'account_remember_details';

  bool _isLoggedIn = true;
  String _studentName = 'Arjun Sharma';
  String _studentEmail = 'arjun.sharma@doubtqueue.edu';
  String _department = 'Computer Science & Engineering';
  String _role = 'Student';
  bool _rememberDetails = true;
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    widget.learnService.addListener(_onServiceChanged);
    _loadPreferences();
  }

  @override
  void dispose() {
    widget.learnService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPreferences() async {
    if (widget.authService?.currentUser != null) {
      final user = widget.authService!.currentUser!;
      if (!mounted) return;
      setState(() {
        _isLoggedIn = true;
        _studentName = user.name;
        _studentEmail = user.email;
        _department = user.department;
        _role = user.isMentor ? 'Mentor' : 'Student';
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = prefs.getBool(_prefLoggedInKey) ?? true;
        _studentName = prefs.getString(_prefNameKey) ?? 'Arjun Sharma';
        _studentEmail =
            prefs.getString(_prefEmailKey) ?? 'arjun.sharma@doubtqueue.edu';
        _department =
            prefs.getString(_prefDeptKey) ?? 'Computer Science & Engineering';
        _role = prefs.getString(_prefRoleKey) ?? 'Student';
        _rememberDetails = prefs.getBool(_prefRememberKey) ?? true;
      });
    } catch (_) {
      // In tests or if SharedPreferences is unavailable, keep defaults.
    }
  }


  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoggedInKey, _isLoggedIn);
      await prefs.setString(_prefNameKey, _studentName);
      await prefs.setString(_prefEmailKey, _studentEmail);
      await prefs.setString(_prefDeptKey, _department);
      await prefs.setString(_prefRoleKey, _role);
      await prefs.setBool(_prefRememberKey, _rememberDetails);
    } catch (_) {}
  }

  void _openEditProfileDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: _studentName);
    final emailCtrl = TextEditingController(text: _studentEmail);
    final deptCtrl = TextEditingController(text: _department);
    String selectedRole = _role;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 24),
              SizedBox(width: 8),
              Text('Edit Profile'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter an email address';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Department / Major',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'Teaching Assistant',
                        child: Text('Teaching Assistant'),
                      ),
                      DropdownMenuItem(
                        value: 'Peer Mentor',
                        child: Text('Peer Mentor'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  setState(() {
                    _studentName = nameCtrl.text.trim();
                    _studentEmail = emailCtrl.text.trim();
                    _department = deptCtrl.text.trim().isNotEmpty
                        ? deptCtrl.text.trim()
                        : 'Computer Science & Engineering';
                    _role = selectedRole;
                  });
                  _savePreferences();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully.'),
                      ),
                    );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _openLoginDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: _studentName);
    final emailCtrl = TextEditingController(text: _studentEmail);
    final deptCtrl = TextEditingController(text: _department);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login_rounded, size: 24),
            SizedBox(width: 8),
            Text('Sign In to DoubtQueue'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your student credentials to join queues and track doubts.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Student Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!val.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department / Major',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text(
                      'Use Demo Student',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      nameCtrl.text = 'Arjun Sharma';
                      emailCtrl.text = 'arjun.sharma@doubtqueue.edu';
                      deptCtrl.text = 'Computer Science & Engineering';
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                setState(() {
                  _isLoggedIn = true;
                  _studentName = nameCtrl.text.trim();
                  _studentEmail = emailCtrl.text.trim();
                  if (deptCtrl.text.trim().isNotEmpty) {
                    _department = deptCtrl.text.trim();
                  }
                });
                _savePreferences();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('Welcome back, $_studentName!')),
                  );
              }
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await confirmAction(
      context,
      title: 'Log Out of DoubtQueue?',
      message: 'Are you sure you want to log out? Your local learning progress, notes, and revision history will remain safe on this device.',
      confirmLabel: 'Log Out',
    );
    if (!confirmed) return;

    if (widget.authService != null) {
      await widget.authService!.logout();
    }

    setState(() {
      _isLoggedIn = false;
    });
    await _savePreferences();


    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('You have been logged out.')),
      );
  }

  Future<void> _checkServerHealth() async {
    if (_isTestingConnection) return;
    setState(() => _isTestingConnection = true);

    try {
      final sessions = await widget.api.getSessions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF166534),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected to backend: ${sessions.length} sessions retrieved successfully.',
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF991B1B),
          content: Text('Server connection failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  void _openAboutProjectDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text('About DoubtQueue'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DoubtQueue is an open-source peer-to-peer queue management and learning assistant system for university lab sessions and office hours.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Core Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text('• Real-time doubt registration and mentor dispatch'),
              Text('• Smart solution suggester with live query similarity'),
              Text('• Student self-resolution using verified mentor solutions'),
              Text('• Leitner spaced repetition for long-term retention'),
              Text('• Local-first knowledge library and personal notes'),
              SizedBox(height: 12),
              Text(
                'Architecture:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                '• Frontend: Flutter 3 (Cross-platform Desktop, Web, Mobile)',
              ),
              Text('• Backend: PHP 8.2 + MySQL / MariaDB REST API'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLearnData() async {
    final confirmed = await confirmAction(
      context,
      title: 'Clear Local Learn Data?',
      message: 'This will remove all saved solutions, personal notes, and spaced repetition history stored on this device.',
      confirmLabel: 'Clear Data',
    );
    if (!confirmed) return;

    for (final doubt in widget.learnService.allSavedDoubts) {
      await widget.learnService.unbookmark(doubt.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local learning data cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totalSaved = widget.learnService.totalDoubtsCount;
    final mastered = widget.learnService.masteredCount;
    final due = widget.learnService.dueCount;
    final sessionsCount = widget.learnService.allSessions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: _openEditProfileDialog,
            ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(pagePadding),
          children: [
            // Profile / Authentication Card
            _buildProfileSection(theme, colors),
            const SizedBox(height: sectionGap),

            // Learning Overview
            const SectionHeader(
              title: 'Learning & Doubts Overview',
              subtitle: 'Activity tracked locally on this device',
            ),
            const SizedBox(height: itemGap),
            Row(
              children: [
                _buildStatTile(
                  'Saved',
                  '$totalSaved',
                  Icons.bookmark_added_rounded,
                  colors.primary,
                ),
                const SizedBox(width: 10),
                _buildStatTile(
                  'Mastered',
                  '$mastered',
                  Icons.verified_rounded,
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 10),
                _buildStatTile(
                  'Due',
                  '$due',
                  Icons.timer_outlined,
                  const Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                _buildStatTile(
                  'Reviews',
                  '$sessionsCount',
                  Icons.repeat_rounded,
                  const Color(0xFF6366F1),
                ),
              ],
            ),
            const SizedBox(height: sectionGap),

            // Quick Learn Links
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: itemGap),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.auto_stories_outlined,
                      color: Color(0xFF0F766E),
                    ),
                    title: const Text('Knowledge Library'),
                    subtitle: const Text(
                      'Browse bookmarked solutions and personal notes',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => KnowledgeLibraryScreen(
                            service: widget.learnService,
                            api: widget.api,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF0284C7),
                    ),
                    title: const Text('Learning Analytics & Progress'),
                    subtitle: const Text(
                      'Mastery breakdown, revision logs and Leitner schedule',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LearningProgressScreen(
                            service: widget.learnService,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: sectionGap),

            // Preferences & Storage
            const SectionHeader(title: 'Preferences & System'),
            const SizedBox(height: itemGap),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.save_outlined),
                    title: const Text('Remember My Info'),
                    subtitle: const Text(
                      'Autofill name & email when joining session queues',
                    ),
                    value: _rememberDetails,
                    onChanged: (val) {
                      setState(() => _rememberDetails = val);
                      _savePreferences();
                    },
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.security_outlined),
                    title: Text('Privacy & Local Storage'),
                    subtitle: Text(
                      'Personal notes & Leitner history are saved only on your device',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Clear Local Learning Data',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                      'Erase saved doubts and review logs from device',
                    ),
                    onTap: _clearLearnData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: sectionGap),

            // About Section
            const SectionHeader(
              title: 'About DoubtQueue',
              subtitle: 'Application details, backend status, and licenses',
            ),
            const SizedBox(height: itemGap),
            Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: colors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DoubtQueue',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'v1.0.0 (GSoC Edition)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Peer-to-peer queue management, smart solution suggestions, and interactive Leitner spaced-repetition learning for computer science lab sessions.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Backend API Server'),
                    subtitle: Text(
                      widget.api.baseUrl,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: _isTestingConnection
                          ? null
                          : _checkServerHealth,
                      icon: _isTestingConnection
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check_rounded, size: 16),
                      label: const Text('Test', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Project Overview'),
                    subtitle: const Text('Features & architecture information'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: _openAboutProjectDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Open Source Licenses'),
                    subtitle: const Text('View software credits and licenses'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'DoubtQueue',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme, ColorScheme colors) {
    if (_isLoggedIn) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colors.primary.withValues(alpha: 0.15),
                    child: Text(
                      _studentName.isNotEmpty
                          ? _studentName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _studentEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _department,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_role • Active',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openEditProfileDialog,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                        side: BorderSide(
                          color: colors.error.withValues(alpha: 0.5),
                        ),
                      ),
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Guest / Logged Out View
    return Card(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFE2E8F0),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 32,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest Account',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Not signed in • Offline Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Guest Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in to sync your profile details, auto-fill queue submissions, and interact with mentor sessions.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openLoginDialog,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign In / Log In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
