import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neo/services/course_material.dart';
import 'package:neo/services/course_model.dart' show Course;
import 'package:neo/services/department.dart' show Department;
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection references
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'Users',
  );
  final CollectionReference departmentCollection = FirebaseFirestore.instance
      .collection('departments');
  final CollectionReference courseCollection = FirebaseFirestore.instance
      .collection('courses');
  final CollectionReference materialsCollection =
      FirebaseFirestore.instance.collection('course_materials');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Update user data in Firestore
  Future<void> updateUserData({
    String? name,
    String? matricule,
    String? phoneNumber,
  }) async {
    if (uid == null) return;
    return await users.doc(uid).set({
      if (name != null) 'name': name,
      if (matricule != null) 'matricule': matricule,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    }, SetOptions(merge: true)); // Use merge to avoid overwriting other fields
  }

  Stream get userData {
    if (uid == null) return Stream.empty();
    return users.doc(uid).snapshots();
  }

  // Get departments stream
  Stream<List<Department>> get departments {
    return departmentCollection.snapshots().map(_departmentListFromSnapshot);
  }

  // department list from snapshot
  List<Department> _departmentListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Department.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
    }).toList();
  }

  Stream get courseData {
    return courseCollection.snapshots();
  }

  // Get courses for a specific department
  Stream<List<Course>> getCoursesForDepartment(String departmentId) {
    return courseCollection
        .where('departmentId', isEqualTo: departmentId)
        .snapshots()
        .map(_courseListFromSnapshot);
  }

  // course list from snapshot
  List<Course> _courseListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Course.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
    }).toList();
  }

  // Create a new department
  Future<DocumentReference> createDepartment(Department department) async {
    return await departmentCollection.add(department.toFirestore());
  }

  // Create a new course
  Future<DocumentReference> createCourse(Course course) async {
    return await courseCollection.add(course.toFirestore());
  }

  // Upload an image and get the URL
  Future<String> uploadDepartmentImage(
    Uint8List imageData,
    String departmentName,
  ) async {
    final ref = _storage
        .ref()
        .child('department_images')
        .child('$departmentName-${DateTime.now().toIso8601String()}.jpg');
    // Use putData which works for web and mobile
    await ref.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  // Upload a course material file and get the URL
  Future<String> uploadCourseMaterialFile(
    Uint8List fileData,
    String courseId,
    String fileName,
  ) async {
    final ref = _storage
        .ref()
        .child('course_materials')
        .child(courseId)
        .child(fileName);
    await ref.putData(fileData);
    return await ref.getDownloadURL();
  }

  // Create a new course material document
  Future<void> addCourseMaterial(CourseMaterial material) async {
    await materialsCollection.add(material.toFirestore());
  }

  // Get materials for a specific course
  Stream<List<CourseMaterial>> getCourseMaterials(String courseId) {
    return materialsCollection
        .where('courseId', isEqualTo: courseId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourseMaterial.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  //  I'll be adding more methods to Delete, Upload, and Read courses here
}
