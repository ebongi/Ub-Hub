/// Fallback institution for users who haven't explicitly chosen one yet
/// (e.g. right after registration, before they tap a university chip on
/// the home screen). University Of Buea, since GoStudy started as a
/// UB-only app before other institutions were added.
const String kDefaultInstitutionId = '0bb35b95-fe1a-4b0c-bcad-22cd5073a2b4';

class Institution {
  final String id;
  final String name;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? description;
  final DateTime? createdAt;

  Institution({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.description,
    this.createdAt,
  });

  factory Institution.fromSupabase(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      primaryColor: json['primary_color'],
      secondaryColor: json['secondary_color'],
      description: json['description'],
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
      'description': description,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
