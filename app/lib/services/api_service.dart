import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/doubt.dart';
import '../models/intelligence.dart';
import '../models/session.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this._client, {this.baseUrl = apiBaseUrl});

  final http.Client _client;
  final String baseUrl;

  Future<List<Session>> getSessions({String? status}) async {
    final query = status == null ? '' : '?status=$status';
    final data = await _send('GET', '/api/sessions$query') as List<dynamic>;
    return data
        .map((item) => Session.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Session> createSession(String title, String mentorName) async {
    final data = await _send('POST', '/api/sessions', {
      'title': title,
      'mentor_name': mentorName,
    });
    return Session.fromJson(data as Map<String, dynamic>);
  }

  Future<Session> closeSession(int sessionId) async {
    final data = await _send('PATCH', '/api/sessions/$sessionId/close');
    return Session.fromJson(data as Map<String, dynamic>);
  }

  Future<Doubt> joinSession(
    int sessionId, {
    required String name,
    required String email,
    required String topic,
    required String question,
  }) async {
    final data = await _send('POST', '/api/sessions/$sessionId/doubts', {
      'student_name': name,
      'student_email': email,
      'topic': topic,
      'question': question,
    });
    return Doubt.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Doubt>> getQueue(int sessionId) async {
    final data =
        await _send('GET', '/api/sessions/$sessionId/queue') as List<dynamic>;
    return data
        .map((item) => Doubt.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Doubt> takeNext(int sessionId) async {
    final data = await _send('POST', '/api/sessions/$sessionId/next');
    return Doubt.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, int>> getStats(int sessionId) async {
    final data = await _send('GET', '/api/sessions/$sessionId/stats');
    return (data as Map<String, dynamic>).map(
      (status, count) => MapEntry(status, count as int),
    );
  }

  Future<Doubt> getDoubt(int doubtId) async {
    final data = await _send('GET', '/api/doubts/$doubtId');
    return Doubt.fromJson(data as Map<String, dynamic>);
  }

  Future<Doubt?> getCurrentDoubt(int sessionId) async {
    final data = await _send('GET', '/api/sessions/$sessionId/current');
    if (data is Map<String, dynamic> && data['doubt'] != null) {
      return Doubt.fromJson(data['doubt'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Doubt>> searchSolvedDoubts(String query, {int? sessionId}) async {
    final sessionParam = sessionId == null ? '' : '&session_id=$sessionId';
    final data = await _send(
      'GET',
      '/api/doubts/search?q=${Uri.encodeQueryComponent(query)}$sessionParam',
    ) as List<dynamic>;
    return data
        .map((item) => Doubt.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DoubtIntelligence> getIntelligence(int sessionId) async {
    final data = await _send('GET', '/api/sessions/$sessionId/intelligence');
    return DoubtIntelligence.fromJson(data as Map<String, dynamic>);
  }

  Future<Doubt> markSolved(int doubtId, {String? resolutionNotes}) async {
    final body = resolutionNotes == null
        ? null
        : {'resolution_notes': resolutionNotes};
    final data = await _send('PATCH', '/api/doubts/$doubtId/solved', body);
    return Doubt.fromJson(data as Map<String, dynamic>);
  }

  Future<Doubt> markSkipped(int doubtId) async {
    final data = await _send('PATCH', '/api/doubts/$doubtId/skipped');
    return Doubt.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    if (decoded is Map<String, dynamic> && decoded['message'] is String) {
      throw ApiException(decoded['message'] as String);
    }
    throw ApiException('Request failed with status ${response.statusCode}');
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }
}
