import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String name;
  final String departmentId;
  final String? semester;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Course({
    required this.id,
    required this.name,
    required this.departmentId,
    this.semester,
    this.createdAt,
    this.updatedAt,
  });

  factory Course.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Course(
      id: snapshot.id,
      name: data?['name'] ?? '',
      departmentId: data?['departmentId'] ?? '',
      semester: data?['semester'],
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'departmentId': departmentId,
      if (semester != null) 'semester': semester,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}