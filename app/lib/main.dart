import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/user.dart';
import 'screens/mentor_portal_screen.dart';
import 'screens/portal_entry_screen.dart';
import 'screens/student_portal_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  final api = ApiService(http.Client());
  final authService = AuthService(api: api);
  runApp(DoubtQueueApp(api: api, authService: authService));
}

class DoubtQueueApp extends StatefulWidget {
  const DoubtQueueApp({
    super.key,
    required this.api,
    this.authService,
  });

  final ApiService api;
  final AuthService? authService;

  @override
  State<DoubtQueueApp> createState() => _DoubtQueueAppState();
}

class _DoubtQueueAppState extends State<DoubtQueueApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService(api: widget.api);
    _authService.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoubtQueue',
      theme: buildAppTheme(),
      home: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) {
          if (!_authService.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (!_authService.isAuthenticated) {
            return PortalEntryScreen(authService: _authService);
          }

          if (_authService.currentRole == UserRole.mentor) {
            return MentorPortalScreen(
              api: widget.api,
              authService: _authService,
            );
          }

          return StudentPortalScreen(
            api: widget.api,
            authService: _authService,
          );
        },
      ),
    );
  }
}
