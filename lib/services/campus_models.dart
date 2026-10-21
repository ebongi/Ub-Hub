class CampusLocation {
  final String id;
  final String name;
  final String category; // 'amphi', 'lab', 'office', 'restaurant', 'clinic'
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  CampusLocation({
    this.id = '',
    required this.name,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  factory CampusLocation.fromSupabase(Map<String, dynamic> json) {
    return CampusLocation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'other',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      if (imageUrl != null) 'image_url': imageUrl,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
