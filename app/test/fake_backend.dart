import 'dart:convert';

import 'package:doubtqueue/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A small in-memory copy of the DoubtQueue API for widget tests.
class FakeBackend {
  FakeBackend({List<Map<String, dynamic>>? sessions})
    : sessions = sessions ?? [openSession(1, 'PHP Basics Doubt Session')];

  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> doubts = [];
  final List<Map<String, dynamic>> users = [
    {
      'id': 1,
      'name': 'Arjun Sharma',
      'email': 'student@doubtqueue.edu',
      'password': 'Password123!',
      'role': 'STUDENT',
      'department': 'Computer Science & Engineering',
      'status': 'ACTIVE',
      'created_at': '2026-01-01 10:00:00',
    },
    {
      'id': 2,
      'name': 'Priya Sharma',
      'email': 'mentor@doubtqueue.edu',
      'password': 'Password123!',
      'role': 'MENTOR',
      'department': 'Computer Science & Engineering',
      'status': 'ACTIVE',
      'created_at': '2026-01-01 10:00:00',
    },
  ];
  bool failRequests = false;

  static Map<String, dynamic> openSession(
    int id,
    String title, {
    String mentor = 'Priya',
    String createdAt = '2026-01-01 10:00:00',
  }) {
    return {
      'id': id,
      'title': title,
      'mentor_name': mentor,
      'status': 'OPEN',
      'created_at': createdAt,
      'closed_at': null,
    };
  }

  late final MockClient client = MockClient(_handle);

  ApiService get api => ApiService(client, baseUrl: 'http://test.local');

  Map<String, dynamic> addDoubt(
    int sessionId,
    String name, {
    String status = 'WAITING',
    String? resolutionNotes,
  }) {
    final doubt = {
      'id': doubts.length + 1,
      'session_id': sessionId,
      'student_name': name,
      'student_email': '${name.toLowerCase()}@example.com',
      'topic': 'Arrays',
      'question': 'How do loops work for $name?',
      'status': status,
      'resolution_notes': resolutionNotes,
      'created_at': '2026-01-01 10:05:00',
      'started_at': null,
      'finished_at': null,
    };
    doubts.add(doubt);
    return doubt;
  }

  List<Map<String, dynamic>> _doubtsOf(int sessionId, String status) {
    return doubts
        .where((d) => d['session_id'] == sessionId && d['status'] == status)
        .toList();
  }

  Map<String, dynamic> _withPosition(Map<String, dynamic> doubt) {
    final waiting = _doubtsOf(doubt['session_id'] as int, 'WAITING');
    final isWaiting = doubt['status'] == 'WAITING';
    final session = sessions.firstWhere(
      (s) => s['id'] == doubt['session_id'],
      orElse: () => {'status': 'OPEN'},
    );
    return {
      ...doubt,
      'session_status': session['status'],
      'position': isWaiting ? waiting.indexOf(doubt) + 1 : null,
    };
  }

  Map<String, dynamic> _sessionJson(Map<String, dynamic> session) {
    final waiting = _doubtsOf(session['id'] as int, 'WAITING').length;
    return {...session, 'waiting_count': waiting};
  }

  http.Response _json(Object? body, [int status = 200]) {
    return http.Response(jsonEncode(body), status);
  }

  Future<http.Response> _handle(http.Request request) async {
    if (failRequests) {
      return _json({'status': 500, 'message': 'Something went wrong'}, 500);
    }

    final path = request.url.path;
    final method = request.method;

    if (path == '/api/auth/login' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final email = (body['email'] as String? ?? '').trim().toLowerCase();
      final password = body['password'] as String? ?? '';
      final portal = body['portal'] as String?;

      final user = users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => (u?['email'] as String).toLowerCase() == email,
        orElse: () => null,
      );

      if (user == null || user['password'] != password) {
        return _json({'status': 400, 'message': 'Invalid email or password'}, 400);
      }

      if (portal != null && portal.toUpperCase() != user['role']) {
        final roleLabel = user['role'] == 'MENTOR' ? 'Mentor' : 'Student';
        final portalLabel = user['role'] == 'MENTOR' ? 'Mentor Portal' : 'Student Portal';
        return _json({
          'status': 403,
          'message': 'Access denied: This account is registered as a $roleLabel. Please use the $portalLabel.',
        }, 403);
      }

      return _json({
        'token': 'fake_token_${user['id']}',
        'user': user,
      });
    }

