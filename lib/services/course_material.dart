import 'package:cloud_firestore/cloud_firestore.dart';

class CourseMaterial {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final String fileType; // e.g., 'pdf', 'image', 'link'
  final DateTime uploadedAt;

  CourseMaterial({
    this.id = '',
    required this.courseId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
  });

  factory CourseMaterial.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return CourseMaterial(
      id: snapshot.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      fileType: data['fileType'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}