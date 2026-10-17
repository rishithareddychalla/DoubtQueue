import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Session.fromJson reads all fields', () {
    final session = Session.fromJson({
      'id': 3,
      'title': 'PHP Basics Doubt Session',
      'mentor_name': 'Priya',
      'status': 'OPEN',
      'created_at': '2026-01-01 10:00:00',
      'closed_at': null,
      'waiting_count': 5,
    });

    expect(session.id, 3);
    expect(session.title, 'PHP Basics Doubt Session');
    expect(session.mentorName, 'Priya');
    expect(session.isOpen, isTrue);
    expect(session.waitingCount, 5);
    expect(session.createdAt, DateTime.utc(2026, 1, 1, 10));
    expect(session.closedAt, isNull);
  });

  test('Session.fromJson works without dates', () {
    final session = Session.fromJson({
      'id': 4,
      'title': 'Old session',
      'mentor_name': 'Arjun',
      'status': 'CLOSED',
    });

    expect(session.isOpen, isFalse);
    expect(session.waitingCount, 0);
    expect(session.createdAt, isNull);
  });

  test('Doubt.fromJson reads a waiting doubt with a position', () {
    final doubt = Doubt.fromJson({
      'id': 8,
      'session_id': 3,
      'student_name': 'Asha',
      'student_email': 'asha@example.com',
      'topic': 'Arrays',
      'question': 'How do I loop over an array?',
      'status': 'WAITING',
      'position': 3,
      'created_at': '2026-01-01 10:05:00',
      'started_at': null,
    });

    expect(doubt.id, 8);
    expect(doubt.sessionId, 3);
    expect(doubt.studentName, 'Asha');
    expect(doubt.studentEmail, 'asha@example.com');
    expect(doubt.isWaiting, isTrue);
    expect(doubt.position, 3);
    expect(doubt.studentsAhead, 2);
    expect(doubt.createdAt, DateTime.utc(2026, 1, 1, 10, 5));
    expect(doubt.startedAt, isNull);
  });

  test('Doubt.fromJson accepts a null position', () {
    final doubt = Doubt.fromJson({
      'id': 9,
      'session_id': 3,
      'student_name': 'Ben',
      'student_email': 'ben@example.com',
      'topic': 'PDO',
      'question': 'What is a prepared statement?',
      'status': 'SOLVED',
      'position': null,
      'started_at': '2026-01-01 10:10:00',
    });

    expect(doubt.position, isNull);
    expect(doubt.studentsAhead, 0);
    expect(doubt.isFinished, isTrue);
    expect(doubt.startedAt, DateTime.utc(2026, 1, 1, 10, 10));
  });

  test('Doubt.fromJson reads sessionStatus and resolutionNotes', () {
    final doubt = Doubt.fromJson({
      'id': 12,
      'session_id': 3,
      'student_name': 'Chitra',
      'student_email': 'chitra@example.com',
      'topic': 'State',
      'question': 'When to use StatefulWidget?',
      'status': 'SOLVED',
      'session_status': 'CLOSED',
      'resolution_notes': 'Use when UI changes dynamically.',
    });

    expect(doubt.sessionStatus, 'CLOSED');
    expect(doubt.isSessionClosed, isTrue);
    expect(doubt.resolutionNotes, 'Use when UI changes dynamically.');
  });
}
