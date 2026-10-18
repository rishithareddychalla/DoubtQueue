import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';

class PortalEntryScreen extends StatefulWidget {
  const PortalEntryScreen({
    super.key,
    required this.authService,
    this.initialRole = UserRole.student,
  });

  final AuthService authService;
  final UserRole initialRole;

  @override
  State<PortalEntryScreen> createState() => _PortalEntryScreenState();
}

class _PortalEntryScreenState extends State<PortalEntryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _portalTabController;

  // Student form controllers
  final _studentLoginFormKey = GlobalKey<FormState>();
  final _studentRegFormKey = GlobalKey<FormState>();
  final _studentLoginEmail = TextEditingController();
  final _studentLoginPassword = TextEditingController();
  final _studentRegName = TextEditingController();
  final _studentRegEmail = TextEditingController();
  final _studentRegDept =
      TextEditingController(text: 'Computer Science & Engineering');
  final _studentRegPassword = TextEditingController();
  bool _studentIsRegistering = false;

  // Mentor form controllers
  final _mentorLoginFormKey = GlobalKey<FormState>();
  final _mentorRegFormKey = GlobalKey<FormState>();
  final _mentorLoginEmail = TextEditingController();
  final _mentorLoginPassword = TextEditingController();
  final _mentorRegName = TextEditingController();
  final _mentorRegEmail = TextEditingController();
  final _mentorRegDept =
      TextEditingController(text: 'Computer Science & Engineering');
  final _mentorRegPassword = TextEditingController();
  final _mentorRegSecret =
      TextEditingController(text: 'MENTOR_SECRET_2026');
  bool _mentorIsRegistering = false;

  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _portalTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialRole == UserRole.mentor ? 1 : 0,
    );
    _portalTabController.addListener(() {
      if (!_portalTabController.indexIsChanging) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _portalTabController.dispose();
    _studentLoginEmail.dispose();
    _studentLoginPassword.dispose();
    _studentRegName.dispose();
    _studentRegEmail.dispose();
    _studentRegDept.dispose();
    _studentRegPassword.dispose();

    _mentorLoginEmail.dispose();
    _mentorLoginPassword.dispose();
    _mentorRegName.dispose();
    _mentorRegEmail.dispose();
    _mentorRegDept.dispose();
    _mentorRegPassword.dispose();
    _mentorRegSecret.dispose();
    super.dispose();
  }

  Future<void> _handleStudentLogin() async {
    if (!(_studentLoginFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.login(
        email: _studentLoginEmail.text,
        password: _studentLoginPassword.text,
        portalRole: UserRole.student,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleStudentRegister() async {
    if (!(_studentRegFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.register(
        name: _studentRegName.text,
        email: _studentRegEmail.text,
        password: _studentRegPassword.text,
        role: UserRole.student,
        department: _studentRegDept.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Registration failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleMentorLogin() async {
    if (!(_mentorLoginFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.login(
        email: _mentorLoginEmail.text,
        password: _mentorLoginPassword.text,
        portalRole: UserRole.mentor,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleMentorRegister() async {
    if (!(_mentorRegFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.register(
        name: _mentorRegName.text,
        email: _mentorRegEmail.text,
        password: _mentorRegPassword.text,
        role: UserRole.mentor,
        mentorSecret: _mentorRegSecret.text,
        department: _mentorRegDept.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Registration failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillStudentDemo() {
    _studentLoginEmail.text = 'student@doubtqueue.edu';
    _studentLoginPassword.text = 'Password123!';
    setState(() {});
  }

  void _fillMentorDemo() {
    _mentorLoginEmail.text = 'mentor@doubtqueue.edu';
    _mentorLoginPassword.text = 'Password123!';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Header logo / title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: pagePadding),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.queue_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DoubtQueue',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Office Hours & Doubt Resolution',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Portal tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: pagePadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _portalTabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade700,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.school_outlined, size: 20),
                        text: 'Student Portal',
                      ),
                      Tab(
                        icon: Icon(Icons.support_agent_rounded, size: 20),
                        text: 'Mentor Portal',
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _portalTabController,
                  children: [
                    _buildStudentPortalView(),
                    _buildMentorPortalView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentPortalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _studentIsRegistering ? 'Student Registration' : 'Student Login',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _studentIsRegistering = !_studentIsRegistering;
                  _errorMessage = null;
                }),
                child: Text(
                  _studentIsRegistering
                      ? 'Already have an account? Sign in'
                      : 'New student? Register',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_studentIsRegistering) ...[
            Form(
              key: _studentLoginFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _studentLoginEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Student Email *',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'e.g. student@doubtqueue.edu',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentLoginPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loading ? null : _handleStudentLogin,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: const Text('Sign In as Student'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _fillStudentDemo,
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: const Text('Fill Demo Student Credentials'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Form(
              key: _studentRegFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _studentRegName,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentRegEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentRegDept,
                    decoration: const InputDecoration(
                      labelText: 'Department / Major',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentRegPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password * (min 6 chars)',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loading ? null : _handleStudentRegister,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_rounded),
                    label: const Text('Register as Student'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMentorPortalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _mentorIsRegistering ? 'Mentor Provisioning' : 'Mentor Login',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _mentorIsRegistering = !_mentorIsRegistering;
                  _errorMessage = null;
                }),
                child: Text(
                  _mentorIsRegistering
                      ? 'Already authorized? Sign in'
                      : 'New mentor? Register',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_mentorIsRegistering) ...[
            Form(
              key: _mentorLoginFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _mentorLoginEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Mentor Email *',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'e.g. mentor@doubtqueue.edu',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mentorLoginPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loading ? null : _handleMentorLogin,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.admin_panel_settings_rounded),
                    label: const Text('Sign In as Mentor'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _fillMentorDemo,
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: const Text('Fill Demo Mentor Credentials'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Form(
              key: _mentorRegFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _mentorRegName,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mentorRegEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mentorRegDept,
                    decoration: const InputDecoration(
                      labelText: 'Department / Department Office',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mentorRegPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password * (min 6 chars)',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mentorRegSecret,
                    decoration: const InputDecoration(
                      labelText: 'Mentor Registration Secret *',
                      prefixIcon: Icon(Icons.security_rounded),
                      hintText: 'Enter authorized mentor key',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Mentor authorization key is required'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loading ? null : _handleMentorRegister,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.how_to_reg_rounded),
                    label: const Text('Provision Mentor Account'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
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
