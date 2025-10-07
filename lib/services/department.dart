import 'package:cloud_firestore/cloud_firestore.dart';

class Department {
  final String id;
  final String name;
  final String schoolId;
  final String description;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Department({
    this.id = '',
    required this.name,
    required this.schoolId,
    required this.description,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Department(
      id: snapshot.id,
      name: data?['name'] ?? '',
      schoolId: data?['schoolId'] ?? '',
      description: data?['description'] ?? '',
      imageUrl: data?['imageUrl'],
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'schoolId': schoolId,
      'description': description,
      'imageUrl': imageUrl,
      if (id.isNotEmpty) 'id': id,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}