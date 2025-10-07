import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neo/services/course_model.dart' show Course;
import 'package:neo/services/department.dart' show Department;
 
 

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection references
  final CollectionReference users =
      FirebaseFirestore.instance.collection('Users');
  final CollectionReference departmentCollection =
      FirebaseFirestore.instance.collection('departments');
  final CollectionReference courseCollection =
      FirebaseFirestore.instance.collection('courses');

  Future updateUserData({String? name, String? matricule}) async {
    if (uid == null) return;
    return await users.doc(
      uid,
    ).set({'Name': name, 'Matricule': matricule});
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
      return Department.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
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
      return Course.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
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

  // You can add more methods here for reading, updating, and deleting data.
}
