import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  AuthService({required this.api});

  final ApiService api;

  static const _prefToken = 'auth_token';
  static const _prefUserId = 'auth_user_id';
  static const _prefUserName = 'auth_user_name';
  static const _prefUserEmail = 'auth_user_email';
  static const _prefUserRole = 'auth_user_role';
  static const _prefUserDept = 'auth_user_department';
  static const _prefUserStatus = 'auth_user_status';

  User? _currentUser;
  String? _token;
  bool _isInitialized = false;

  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isInitialized => _isInitialized;
  User? get currentUser => _currentUser;
  String? get token => _token;
  UserRole? get currentRole => _currentUser?.role;
  bool get isMentor => _currentUser?.isMentor ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_prefToken);
      final userId = prefs.getInt(_prefUserId);
      final userName = prefs.getString(_prefUserName);
      final userEmail = prefs.getString(_prefUserEmail);
      final userRole = prefs.getString(_prefUserRole);
      final userDept = prefs.getString(_prefUserDept);
      final userStatus = prefs.getString(_prefUserStatus);

      if (savedToken != null &&
          userId != null &&
          userName != null &&
          userEmail != null &&
          userRole != null) {
        _token = savedToken;
        api.setAuthToken(savedToken);
        _currentUser = User(
          id: userId,
          name: userName,
          email: userEmail,
          role: UserRole.fromString(userRole),
          department: userDept ?? 'Computer Science & Engineering',
          status: userStatus ?? 'ACTIVE',
        );

        // Verify token with backend
        try {
          final liveUser = await api.getMe();
          _currentUser = liveUser;
          await _persistUser(liveUser, savedToken);
        } on ApiException catch (e) {
          if (e.statusCode == 401) {
            await logout();
            return;
          }
        } catch (_) {}
      }
    } catch (_) {
      // In test or restricted environments, gracefully proceed
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required UserRole portalRole,
  }) async {
    final data = await api.login(
      email.trim(),
      password,
      portal: portalRole.apiValue,
    );
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    _token = token;
    _currentUser = user;
    api.setAuthToken(token);

    await _persistUser(user, token);
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? mentorSecret,
    String? department,
  }) async {
    final data = await api.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
      role: role.apiValue,
      mentorSecret: mentorSecret?.trim(),
      department: department?.trim(),
    );
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    _token = token;
    _currentUser = user;
    api.setAuthToken(token);

    await _persistUser(user, token);
    notifyListeners();
  }

  Future<void> updateLocalProfile({
    required String name,
    required String email,
    required String department,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: name.trim(),
      email: email.trim(),
      department: department.trim(),
    );
    if (_token != null) {
      await _persistUser(_currentUser!, _token!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}

    _token = null;
    _currentUser = null;
    api.setAuthToken(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefToken);
      await prefs.remove(_prefUserId);
      await prefs.remove(_prefUserName);
      await prefs.remove(_prefUserEmail);
      await prefs.remove(_prefUserRole);
      await prefs.remove(_prefUserDept);
      await prefs.remove(_prefUserStatus);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> _persistUser(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefToken, token);
      await prefs.setInt(_prefUserId, user.id);
      await prefs.setString(_prefUserName, user.name);
      await prefs.setString(_prefUserEmail, user.email);
      await prefs.setString(_prefUserRole, user.role.apiValue);
      await prefs.setString(_prefUserDept, user.department);
      await prefs.setString(_prefUserStatus, user.status);
    } catch (_) {}
  }
}
