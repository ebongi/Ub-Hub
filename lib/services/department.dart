class Department {
  final String id;
  final String name;
  final String schoolId;
  final String description;
  final String? imageUrl;
  final String? adminId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Department({
    this.id = '',
    required this.name,
    this.schoolId = '',
    this.description = '',
    this.imageUrl,
    this.adminId,
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromSupabase(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      schoolId: json['school_id'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      adminId: json['admin_id'],
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
      'school_id': schoolId,
      'description': description,
      'image_url': imageUrl,
      'admin_id': adminId,
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': id,
    };
  }
}