    if (path == '/api/auth/register' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final email = (body['email'] as String? ?? '').trim().toLowerCase();
      final role = (body['role'] as String? ?? 'STUDENT').toUpperCase();

      if (role == 'MENTOR') {
        final secret = body['mentor_secret'] as String? ?? '';
        if (secret != 'MENTOR_SECRET_2026') {
          return _json({
            'status': 400,
            'message': 'Invalid mentor registration secret key. Mentor accounts require explicit authorization.',
          }, 400);
        }
      }

      if (users.any((u) => (u['email'] as String).toLowerCase() == email)) {
        return _json({'status': 400, 'message': 'An account with this email address already exists'}, 400);
      }

      final newUser = {
        'id': users.length + 1,
        'name': body['name'] ?? 'User',
        'email': email,
        'password': body['password'] ?? 'secret',
        'role': role,
        'department': body['department'] ?? 'Computer Science & Engineering',
        'status': 'ACTIVE',
        'created_at': '2026-01-01 10:00:00',
      };
      users.add(newUser);

      return _json({
        'token': 'fake_token_${newUser['id']}',
        'user': newUser,
      }, 201);
    }

    if (path == '/api/auth/me' && method == 'GET') {
      final auth = request.headers['authorization'] ?? '';
      if (auth.contains('fake_token_2')) {
        return _json({'user': users[1]});
      }
      return _json({'user': users[0]});
    }

    if (path == '/api/auth/logout' && method == 'POST') {
      return _json({'message': 'Logged out successfully'});
    }

    if (path == '/api/doubts/my' && method == 'GET') {
      return _json(doubts.map(_withPosition).toList());
    }

    if (path == '/api/sessions' && method == 'GET') {
      final status = request.url.queryParameters['status'];
      final list = sessions.where(
        (s) => status == null || s['status'] == status,
      );
      return _json(list.map(_sessionJson).toList());
    }

    if (path == '/api/sessions' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final session = {
        ...openSession(sessions.length + 1, body['title'] as String),
        'mentor_name': body['mentor_name'],
      };
      sessions.add(session);
      return _json(_sessionJson(session), 201);
    }

    if (path == '/api/doubts/search' && method == 'GET') {
      final query = (request.url.queryParameters['q'] ?? '').toLowerCase();
      final sessionId = request.url.queryParameters['session_id'];
      final tokens = query
          .split(RegExp(r'\s+'))
          .where((t) => t.length > 1)
          .toList();

      final matches = doubts
          .where((d) {
            if (d['status'] != 'SOLVED') return false;
            if (sessionId != null && '${d['session_id']}' != sessionId) {
              return false;
            }
            final topic = (d['topic'] as String? ?? '').toLowerCase();
            final question = (d['question'] as String? ?? '').toLowerCase();
            final notes = (d['resolution_notes'] as String? ?? '')
                .toLowerCase();
            if (tokens.isEmpty) {
              return topic.contains(query) ||
                  question.contains(query) ||
                  notes.contains(query);
            }
            return tokens.any(
              (t) =>
                  topic.contains(t) ||
                  question.contains(t) ||
                  notes.contains(t),
            );
          })
          .map((d) {
            return {
              'id': d['id'],
              'session_id': d['session_id'],
              'topic': d['topic'],
              'question': d['question'],
              'status': d['status'],
              'resolution_notes': d['resolution_notes'],
              'similarity_score': 0.85,
              'created_at': d['created_at'],
              'finished_at': d['finished_at'],
            };
          })
          .toList();
      return _json(matches);
    }

    final sessionMatch = RegExp(
      r'^/api/sessions/(\d+)/(doubts|current|queue|stats|intelligence|next|close)$',
    ).firstMatch(path);
    if (sessionMatch != null) {
      return _handleSession(
        int.parse(sessionMatch.group(1)!),
        sessionMatch.group(2)!,
        request,
      );
    }

    final doubtMatch = RegExp(r'^/api/doubts/(\d+)(/solved|/skipped)?$')
        .firstMatch(path);
    if (doubtMatch != null) {
      return _handleDoubt(
        int.parse(doubtMatch.group(1)!),
        doubtMatch.group(2),
        request,
      );
    }

