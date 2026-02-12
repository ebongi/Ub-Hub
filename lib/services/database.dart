import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neo/services/course_material.dart';
import 'package:neo/services/course_model.dart' show Course;
import 'package:neo/services/department.dart' show Department;
import 'package:neo/services/exam_event.dart' show ExamEvent;
import 'package:neo/services/payment_models.dart'
    show PaymentTransaction, PaymentStatus;
import 'package:neo/services/task_model.dart';
import 'package:neo/services/profile.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final _supabase = Supabase.instance.client;

  // Update user data in Supabase 'profiles' table
  Future<void> updateUserData({
    String? name,
    String? matricule,
    String? phoneNumber,
  }) async {
    if (uid == null) return;
    return await _supabase.from('profiles').upsert({
      'id': uid,
      if (name != null) 'name': name,
      if (matricule != null) 'matricule': matricule,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    });
  }

  Stream<UserProfile> get userProfile {
    if (uid == null) return Stream.empty();
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid!)
        .map((data) => UserProfile.fromSupabase(data.first));
  }

  // Get departments stream
  Stream<List<Department>> get departments {
    return _supabase
        .from('departments')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (data) => data.map((json) => Department.fromSupabase(json)).toList(),
        );
  }

  // Get courses for a specific department
  Stream<List<Course>> getCoursesForDepartment(String departmentId) {
    return _supabase
        .from('courses')
        .stream(primaryKey: ['id'])
        .eq('department_id', departmentId)
        .map((data) => data.map((json) => Course.fromSupabase(json)).toList());
  }

  // Get all courses (for notifications)
  Stream<List<Course>> get allCourses {
    return _supabase
        .from('courses')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Course.fromSupabase(json)).toList());
  }

  // Create a new department
  Future<String> createDepartment(Department department) async {
    final data = await _supabase
        .from('departments')
        .insert(department.toSupabase())
        .select()
        .single();
    return data['id'] as String;
  }

  // Create a new course
  Future<String> createCourse(Course course) async {
    final data = await _supabase
        .from('courses')
        .insert(course.toSupabase())
        .select()
        .single();
    return data['id'] as String;
  }

  // Upload an image and get the public URL
  Future<String> uploadDepartmentImage(
    Uint8List imageData,
    String departmentName,
  ) async {
    final fileName =
        '$departmentName-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'department_images/$fileName';

    await _supabase.storage
        .from('department_images')
        .uploadBinary(
          path,
          imageData,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _supabase.storage.from('department_images').getPublicUrl(path);
  }

  // Upload a material file (course or department) and get the public URL
  Future<String> uploadMaterialFile(
    Uint8List fileData,
    String targetId, // courseCode or departmentId
    String fileName,
    bool isDepartment,
  ) async {
    // Use the existing 'course_materials' bucket for all documents
    const folder = 'course_materials';
    final path = isDepartment
        ? 'department/$targetId/$fileName'
        : 'course/$targetId/$fileName';
    await _supabase.storage.from(folder).uploadBinary(path, fileData);
    return _supabase.storage.from(folder).getPublicUrl(path);
  }

  // Create a new material record
  Future<String> addMaterial(CourseMaterial material) async {
    final data = await _supabase
        .from('course_materials')
        .insert(material.toSupabase())
        .select()
        .single();
    return data['id'] as String;
  }

  // Get materials for a specific course
  Stream<List<CourseMaterial>> getCourseMaterials(String courseId) {
    return _supabase
        .from('course_materials')
        .stream(primaryKey: ['id'])
        .eq('course_id', courseId)
        .order('uploaded_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => CourseMaterial.fromSupabase(json)).toList(),
        );
  }

  // Get materials for a specific department
  Stream<List<CourseMaterial>> getDepartmentMaterials(String departmentId) {
    return _supabase
        .from('course_materials')
        .stream(primaryKey: ['id'])
        .eq('department_id', departmentId)
        .order('uploaded_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => CourseMaterial.fromSupabase(json)).toList(),
        );
  }

  // Get exams for the current user
  Stream<List<ExamEvent>> get exams {
    if (uid == null) return Stream.empty();
    return _supabase
        .from('exams')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid!)
        .order('start_time', ascending: true)
        .map(
          (data) => data.map((json) => ExamEvent.fromSupabase(json)).toList(),
        );
  }

  // Create a new exam
  Future<void> addExam(ExamEvent exam) async {
    await _supabase.from('exams').insert(exam.toSupabase());
  }

  // Update an exam
  Future<void> updateExam(ExamEvent exam) async {
    await _supabase.from('exams').update(exam.toSupabase()).eq('id', exam.id);
  }

  // Delete an exam
  Future<void> deleteExam(String examId) async {
    await _supabase.from('exams').delete().eq('id', examId);
  }

  // ==================== Payment Transaction Methods ====================

  /// Create a new payment transaction record
  Future<String> createPaymentTransaction(
    PaymentTransaction transaction,
  ) async {
    final data = await _supabase
        .from('payment_transactions')
        .insert(transaction.toSupabase())
        .select()
        .single();
    return data['id'] as String;
  }

  /// Update payment transaction status
  Future<void> updatePaymentStatus(
    String paymentRef,
    PaymentStatus status, {
    String? departmentId,
    String? materialId,
  }) async {
    await _supabase
        .from('payment_transactions')
        .update({
          'status': status.name,
          if (departmentId != null) 'department_id': departmentId,
          if (materialId != null) 'material_id': materialId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('payment_ref', paymentRef);
  }

  /// Get payment transaction by payment reference
  Future<PaymentTransaction?> getPaymentByRef(String paymentRef) async {
    final data = await _supabase
        .from('payment_transactions')
        .select()
        .eq('payment_ref', paymentRef)
        .maybeSingle();

    if (data == null) return null;
    return PaymentTransaction.fromSupabase(data);
  }

  /// Get all payment transactions for the current user
  Stream<List<PaymentTransaction>> get userPayments {
    if (uid == null) return Stream.empty();
    return _supabase
        .from('payment_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid!)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .map((json) => PaymentTransaction.fromSupabase(json))
              .toList(),
        );
  }

  // ==================== Task To-Do Persistence ====================

  /// Get tasks for the current user
  Stream<List<TodoTask>> get tasks {
    if (uid == null) return Stream.empty();
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid!)
        .order('created_at', ascending: false)
        .map(
          (data) => data.map((json) => TodoTask.fromSupabase(json)).toList(),
        );
  }

  /// Create a new task
  Future<void> addTask(TodoTask task) async {
    await _supabase.from('tasks').insert(task.toSupabase());
  }

  /// Update a task
  Future<void> updateTask(TodoTask task) async {
    await _supabase.from('tasks').update(task.toSupabase()).eq('id', task.id);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  /// Upgrade user to contributor role
  Future<void> upgradeUserToContributor() async {
    if (uid == null) return;
    await _supabase
        .from('profiles')
        .update({
          'role': UserRole.contributor.name,
          'upgraded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid!);
  }

  /// Upload profile avatar and update profile URL
  Future<String> uploadAvatar(Uint8List imageData) async {
    if (uid == null) throw "User not authenticated";

    final fileName = '$uid-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path =
        fileName; // Directly in root of avatars bucket or use subfolder

    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          imageData,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(path);

    await _supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', uid!);

    return avatarUrl;
  }
}
