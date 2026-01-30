class Course {
  final String id;
  final String code;
  final String name;
  final String departmentId;
  final String? semester;
  final String? level;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Course({
    this.id = '',
    required this.code,
    required this.name,
    required this.departmentId,
    this.semester,
    this.level,
    this.createdAt,
    this.updatedAt,
  });

  factory Course.fromSupabase(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['course_code'] ?? '',
      departmentId: json['department_id'] ?? '',
      semester: json['semester'],
      level: json['level'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'course_code': code,
      'department_id': departmentId,
      if (semester != null) 'semester': semester,
      if (level != null) 'level': level,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
