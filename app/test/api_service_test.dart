import 'dart:convert';

import 'package:doubtqueue/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const baseUrl = 'http://test.local';

  test('getSessions returns sessions from the API', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/sessions?status=OPEN');
      return http.Response(
        jsonEncode([
          {
            'id': 1,
            'title': 'PHP Basics Doubt Session',
            'mentor_name': 'Priya',
            'status': 'OPEN',
            'waiting_count': 5,
          },
        ]),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final sessions = await api.getSessions(status: 'OPEN');

    expect(sessions, hasLength(1));
    expect(sessions.first.title, 'PHP Basics Doubt Session');
    expect(sessions.first.waitingCount, 5);
  });

  test('a network failure throws a friendly message', () async {
    final client = MockClient((request) async {
      throw http.ClientException('connection refused');
    });
    final api = ApiService(client, baseUrl: baseUrl);

    expect(
      api.getSessions(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Could not reach the server'),
        ),
      ),
    );
  });

  test('getSessions without a status asks for every session', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/sessions');
      return http.Response('[]', 200);
    });
    final api = ApiService(client, baseUrl: baseUrl);

    expect(await api.getSessions(), isEmpty);
  });

  test('a 409 response throws an exception with the API message', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'status': 409, 'message': 'Session with id 2 is closed'}),
        409,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    expect(
      api.joinSession(
        2,
        name: 'Asha',
        email: 'asha@example.com',
        topic: 'Arrays',
        question: 'How do I loop?',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Session with id 2 is closed'),
        ),
      ),
    );
  });

  test('getCurrentDoubt returns active doubt or null', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/sessions/1/current');
      return http.Response(
        jsonEncode({
          'doubt': {
            'id': 10,
            'session_id': 1,
            'student_name': 'Asha',
            'student_email': 'asha@example.com',
            'topic': 'Widgets',
            'question': 'How does state work?',
            'status': 'IN_PROGRESS',
          },
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final current = await api.getCurrentDoubt(1);
    expect(current, isNotNull);
    expect(current!.id, 10);
    expect(current.studentName, 'Asha');
  });

  test('searchSolvedDoubts sends query and maps results', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        '$baseUrl/api/doubts/search?q=loops&session_id=1',
      );
      return http.Response(
        jsonEncode([
          {
            'id': 15,
            'session_id': 1,
            'student_name': 'Ben',
            'student_email': 'ben@example.com',
            'topic': 'Arrays',
            'question': 'How do loops work?',
            'status': 'SOLVED',
            'resolution_notes': 'Use foreach loops for arrays.',
          },
        ]),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final results = await api.searchSolvedDoubts('loops', sessionId: 1);
    expect(results, hasLength(1));
    expect(results.first.resolutionNotes, 'Use foreach loops for arrays.');
  });

  test('markSolved sends resolution_notes in body', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/doubts/20/solved');
      expect(request.method, 'PATCH');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['resolution_notes'], 'Fixed via setState.');
      return http.Response(
        jsonEncode({
          'id': 20,
          'session_id': 1,
          'student_name': 'Chitra',
          'student_email': 'chitra@example.com',
          'topic': 'State',
          'question': 'How to rebuild UI?',
          'status': 'SOLVED',
          'resolution_notes': 'Fixed via setState.',
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final solved = await api.markSolved(
      20,
      resolutionNotes: 'Fixed via setState.',
    );
    expect(solved.status, 'SOLVED');
    expect(solved.resolutionNotes, 'Fixed via setState.');
  });

  test('getIntelligence sends request and parses DoubtIntelligence', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/sessions/1/intelligence');
      expect(request.method, 'GET');
      return http.Response(
        jsonEncode({
          'session_id': 1,
          'session_title': 'Flutter Session',
          'total_topics': 1,
          'recurring_topics': [
            {
              'topic': 'State Management',
              'normalized_topic': 'state management',
              'total_doubts': 3,
              'solved_count': 1,
              'skipped_count': 2,
              'waiting_count': 0,
              'in_progress_count': 0,
              'unresolved_rate': 0.67,
              'is_hotspot': true,
            },
          ],
          'hotspots': [
            {
              'topic': 'State Management',
              'normalized_topic': 'state management',
              'total_doubts': 3,
              'solved_count': 1,
              'skipped_count': 2,
              'waiting_count': 0,
              'in_progress_count': 0,
              'unresolved_rate': 0.67,
              'is_hotspot': true,
            },
          ],
          'top_solutions': [
            {
              'id': 5,
              'topic': 'State Management',
              'question': 'How does setState work?',
              'resolution_notes': 'Calls markNeedsBuild.',
            },
          ],
        }),
        200,
      );
    });
    final api = ApiService(client, baseUrl: baseUrl);

    final intel = await api.getIntelligence(1);
    expect(intel.sessionId, 1);
    expect(intel.totalTopics, 1);
    expect(intel.recurringTopics.first.topic, 'State Management');
    expect(intel.recurringTopics.first.isHotspot, isTrue);
    expect(intel.hasHotspots, isTrue);
    expect(intel.topSolutions.first.resolutionNotes, 'Calls markNeedsBuild.');
  });
}