    return _json({'status': 404, 'message': 'Route not found'}, 404);
  }

  http.Response _handleSession(int id, String action, http.Request request) {
    final session = sessions.firstWhere((s) => s['id'] == id);

    switch (action) {
      case 'doubts':
        if (session['status'] != 'OPEN') {
          return _json({
            'status': 409,
            'message': 'Session with id $id is closed',
          }, 409);
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final doubt = addDoubt(id, body['student_name'] as String);
        doubt['topic'] = body['topic'];
        doubt['question'] = body['question'];
        return _json(_withPosition(doubt), 201);
      case 'current':
        final active = _doubtsOf(id, 'IN_PROGRESS');
        return _json({
          'doubt': active.isEmpty ? null : _withPosition(active.first),
        });
      case 'queue':
        return _json(_doubtsOf(id, 'WAITING'));
      case 'stats':
        return _json({
          for (final s in ['WAITING', 'IN_PROGRESS', 'SOLVED', 'SKIPPED'])
            s: _doubtsOf(id, s).length,
        });
      case 'intelligence':
        final sessionDoubts = doubts
            .where((d) => d['session_id'] == id)
            .toList();
        final topicMap = <String, Map<String, dynamic>>{};
        for (final d in sessionDoubts) {
          final rawTopic = d['topic'] as String? ?? 'General';
          final norm = rawTopic.trim().toLowerCase();
          if (!topicMap.containsKey(norm)) {
            topicMap[norm] = {
              'topic': rawTopic,
              'normalized_topic': norm,
              'total_doubts': 0,
              'solved_count': 0,
              'skipped_count': 0,
              'waiting_count': 0,
              'in_progress_count': 0,
            };
          }
          final m = topicMap[norm]!;
          m['total_doubts'] = (m['total_doubts'] as int) + 1;
          final status = d['status'] as String? ?? 'WAITING';
          if (status == 'SOLVED') {
            m['solved_count'] = (m['solved_count'] as int) + 1;
          }
          if (status == 'SKIPPED') {
            m['skipped_count'] = (m['skipped_count'] as int) + 1;
          }
          if (status == 'WAITING') {
            m['waiting_count'] = (m['waiting_count'] as int) + 1;
          }
          if (status == 'IN_PROGRESS') {
            m['in_progress_count'] = (m['in_progress_count'] as int) + 1;
          }
        }

        final recurringTopics = topicMap.values.map((m) {
          final total = m['total_doubts'] as int;
          final skipped = m['skipped_count'] as int;
          final waiting = m['waiting_count'] as int;
          final unres = (skipped + waiting) / (total == 0 ? 1 : total);
          final isHotspot =
              (total >= 2 && (skipped >= 1 || unres >= 0.4)) || skipped >= 2;
          return {
            ...m,
            'unresolved_rate': double.parse(unres.toStringAsFixed(2)),
            'is_hotspot': isHotspot,
          };
        }).toList();

        final hotspots = recurringTopics
            .where((t) => t['is_hotspot'] == true)
            .toList();
        final topSolutions = sessionDoubts
            .where(
              (d) =>
                  d['status'] == 'SOLVED' &&
                  d['resolution_notes'] != null &&
                  (d['resolution_notes'] as String).isNotEmpty,
            )
            .take(5)
            .map(
              (d) => {
                'id': d['id'],
                'topic': d['topic'],
                'question': d['question'],
                'resolution_notes': d['resolution_notes'],
              },
            )
            .toList();

        return _json({
          'session_id': id,
          'session_title': session['title'],
          'total_topics': recurringTopics.length,
          'recurring_topics': recurringTopics,
          'hotspots': hotspots,
          'top_solutions': topSolutions,
        });
      case 'next':
        final active = _doubtsOf(id, 'IN_PROGRESS');
        if (active.isNotEmpty) {
          return _json({
            'status': 400,
            'message':
                'Cannot take next doubt while another doubt is in progress',
          }, 400);
        }
        final waiting = _doubtsOf(id, 'WAITING');
        if (waiting.isEmpty) {
          return _json({'status': 404, 'message': 'No waiting doubts'}, 404);
        }
        waiting.first['status'] = 'IN_PROGRESS';
        waiting.first['started_at'] = '2026-01-01 10:10:00';
        return _json(_withPosition(waiting.first));
      default:
        session['status'] = 'CLOSED';
        return _json(_sessionJson(session));
    }
  }

  http.Response _handleDoubt(int id, String? action, http.Request request) {
    final doubt = doubts.firstWhere((d) => d['id'] == id);
    if (action == '/solved') {
      doubt['status'] = 'SOLVED';
      if (request.body.isNotEmpty) {
        try {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['resolution_notes'] != null) {
            doubt['resolution_notes'] = body['resolution_notes'];
          }
        } catch (_) {}
      }
    }
    if (action == '/skipped') doubt['status'] = 'SKIPPED';
    return _json(_withPosition(doubt));
  }
}
