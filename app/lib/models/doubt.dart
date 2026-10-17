import '../utils/time_format.dart';

class Doubt {
  const Doubt({
    required this.id,
    required this.sessionId,
    required this.topic,
    required this.question,
    required this.status,
    this.studentName = '',
    this.studentEmail = '',
    this.position,
    this.sessionStatus,
    this.resolutionNotes,
    this.similarityScore,
    this.createdAt,
    this.startedAt,
  });

  factory Doubt.fromJson(Map<String, dynamic> json) {
    return Doubt(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      studentName: (json['student_name'] as String?) ?? '',
      studentEmail: (json['student_email'] as String?) ?? '',
      topic: json['topic'] as String,
      question: json['question'] as String,
      status: json['status'] as String,
      position: json['position'] as int?,
      sessionStatus: json['session_status'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
      createdAt: parseApiDate(json['created_at'] as String?),
      startedAt: parseApiDate(json['started_at'] as String?),
    );
  }

  final int id;
  final int sessionId;
  final String studentName;
  final String studentEmail;
  final String topic;
  final String question;
  final String status;
  final int? position;
  final String? sessionStatus;
  final String? resolutionNotes;
  final double? similarityScore;
  final DateTime? createdAt;
  final DateTime? startedAt;

  bool get isWaiting => status == 'WAITING';
  bool get isFinished => status == 'SOLVED' || status == 'SKIPPED';
  bool get isSessionClosed => sessionStatus == 'CLOSED';

  int get studentsAhead => position == null ? 0 : position! - 1;
}
