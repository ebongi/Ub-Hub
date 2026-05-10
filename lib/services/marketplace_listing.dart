class MarketplaceListing {
  final String id;
  final String vendorId;
  final String title;
  final String? description;
  final double price;
  final String category;
  final String itemType; // 'physical' or 'digital'
  final String? fileUrl;
  final List<String> imageUrls;
  final String? condition;
  final String status;
  final DateTime createdAt;

  MarketplaceListing({
    this.id = '',
    required this.vendorId,
    required this.title,
    this.description,
    required this.price,
    required this.category,
    this.itemType = 'digital',
    this.fileUrl,
    this.imageUrls = const [],
    this.condition,
    this.status = 'active',
    required this.createdAt,
  });

  factory MarketplaceListing.fromSupabase(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Other',
      itemType: json['item_type'] ?? 'digital',
      fileUrl: json['file_url'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      condition: json['condition'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'vendor_id': vendorId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'item_type': itemType,
      'file_url': fileUrl,
      'image_urls': imageUrls,
      'condition': condition,
      'status': status,
      if (id.isNotEmpty) 'id': id,
    };
  }
}
