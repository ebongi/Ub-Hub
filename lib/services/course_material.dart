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
  final String materialCategory; // e.g., 'regular', 'past_question', 'answer'
  final bool isPastQuestion;
  final bool isAnswer;
  final String? linkedMaterialId; // ID of the linked question or answer
  final String? uploaderId;

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
    this.materialCategory = 'regular',
    this.isPastQuestion = false,
    this.isAnswer = false,
    this.linkedMaterialId,
    this.uploaderId,
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
      materialCategory: json['material_category'] ?? 'regular',
      isPastQuestion: json['is_past_question'] ?? false,
      isAnswer: json['is_answer'] ?? false,
      linkedMaterialId: json['linked_material_id'],
      uploaderId: json['uploader_id'],
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
      'material_category': materialCategory,
      'is_past_question': isPastQuestion,
      'is_answer': isAnswer,
      'linked_material_id': linkedMaterialId,
      'uploader_id': uploaderId,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
