class Course {
  final String id;
  final String code;
  final String name;
  final String departmentId;
  final String? semester;
  final String? level;
  final String? description;
  final DateTime? createdAt;
  final String? adminId;
  final DateTime? updatedAt;
  final double bountyMultiplier;

  Course({
    this.id = '',
    required this.code,
    required this.name,
    required this.departmentId,
    this.semester,
    this.level,
    this.description,
    this.createdAt,
    this.adminId,
    this.updatedAt,
    this.bountyMultiplier = 1.0,
  });

  /// Whether uploads to this course currently earn boosted approval points
  /// — see courses.bounty_multiplier in
  /// reward_material_approval_and_points_redemption.sql.
  bool get hasBounty => bountyMultiplier > 1.0;

  factory Course.fromSupabase(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['course_code'] ?? '',
      departmentId: json['department_id'] ?? '',
      semester: json['semester'],
      level: json['level'],
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      adminId: json['admin_id'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      bountyMultiplier: (json['bounty_multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'course_code': code,
      'department_id': departmentId,
      if (semester != null) 'semester': semester,
      if (level != null) 'level': level,
      if (description != null) 'description': description,
      'admin_id': adminId,
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': id,
    };
  }
}
