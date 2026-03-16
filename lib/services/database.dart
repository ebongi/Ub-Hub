import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/course_model.dart' show Course;
import 'package:go_study/services/department.dart' show Department;
import 'package:go_study/services/exam_event.dart' show ExamEvent;
import 'package:go_study/services/payment_models.dart'
    show PaymentTransaction, PaymentStatus;
import 'package:go_study/services/task_model.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/grade_model.dart';
import 'package:go_study/services/campus_models.dart';
import 'package:go_study/services/notification_service.dart';
import 'package:go_study/services/notification_model.dart';
import 'package:go_study/services/institution.dart';
import 'package:go_study/services/school.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final _supabase = Supabase.instance.client;

  // Update user data in Supabase 'profiles' table
  Future<void> updateUserData({
    String? name,
    String? matricule,
    String? phoneNumber,
    String? level,
    String? institutionId,
  }) async {
    if (uid == null) return;
    return await _supabase.from('profiles').upsert({
      'id': uid,
      if (name != null) 'name': name,
      if (matricule != null) 'matricule': matricule,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (level != null) 'level': level,
      if (institutionId != null) 'institution_id': institutionId,
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

  // ==================== Multitenancy Methods ====================

  /// Get all institutions
  Stream<List<Institution>> get institutions {
    return _supabase
        .from('institutions')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data.map((json) => Institution.fromSupabase(json)).toList());
  }

  /// Get a single institution by ID
  Future<Institution?> getInstitution(String id) async {
    try {
      final data = await _supabase
          .from('institutions')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Institution.fromSupabase(data);
    } catch (e) {
      print('Error fetching institution: $e');
      return null;
    }
  }

  /// Get schools for a specific institution
  Stream<List<School>> getSchoolsForInstitution(String institutionId) {
    return _supabase
        .from('schools')
        .stream(primaryKey: ['id'])
        .eq('institution_id', institutionId)
        .order('name')
        .map((data) => data.map((json) => School.fromSupabase(json)).toList());
  }

  /// Get departments for a specific school
  Stream<List<Department>> getDepartmentsForSchool(String schoolId) {
    return _supabase
        .from('departments')
        .stream(primaryKey: ['id'])
        .eq('school_id', schoolId)
        .order('name')
        .map((data) => data.map((json) => Department.fromSupabase(json)).toList());
  }

  // Get departments stream (optionally filtered by institution)
  Stream<List<Department>> getDepartments({String? institutionId}) {
    final query = _supabase.from('departments').stream(primaryKey: ['id']);
    
    if (institutionId != null) {
      return query
          .eq('institution_id', institutionId)
          .order('name')
          .map((data) => data.map((json) => Department.fromSupabase(json)).toList());
    }
    
    return query.order('name').map(
          (data) => data.map((json) => Department.fromSupabase(json)).toList(),
        );
  }

  // Legacy getter for backward compatibility
  Stream<List<Department>> get departments => getDepartments();

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
    final id = data['id'] as String;

    // Trigger notification
    await NotificationService().createNotification(
      title: 'New Department',
      body: 'A new department "${department.name}" has been added.',
      type: NotificationType.department,
      data: {'departmentId': id},
    );

    return id;
  }

  // Create a new course
  Future<String> createCourse(Course course) async {
    final data = await _supabase
        .from('courses')
        .insert(course.toSupabase())
        .select()
        .single();
    final id = data['id'] as String;

    // Trigger notification
    await NotificationService().createNotification(
      title: 'New Course',
      body: 'A new course "${course.name}" (${course.code}) is now available.',
      type: NotificationType.course,
      data: {'courseId': id, 'departmentId': course.departmentId},
    );

    return id;
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
    final id = data['id'] as String;

    // Trigger notification
    await NotificationService().createNotification(
      title: 'New Material Uploaded',
      body: 'New content "${material.title}" has been uploaded.',
      type: NotificationType.material,
      data: {
        'materialId': id,
        'courseId': material.courseId,
        'category': material.materialCategory,
      },
    );

    return id;
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

  /// Get multiple materials by their IDs
  Future<List<CourseMaterial>> getMaterialsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final List<dynamic> data = await _supabase
        .from('course_materials')
        .select()
        .filter('id', 'in', '(${ids.join(",")})');

    return data.map((json) => CourseMaterial.fromSupabase(json)).toList();
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

    await NotificationService().createNotification(
      title: 'Welcome Contributor!',
      body:
          'You have been successfully upgraded to a contributor. You now have unlimited access to all features.',
      type: NotificationType.subscription,
    );
  }

  /// Upgrade user subscription tier
  Future<void> upgradeSubscription(SubscriptionTier tier) async {
    if (uid == null) return;

    // Silver lasts for 14 days, others for 30 days
    final durationDays = tier == SubscriptionTier.silver ? 14 : 30;
    final expiry = DateTime.now().add(Duration(days: durationDays));

    await _supabase
        .from('profiles')
        .update({
          'subscription_tier': tier.name,
          'subscription_expiry': expiry.toIso8601String(),
          'free_download_count': 0, // Reset count on upgrade/renewal
        })
        .eq('id', uid!);

    await NotificationService().createNotification(
      title: 'Subscription Activated',
      body:
          'Your ${tier.name.toUpperCase()} subscription is now active until ${DateFormat.yMMMd().format(expiry)}.',
      type: NotificationType.subscription,
      data: {'tier': tier.name, 'expiry': expiry.toIso8601String()},
    );
  }

  /// Increment free download count for Silver users
  Future<void> incrementFreeDownloadCount() async {
    if (uid == null) return;

    final profile = await _supabase
        .from('profiles')
        .select('free_download_count')
        .eq('id', uid!)
        .single();

    final currentCount = profile['free_download_count'] as int? ?? 0;

    await _supabase
        .from('profiles')
        .update({'free_download_count': currentCount + 1})
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

  // ==================== Marketplace / Contributor Methods ====================

  /// Get all materials uploaded by a specific user
  Stream<List<CourseMaterial>> getUserUploadedMaterials(String userId) {
    return _supabase
        .from('course_materials')
        .stream(primaryKey: ['id'])
        .eq('uploader_id', userId)
        .order('uploaded_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => CourseMaterial.fromSupabase(json)).toList(),
        );
  }

  /// Get gross earnings for a specific uploader from successful downloads
  Stream<double> getGrossEarningsForUploader(String userId) {
    return _supabase
        .from('course_materials')
        .stream(primaryKey: ['id'])
        .eq('uploader_id', userId)
        .asyncMap((materials) async {
          if (materials.isEmpty) return 0.0;
          final materialIds = materials.map((m) => m['id']).toList();

          final transactions = await _supabase
              .from('payment_transactions')
              .select('amount')
              .eq('status', 'success')
              .eq('item_type', 'download')
              .filter('material_id', 'in', '(${materialIds.join(",")})');

          double total = 0;
          for (var t in transactions) {
            total += (t['amount'] as num).toDouble();
          }
          return total;
        });
  }

  /// Get total withdrawn earnings for a specific user
  Stream<double> getWithdrawnEarnings(String userId) {
    return _supabase
        .from('payment_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          double total = 0;
          for (var t in data) {
            if (t['item_type'] == 'payout' && t['status'] == 'success') {
              total += (t['amount'] as num).toDouble();
            }
          }
          return total;
        });
  }

  /// Get net earnings (Gross - Withdrawn)
  Stream<double> getEarningsForUploader(String userId) {
    // Combine gross and withdrawn streams
    return getGrossEarningsForUploader(userId).asyncMap((gross) async {
      final withdrawnStream = getWithdrawnEarnings(userId);
      final withdrawn = await withdrawnStream.first;
      return gross - withdrawn;
    });
  }

  // ==================== Grade Tracking / Predictor Methods ====================

  /// Get all grades for a specific user
  Stream<List<UserGrade>> getUserGrades(String userId) {
    return _supabase
        .from('grades')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data.map((json) => UserGrade.fromSupabase(json)).toList(),
        );
  }

  /// Save or update a grade
  Future<void> saveGrade(UserGrade grade) async {
    await _supabase.from('grades').upsert(grade.toSupabase());
  }

  /// Delete a grade
  Future<void> deleteGrade(String gradeId) async {
    await _supabase.from('grades').delete().eq('id', gradeId);
  }

  // ==================== Campus Integration Methods ====================

  /// Get all campus locations (halls, amphis, labs)
  Stream<List<CampusLocation>> getCampusLocations({String? institutionId}) {
    final query = _supabase.from('campus_locations').stream(primaryKey: ['id']);
    
    if (institutionId != null) {
      return query
          .eq('institution_id', institutionId)
          .order('name')
          .map((data) => data.map((json) => CampusLocation.fromSupabase(json)).toList());
    }
    
    return query.order('name').map(
          (data) => data.map((json) => CampusLocation.fromSupabase(json)).toList(),
        );
  }

  /// Get latest university news
  Stream<List<NewsArticle>> getUniversityNews({String? institutionId}) {
    final query = _supabase.from('university_news').stream(primaryKey: ['id']);
    
    if (institutionId != null) {
      return query
          .eq('institution_id', institutionId)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => NewsArticle.fromSupabase(json)).toList());
    }
    
    return query.order('created_at', ascending: false).map(
          (data) => data.map((json) => NewsArticle.fromSupabase(json)).toList(),
        );
  }
}
