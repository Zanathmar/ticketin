class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? emailVerifiedAt;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.emailVerifiedAt,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'attendee',
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
      };

  bool get isAdmin => role == 'admin';
  bool get isOrganizer => role == 'organizer';
  bool get isAttendee => role == 'attendee';

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      emailVerifiedAt: emailVerifiedAt,
      createdAt: createdAt,
    );
  }
}
