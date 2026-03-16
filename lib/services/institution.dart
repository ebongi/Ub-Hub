class Institution {
  final String id;
  final String name;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final DateTime? createdAt;

  Institution({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.createdAt,
  });

  factory Institution.fromSupabase(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      primaryColor: json['primary_color'],
      secondaryColor: json['secondary_color'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
