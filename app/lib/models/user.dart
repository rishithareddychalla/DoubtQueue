enum UserRole {
  student,
  mentor;

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MENTOR':
        return UserRole.mentor;
      case 'STUDENT':
      default:
        return UserRole.student;
    }
  }

  String get apiValue => this == UserRole.mentor ? 'MENTOR' : 'STUDENT';
  String get displayName => this == UserRole.mentor ? 'Mentor' : 'Student';
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'ACTIVE',
    this.department = 'Computer Science & Engineering',
    this.createdAt = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'STUDENT'),
      status: json['status'] as String? ?? 'ACTIVE',
      department:
          json['department'] as String? ?? 'Computer Science & Engineering',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String status;
  final String department;
  final String createdAt;

  bool get isMentor => role == UserRole.mentor;
  bool get isStudent => role == UserRole.student;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.apiValue,
      'status': status,
      'department': department,
      'created_at': createdAt,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    UserRole? role,
    String? status,
    String? department,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
