class UserGrade {
  final String id;
  final String userId;
  final String courseName;
  final int credits;
  final String grade;
  final String? semester;
  final String? academicYear;
  final DateTime createdAt;

  UserGrade({
    this.id = '',
    required this.userId,
    required this.courseName,
    required this.credits,
    required this.grade,
    this.semester,
    this.academicYear,
    required this.createdAt,
  });

  factory UserGrade.fromSupabase(Map<String, dynamic> json) {
    return UserGrade(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      courseName: json['course_name'] ?? '',
      credits: json['credits'] ?? 0,
      grade: json['grade'] ?? 'A',
      semester: json['semester'],
      academicYear: json['academic_year'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'course_name': courseName,
      'credits': credits,
      'grade': grade,
      'semester': semester,
      'academic_year': academicYear,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
