class CourseMaterial {
  final String id;
  final String? courseId;
  final String? departmentId;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final String fileType; // e.g., 'pdf', 'image', 'link'
  final DateTime uploadedAt;

  CourseMaterial({
    this.id = '',
    this.courseId,
    this.departmentId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
  }) : assert(
         courseId != null || departmentId != null,
         'Either courseId or departmentId must be provided',
       );

  factory CourseMaterial.fromSupabase(Map<String, dynamic> json) {
    return CourseMaterial(
      id: json['id'] ?? '',
      courseId: json['course_id'],
      departmentId: json['department_id'],
      title: json['name'] ?? '',
      fileUrl: json['file_url'] ?? '',
      fileType: json['file_type'] ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : DateTime.now(),
      fileName: json['file_name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'course_id': courseId,
      'department_id': departmentId,
      'name': title,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_name': fileName,
      'description': description,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
