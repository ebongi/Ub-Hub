class School {
  final String id;
  final String name;
  final String institutionId;
  final String description;
  final DateTime? createdAt;

  School({
    required this.id,
    required this.name,
    required this.institutionId,
    this.description = '',
    this.createdAt,
  });

  factory School.fromSupabase(Map<String, dynamic> json) {
    return School(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      institutionId: json['institution_id'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'institution_id': institutionId,
      'description': description,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
