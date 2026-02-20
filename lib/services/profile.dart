enum UserRole {
  viewer,
  contributor,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'contributor':
        return UserRole.contributor;
      case 'admin':
        return UserRole.admin;
      case 'viewer':
      default:
        return UserRole.viewer;
    }
  }

  String get name => toString().split('.').last;
}

class UserProfile {
  final String id;
  final String? name;
  final String? matricule;
  final String? phoneNumber;
  final String? level;
  final UserRole role;
  final DateTime? upgradedAt;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    this.name,
    this.matricule,
    this.phoneNumber,
    this.level,
    this.role = UserRole.viewer,
    this.upgradedAt,
    this.avatarUrl,
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'],
      matricule: json['matricule'],
      phoneNumber: json['phone_number'],
      level: json['level'],
      role: UserRole.fromString(json['role']),
      upgradedAt: json['upgraded_at'] != null
          ? DateTime.parse(json['upgraded_at'])
          : null,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'matricule': matricule,
      'phone_number': phoneNumber,
      'level': level,
      'role': role.name,
      'upgraded_at': upgradedAt?.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  bool get canUpload => role == UserRole.contributor || role == UserRole.admin;
}
