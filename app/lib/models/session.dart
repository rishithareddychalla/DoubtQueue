import '../utils/time_format.dart';

class Session {
  const Session({
    required this.id,
    required this.title,
    required this.mentorName,
    required this.status,
    required this.waitingCount,
    this.mentorId,
    this.createdAt,
    this.closedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      mentorId: json['mentor_id'] as int?,
      title: json['title'] as String,
      mentorName: json['mentor_name'] as String,
      status: json['status'] as String,
      waitingCount: json['waiting_count'] as int? ?? 0,
      createdAt: parseApiDate(json['created_at'] as String?),
      closedAt: parseApiDate(json['closed_at'] as String?),
    );
  }

  final int id;
  final int? mentorId;
  final String title;
  final String mentorName;
  final String status;
  final int waitingCount;
  final DateTime? createdAt;
  final DateTime? closedAt;

  bool get isOpen => status == 'OPEN';

}
