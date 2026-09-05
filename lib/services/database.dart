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
import 'package:go_study/services/recent_activity_service.dart';
import 'package:go_study/services/marketplace_listing.dart';
import 'package:go_study/services/bot_knowledge.dart';
import 'package:go_study/services/news_post.dart';
import 'package:go_study/services/flashcard_model.dart';
import 'package:go_study/services/points_service.dart';

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
    String? department,
    String? bio,
    String? avatarUrl,
  }) async {
    if (uid == null) return;
    return await _supabase.from('profiles').upsert({
      'id': uid,
      if (name != null) 'name': name,
      if (matricule != null) 'matricule': matricule,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (level != null) 'level': level,
      if (institutionId != null) 'institution_id': institutionId,
      if (department != null) 'department': department,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
  }

  Stream<UserProfile> get userProfile {
    if (uid == null) return Stream.empty();
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid!)
        .map((data) {
          if (data.isEmpty) {
            // Route through fromSupabase so createdAt falls back to
            // auth.currentUser.createdAt (see profile.dart) instead of
            // staying null — a null createdAt fails hasAccess's new-account
            // grace window and wrongly paywalls a user whose profiles row
            // hasn't been created yet (a signup-vs-profile-insert race).
            return UserProfile.fromSupabase({'id': uid});
          }
          return UserProfile.fromSupabase(data.first);
        });
  }

  // ==================== Multitenancy Methods ====================

  /// Get all institutions
  Stream<List<Institution>> get institutions {
    return _supabase
        .from('institutions')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (data) => data.map((json) => Institution.fromSupabase(json)).toList(),
        );
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
        .map(
          (data) => data.map((json) => Department.fromSupabase(json)).toList(),
        );
  }

  // Get departments stream (optionally filtered by institution)
  Stream<List<Department>> getDepartments({String? institutionId}) {
    final query = _supabase.from('departments').stream(primaryKey: ['id']);

    if (institutionId != null) {
      return query
          .eq('school_id', institutionId)
          .order('name')
          .map(
            (data) =>
                data.map((json) => Department.fromSupabase(json)).toList(),
          );
    }

    return query
        .order('name')
        .map(
          (data) => data.map((json) => Department.fromSupabase(json)).toList(),
        );
  }

  // Legacy getter for backward compatibility
  Stream<List<Department>> get departments => getDepartments();

  // Get a single department by ID
  Future<Department?> getDepartment(String id) async {
    try {
      final data = await _supabase
          .from('departments')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Department.fromSupabase(data);
    } catch (e) {
      print('Error fetching department: $e');
      return null;
    }
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

  /// Ids of every student profile in the given department (matched by
  /// department name, since UserProfile.department stores the name a
  /// student picked at registration, not an id).
  Future<List<String>> _getStudentIdsInDepartment(String departmentId) async {
    final dept = await _supabase
        .from('departments')
        .select('name')
        .eq('id', departmentId)
        .maybeSingle();
    if (dept == null) return [];

    final rows = await _supabase
        .from('profiles')
        .select('id')
        .eq('department', dept['name'] as String);
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Ids of every student profile at the given institution.
  Future<List<String>> _getStudentIdsInInstitution(String institutionId) async {
    final rows = await _supabase
        .from('profiles')
        .select('id')
        .eq('institution_id', institutionId);
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Fires the "new content" broadcast pair together — an in-app
  /// notification row (visible in the recipient's notification list) plus
  /// an FCM push (for background/terminated devices) — since neither
  /// depends on the other's result. Each create-content method still
  /// resolves its own [recipientIds] (the DB-row audience) and
  /// [scope]/[scopeId] (the push audience, resolved server-side by the edge
  /// function) since their broadcast semantics differ.
  Future<void> _broadcastCreate({
    required List<String> recipientIds,
    required String title,
    required String body,
    required NotificationType type,
    required String scope,
    String? scopeId,
    Map<String, dynamic>? data,
    String? pushTitle,
    Map<String, dynamic>? pushData,
  }) async {
    await Future.wait([
      NotificationService().createBroadcastNotification(
        recipientIds: recipientIds,
        title: title,
        body: body,
        type: type,
        data: data,
        excludeUserId: uid,
      ),
      NotificationService().triggerPushViaEdgeFunction(
        scope: scope,
        scopeId: scopeId,
        title: pushTitle ?? title,
        body: body,
        type: type,
        data: pushData ?? data,
        insertNotification: false,
      ),
    ]);
  }

  // Create a new department
  Future<String> createDepartment(Department department) async {
    final data = await _supabase
        .from('departments')
        .insert(department.toSupabase())
        .select()
        .single();

    final id = data['id'] as String;

    // Broadcast to every student at the parent institution (the department
    // is brand new, so it has no students of its own yet). Best-effort —
    // never let a notification failure block department creation.
    try {
      final school = await _supabase
          .from('schools')
          .select('institution_id')
          .eq('id', department.schoolId)
          .maybeSingle();
      final institutionId = school?['institution_id'] as String?;
      if (institutionId != null) {
        final recipientIds = await _getStudentIdsInInstitution(institutionId);
        await _broadcastCreate(
          recipientIds: recipientIds,
          title: 'New Department',
          body: 'A new department "${department.name}" has been added.',
          type: NotificationType.department,
          data: {'departmentId': id},
          scope: 'institution',
          scopeId: institutionId,
        );
      }
    } catch (_) {
      // Silently ignore — see comment above.
    }

    return id;
  }

  // Delete a department
  Future<void> deleteDepartment(String departmentId) async {
    await _supabase.from('departments').delete().eq('id', departmentId);
    await RecentActivityService().clearIfMatches(departmentId);
  }

  // Create a new course
  Future<String> createCourse(Course course) async {
    final data = await _supabase
        .from('courses')
        .insert(course.toSupabase())
        .select()
        .single();

    final id = data['id'] as String;

    // Broadcast to every student already in this department. Best-effort —
    // never let a notification failure block course creation.
    try {
      final recipientIds = await _getStudentIdsInDepartment(
        course.departmentId,
      );
      await _broadcastCreate(
        recipientIds: recipientIds,
        title: 'New Course',
        body:
            'A new course "${course.name}" (${course.code}) is now available.',
        type: NotificationType.course,
        data: {'courseId': id, 'departmentId': course.departmentId},
        scope: 'department',
        scopeId: course.departmentId,
      );
    } catch (_) {
      // Silently ignore — see comment above.
    }

    return id;
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    await _supabase.from('courses').delete().eq('id', courseId);
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

  // Upload an image for a marketplace listing
  Future<String> uploadMarketplaceImage(
    Uint8List imageData,
    String fileName,
  ) async {
    final cleanName =
        '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';
    final path = 'marketplace/$cleanName';

    // Using 'department_images' bucket as it is configured for public images
    await _supabase.storage
        .from('department_images')
        .uploadBinary(
          path,
          imageData,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
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
        .insert({
          ...material.toSupabase(),
          if (material.uploaderId == null && uid != null) 'uploader_id': uid,
        })
        .select()
        .single();
    final id = data['id'] as String;

    // Broadcast to every student in the material's department (resolve via
    // the course if the material wasn't uploaded directly to a department).
    String? departmentId = material.departmentId;
    if (departmentId == null && material.courseId != null) {
      final course = await _supabase
          .from('courses')
          .select('department_id')
          .eq('id', material.courseId!)
          .maybeSingle();
      departmentId = course?['department_id'] as String?;
    }

    if (departmentId != null) {
      // Best-effort: RLS permits notifying same-department peers or (if
      // admin) anyone, but a student uploading to a department other than
      // their own profile's department still won't have coverage. Don't
      // let a rejected broadcast fail the upload itself.
      try {
        final recipientIds = await _getStudentIdsInDepartment(departmentId);
        await _broadcastCreate(
          recipientIds: recipientIds,
          title: 'New Material Uploaded',
          body: 'New content "${material.title}" has been uploaded.',
          type: NotificationType.material,
          data: {
            'materialId': id,
            'courseId': material.courseId,
            'category': material.materialCategory,
          },
          scope: 'department',
          scopeId: departmentId,
          pushTitle: 'New Material Uploaded 📚',
          pushData: {
            'materialId': id,
            'courseId': material.courseId ?? '',
            'category': material.materialCategory,
          },
        );
      } catch (_) {
        // Silently ignore — see comment above.
      }
    }

    // Best-effort — a points RPC hiccup shouldn't fail the upload itself.
    try {
      await PointsService().awardPoints('material_uploaded');
    } catch (_) {
      // Silently ignore.
    }

    return id;
  }

  // Delete a material record
  Future<void> deleteMaterial(String materialId) async {
    await _supabase.from('course_materials').delete().eq('id', materialId);
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

  // ==================== Flashcard Deck Methods ====================
  //
  // Decks are private to their creator (RLS: auth.uid() = user_id). Supabase
  // realtime streams take a single filter, so we filter by the FK server-side
  // and drop anyone else's rows client-side — same shape as getBotKnowledge.

  /// Decks the current user generated, filtered by a single foreign-key
  /// column ('material_id', 'course_id', or 'department_id') — the three
  /// public getters below only differ in which column they filter on.
  Stream<List<FlashcardDeck>> _getDecksFiltered(String column, String value) {
    return _supabase
        .from('flashcard_decks')
        .stream(primaryKey: ['id'])
        .eq(column, value)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .map((json) => FlashcardDeck.fromSupabase(json))
              .where((d) => d.userId == uid)
              .toList(),
        );
  }

  /// Decks the current user generated from a specific material.
  Stream<List<FlashcardDeck>> getDecksForMaterial(String materialId) =>
      _getDecksFiltered('material_id', materialId);

  /// Decks the current user generated from any of a course's materials.
  Stream<List<FlashcardDeck>> getDecksForCourse(String courseId) =>
      _getDecksFiltered('course_id', courseId);

  /// Decks the current user generated from any of a department's materials.
  Stream<List<FlashcardDeck>> getDecksForDepartment(String departmentId) =>
      _getDecksFiltered('department_id', departmentId);

  /// The cards of a deck, in study order.
  Future<List<Flashcard>> getCards(String deckId) async {
    final List<dynamic> data = await _supabase
        .from('flashcards')
        .select()
        .eq('deck_id', deckId)
        .order('position', ascending: true);

    return data.map((json) => Flashcard.fromSupabase(json)).toList();
  }

  /// Persists a generated deck and its cards, returning the stored deck.
  Future<FlashcardDeck> createDeckWithCards({
    required String materialId,
    String? courseId,
    String? departmentId,
    required String title,
    required List<Flashcard> cards,
  }) async {
    final deck = FlashcardDeck(
      materialId: materialId,
      courseId: courseId,
      departmentId: departmentId,
      userId: uid ?? '',
      title: title,
      cardCount: cards.length,
    );

    final row = await _supabase
        .from('flashcard_decks')
        .insert(deck.toSupabase())
        .select()
        .single();

    final stored = FlashcardDeck.fromSupabase(row);

    if (cards.isNotEmpty) {
      await _supabase.from('flashcards').insert([
        for (int i = 0; i < cards.length; i++)
          {
            'deck_id': stored.id,
            'question': cards[i].question,
            'answer': cards[i].answer,
            'position': i,
          },
      ]);
    }

    return stored;
  }

  /// Deletes a deck (its cards cascade).
  Future<void> deleteDeck(String deckId) async {
    await _supabase.from('flashcard_decks').delete().eq('id', deckId);
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

  /// Upgrade user subscription tier. Requires `paymentRef` to point at a
  /// `payment_transactions` row (owned by this user) that the server has
  /// already confirmed as `status='success'` — enforced by the
  /// `grant_subscription` RPC, so this can't be forged by a direct write.
  Future<void> upgradeSubscription(SubscriptionTier tier, {required String paymentRef}) async {
    if (uid == null) return;

    final result = await _supabase.rpc(
      'grant_subscription',
      params: {'p_tier': tier.name, 'p_payment_ref': paymentRef},
    );
    final expiry = DateTime.parse(result as String);

    await NotificationService().createNotification(
      title: 'Subscription Activated',
      body:
          'Your ${tier.name.toUpperCase()} subscription is now active until ${DateFormat.yMMMd().format(expiry)}.',
      type: NotificationType.subscription,
      data: {'tier': tier.name, 'expiry': expiry.toIso8601String()},
    );
  }

  /// Activate the App Plan's one-time free trial month via the
  /// `claim_free_trial` RPC, which is guarded server-side by
  /// `trial_used = false` so it can only ever run once per account.
  Future<void> startFreeMonthlyTrial() async {
    if (uid == null) return;

    DateTime expiry;
    try {
      final result = await _supabase.rpc('claim_free_trial');
      expiry = DateTime.parse(result as String);
    } on PostgrestException catch (e) {
      if (e.message.contains('already used')) {
        throw Exception('Free trial already used');
      }
      rethrow;
    }

    await NotificationService().createNotification(
      title: 'Free Trial Activated',
      body:
          'Your free App Plan month is now active until ${DateFormat.yMMMd().format(expiry)}. AI features are billed separately.',
      type: NotificationType.subscription,
      data: {'tier': SubscriptionTier.monthly.name, 'expiry': expiry.toIso8601String(), 'trial': 'true'},
    );
  }

  /// Activate the separately-purchased Unlimited AI subscription (always
  /// paid, never free). Independent of subscription_tier/subscription_expiry
  /// (the App Plan). Requires `paymentRef` — see [upgradeSubscription].
  Future<void> purchaseAISubscription(SubscriptionTier tier, {required String paymentRef}) async {
    if (uid == null) return;

    final result = await _supabase.rpc(
      'grant_ai_subscription',
      params: {'p_tier': tier.name, 'p_payment_ref': paymentRef},
    );
    final expiry = DateTime.parse(result as String);

    await NotificationService().createNotification(
      title: 'AI Subscription Activated',
      body: 'Your Unlimited AI subscription is now active until ${DateFormat.yMMMd().format(expiry)}.',
      type: NotificationType.subscription,
      data: {'ai_subscription_expiry': expiry.toIso8601String(), 'tier': tier.name},
    );
  }

  /// Increment free download count. Atomic server-side (`increment_free_download_count`
  /// RPC), replacing the previous non-atomic read-then-write from Dart.
  Future<void> incrementFreeDownloadCount() async {
    if (uid == null) return;
    await _supabase.rpc('increment_free_download_count');
  }

  /// Write-once: attaches the payment provider's transaction id to our own
  /// pending `payment_transactions` row right after `collectPayment`
  /// returns one, so the fapshi-proxy edge function can later find this row
  /// by that id alone when it reconciles a confirmed payment server-side.
  Future<void> attachPaymentProviderRef(String paymentRef, String providerTransId) async {
    if (uid == null) return;
    await _supabase
        .from('payment_transactions')
        .update({'fapshi_trans_id': providerTransId})
        .eq('payment_ref', paymentRef)
        .eq('user_id', uid!);
  }

  /// Deduct AI credits from the user's account. Delegates to the
  /// `deduct_ai_credit` Postgres function so the check-and-deduct is a
  /// single atomic operation (row-locked in Postgres) instead of a
  /// read-then-write from Dart, which would let concurrent requests both
  /// pass the balance check before either deduction lands.
  Future<void> useAICredit({int amount = 1}) async {
    if (uid == null) return;

    try {
      await _supabase.rpc('deduct_ai_credit', params: {'p_amount': amount});
    } on PostgrestException catch (e) {
      if (e.message.contains('Insufficient')) {
        throw Exception('Insufficient AI credits');
      }
      rethrow;
    }
  }

  /// Add AI credits to the user's account. Requires `paymentRef` — see
  /// [upgradeSubscription].
  Future<void> addAICredits(int amount, {required String paymentRef}) async {
    if (uid == null) return;

    await _supabase.rpc(
      'grant_ai_credits',
      params: {'p_amount': amount, 'p_payment_ref': paymentRef},
    );

    await NotificationService().createNotification(
      title: 'Credits Added!',
      body: '$amount AI credits have been added to your account.',
      type: NotificationType.system,
    );
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

  /// Get all materials available in the marketplace
  Stream<List<CourseMaterial>> getAllMarketplaceMaterials() {
    return _supabase
        .from("course_materials")
        .stream(primaryKey: ["id"])
        .order("uploaded_at", ascending: false)
        .map(
          (data) =>
              data.map((json) => CourseMaterial.fromSupabase(json)).toList(),
        );
  }

  // --- New Marketplace Listing Methods ---

  /// Get all active marketplace listings
  Stream<List<MarketplaceListing>> getAllMarketplaceListings() {
    return _supabase
        .from('marketplace_listings')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .map((json) => MarketplaceListing.fromSupabase(json))
              .toList(),
        );
  }

  /// Get listings created by a specific user
  Stream<List<MarketplaceListing>> getUserMarketplaceListings(String userId) {
    return _supabase
        .from('marketplace_listings')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .map((json) => MarketplaceListing.fromSupabase(json))
              .toList(),
        );
  }

  /// Add a new marketplace listing
  Future<void> addMarketplaceListing(MarketplaceListing listing) async {
    await _supabase.from('marketplace_listings').insert(listing.toSupabase());
  }

  /// Update a marketplace listing
  Future<void> updateMarketplaceListing(MarketplaceListing listing) async {
    await _supabase
        .from('marketplace_listings')
        .update(listing.toSupabase())
        .eq('id', listing.id);
  }

  /// Delete a marketplace listing
  Future<void> deleteMarketplaceListing(String id) async {
    await _supabase.from('marketplace_listings').delete().eq('id', id);
  }

  /// Get gross earnings for a specific user from all sales (materials & marketplace)
  Stream<double> getGrossEarningsForUploader(String userId) {
    return _supabase
        .from('payment_transactions')
        .stream(primaryKey: ['id'])
        .eq('status', 'success')
        .asyncMap((transactions) async {
          // 1. Get user's material IDs
          final materials = await _supabase
              .from('course_materials')
              .select('id')
              .eq('uploader_id', userId);
          final materialIds = (materials as List)
              .map((m) => m['id'] as String)
              .toList();

          // 2. Get user's listing IDs
          final listings = await _supabase
              .from('marketplace_listings')
              .select('id')
              .eq('vendor_id', userId);
          final listingIds = (listings as List)
              .map((l) => l['id'] as String)
              .toList();

          double total = 0;
          for (var t in transactions) {
            final mId = t['material_id'];
            final lId = t['listing_id'];
            if (mId != null && materialIds.contains(mId)) {
              total += (t['amount'] as num).toDouble();
            } else if (lId != null && listingIds.contains(lId)) {
              total += (t['amount'] as num).toDouble();
            }
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

  // ==================== Custom Bot Knowledge Methods ====================

  /// Get all knowledge entries for a user (including global ones)
  Stream<List<BotKnowledge>> getBotKnowledge(String userId) {
    return _supabase
        .from('bot_knowledge')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((json) => BotKnowledge.fromSupabase(json))
              .where((k) => k.userId == userId || k.isGlobal)
              .toList();
        });
  }

  /// Add a new knowledge entry
  Future<void> addBotKnowledge(BotKnowledge knowledge) async {
    await _supabase.from('bot_knowledge').insert(knowledge.toSupabase());
  }

  /// Delete a knowledge entry
  Future<void> deleteBotKnowledge(String id) async {
    await _supabase.from('bot_knowledge').delete().eq('id', id);
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
          .map(
            (data) =>
                data.map((json) => CampusLocation.fromSupabase(json)).toList(),
          );
    }

    return query
        .order('name')
        .map(
          (data) =>
              data.map((json) => CampusLocation.fromSupabase(json)).toList(),
        );
  }

  // ==================== Admin Management Methods ====================

  /// Search users for admin purposes (can search by name, matricule, or department)
  Future<List<UserProfile>> adminSearchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = await _supabase
          .from('profiles')
          .select()
          .or(
            'name.ilike.%$query%,matricule.ilike.%$query%,department.ilike.%$query%',
          )
          .limit(30);

      return (results as List)
          .map((json) => UserProfile.fromSupabase(json))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Update a user's role
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _supabase
        .from('profiles')
        .update({'role': role.name})
        .eq('id', userId);

    await NotificationService().createNotification(
      title: 'Privileges Updated',
      body: 'Your account role has been updated to ${role.name.toUpperCase()}.',
      type: NotificationType.system,
      recipientId: userId,
      notifySelf: false,
    );
  }

  // ==================== News Feature Methods ====================

  /// Live feed of published news posts, newest first.
  Stream<List<NewsPost>> getNewsFeed() {
    return _supabase
        .from('news_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NewsPost.fromSupabase(json)).toList());
  }

  /// One post by id (used by a push-notification deep link / refresh).
  Future<NewsPost?> getNewsPost(String id) async {
    final data = await _supabase
        .from('news_posts')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return NewsPost.fromSupabase(data);
  }

  /// Live view of a single post by id — lets a detail screen reflect
  /// like_count/comment_count changes made by other users in real time,
  /// instead of staying frozen at the snapshot passed in at navigation time.
  Stream<NewsPost?> getNewsPostStream(String id) {
    return _supabase
        .from('news_posts')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isEmpty ? null : NewsPost.fromSupabase(data.first));
  }

  /// The set of post ids the current user has liked. One cheap stream for the
  /// whole feed — the public like tally lives in `news_posts.like_count`.
  Stream<Set<String>> myLikedNewsPostIds() {
    if (uid == null) return Stream.value(<String>{});
    return _supabase
        .from('news_likes')
        .stream(primaryKey: ['post_id', 'user_id'])
        .eq('user_id', uid!)
        .map((rows) => rows.map((r) => r['post_id'] as String).toSet());
  }

  /// Add or remove the current user's like on [postId]. The `like_count`
  /// column is kept in sync by a DB trigger.
  Future<void> setNewsLike(String postId, bool liked) async {
    if (uid == null) return;
    if (liked) {
      await _supabase.from('news_likes').upsert({
        'post_id': postId,
        'user_id': uid,
      });
    } else {
      await _supabase
          .from('news_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid!);
    }
  }

  /// Live comment thread for a post, oldest first.
  Stream<List<NewsComment>> getNewsComments(String postId) {
    return _supabase
        .from('news_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .map(
          (data) => data.map((json) => NewsComment.fromSupabase(json)).toList(),
        );
  }

  Future<void> addNewsComment({
    required String postId,
    required String content,
    String? authorName,
    String? authorAvatarUrl,
  }) async {
    if (uid == null) return;
    await _supabase.from('news_comments').insert(
      NewsComment(
        postId: postId,
        userId: uid!,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        content: content,
      ).toSupabase(),
    );
  }

  Future<void> deleteNewsComment(String id) async {
    await _supabase.from('news_comments').delete().eq('id', id);
  }

  /// Ids of every profile — the broadcast audience for a new post.
  Future<List<String>> _getAllProfileIds() async {
    final rows = await _supabase.from('profiles').select('id');
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Create a news post (admin only — enforced by RLS) and broadcast it to
  /// every other student: an in-app notification row plus an FCM push for
  /// background/terminated devices. Best-effort — a notification failure
  /// never blocks the post itself (same contract as [createCourse]).
  Future<String> createNewsPost(NewsPost post) async {
    final data = await _supabase
        .from('news_posts')
        .insert(post.toSupabase())
        .select()
        .single();

    final id = data['id'] as String;
    final preview = post.body.length > 140
        ? '${post.body.substring(0, 140).trimRight()}…'
        : post.body;

    try {
      final recipientIds = await _getAllProfileIds();
      await _broadcastCreate(
        recipientIds: recipientIds,
        title: post.title,
        body: preview,
        type: NotificationType.news,
        data: {'newsPostId': id},
        scope: 'all',
        pushTitle: '📰 ${post.title}',
      );
    } catch (_) {
      // Silently ignore — see contract above.
    }

    return id;
  }

  /// Edit an existing post. No re-broadcast.
  Future<void> updateNewsPost(NewsPost post) async {
    await _supabase
        .from('news_posts')
        .update(post.toSupabase())
        .eq('id', post.id);
  }

  /// Delete a post. Its comments and likes cascade away in the DB.
  Future<void> deleteNewsPost(String id) async {
    await _supabase.from('news_posts').delete().eq('id', id);
  }

  /// Upload a news cover image and return its public URL. Reuses the public
  /// `department_images` bucket, like [uploadMarketplaceImage].
  Future<String> uploadNewsImage(Uint8List imageData, String seed) async {
    final cleanName =
        '${DateTime.now().millisecondsSinceEpoch}_${seed.replaceAll(RegExp(r'\s+'), '_')}';
    final path = 'news/$cleanName.jpg';

    await _supabase.storage
        .from('department_images')
        .uploadBinary(
          path,
          imageData,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _supabase.storage.from('department_images').getPublicUrl(path);
  }
}
