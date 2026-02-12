import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
import 'package:neo/services/course_material.dart';
import 'package:neo/services/course_model.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/nkwa_service.dart';
import 'package:neo/services/payment_models.dart';
import 'package:neo/services/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final DatabaseService _dbService;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    final currentUser = Supabase.instance.client.auth.currentUser;
    _dbService = DatabaseService(uid: currentUser?.id);

    _dbService.userProfile.listen((profile) {
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_userProfile?.canUpload ?? false)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showUploadSelection(),
            ),
        ],
      ),
      body: StreamBuilder<List<CourseMaterial>>(
        stream: _dbService.getCourseMaterials(widget.course.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No materials for this course yet.",
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final materials = snapshot.data!;
          final regularMaterials = materials
              .where((m) => m.materialCategory == 'regular')
              .toList();
          final questions = materials
              .where((m) => m.materialCategory == 'past_question')
              .toList();
          final answers = materials
              .where((m) => m.materialCategory == 'answer')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (regularMaterials.isNotEmpty) ...[
                _buildHeader("General Resources"),
                ...regularMaterials.map((m) => _buildMaterialTile(m)),
              ],
              if (questions.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildHeader("Past Questions & Answers"),
                ...questions.map((q) {
                  final relatedAnswers = answers
                      .where((a) => a.linkedMaterialId == q.id)
                      .toList();
                  return _buildPastQuestionTile(q, relatedAnswers);
                }),
              ],
              if (regularMaterials.isEmpty && questions.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No materials for this course yet.",
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildMaterialTile(CourseMaterial material) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          material.fileType == 'pdf'
              ? Icons.picture_as_pdf
              : Icons.insert_drive_file,
          color: Colors.red,
        ),
        title: Text(
          material.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        subtitle: material.description != null
            ? Text(
                material.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _handleDownload(material),
        ),
        onTap: () {
          if (material.fileType.toLowerCase() == 'pdf') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PDFViewerScreen(
                  url: material.fileUrl,
                  title: material.title,
                ),
              ),
            );
          } else {
            _handleDownload(material);
          }
        },
      ),
    );
  }

  Future<void> _handleDownload(CourseMaterial material) async {
    // If user is a contributor or admin, skip payment and download directly
    if (_userProfile?.role == UserRole.contributor ||
        _userProfile?.role == UserRole.admin) {
      final uri = Uri.parse(material.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch download link")),
          );
        }
      }
      return;
    }

    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    double fee = NkwaService.getDocumentDownloadFee();
    if (material.materialCategory == 'past_question') {
      fee = NkwaService.getPastQuestionDownloadFee();
    } else if (material.materialCategory == 'answer') {
      fee = NkwaService.getAnswerDownloadFee();
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Download Material"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "To download \"${material.title}\" (${material.materialCategory.replaceAll('_', ' ')}), a fee of ${fee.toInt()} XAF is required.",
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  enabled: !isProcessing,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Payment Phone",
                    hintText: "6xxxxxxxx",
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isProcessing = true);
                      try {
                        await _processDownloadPayment(
                          material,
                          phoneController.text,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() => isProcessing = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Pay & Download"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processDownloadPayment(
    CourseMaterial material,
    String phoneNumber,
  ) async {
    final userId = _dbService.uid;
    if (userId == null) throw "User not authenticated";

    final paymentRef = NkwaService.generatePaymentRef();
    double amount = NkwaService.getDocumentDownloadFee();
    if (material.materialCategory == 'past_question') {
      amount = NkwaService.getPastQuestionDownloadFee();
    } else if (material.materialCategory == 'answer') {
      amount = NkwaService.getAnswerDownloadFee();
    }
    final formattedPhone = NkwaService.formatPhoneNumber(phoneNumber);

    // 1. Create pending transaction
    final transaction = PaymentTransaction(
      id: '',
      userId: userId,
      paymentRef: paymentRef,
      amount: amount,
      currency: NkwaService.getCurrency(),
      status: PaymentStatus.pending,
      materialId: material.id,
      itemType: 'download',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbService.createPaymentTransaction(transaction);

    // 2. Initiate Payment
    final collectResponse = await NkwaService.collectPayment(
      amount: amount,
      phoneNumber: formattedPhone,
      description: 'Download: ${material.title}',
    );

    final nkwaPaymentId = collectResponse['id'] ?? collectResponse['paymentId'];
    if (nkwaPaymentId == null) throw "Failed to initiate payment";

    // 3. Poll
    PaymentStatus status = PaymentStatus.pending;
    int attempts = 0;
    while (status == PaymentStatus.pending && attempts < 60) {
      await Future.delayed(const Duration(seconds: 3));
      status = await NkwaService.checkPaymentStatus(nkwaPaymentId.toString());
      attempts++;
    }

    // 4. Update status
    await _dbService.updatePaymentStatus(
      paymentRef,
      status,
      materialId: material.id,
    );

    if (status == PaymentStatus.success) {
      final uri = Uri.parse(material.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch download link';
      }
    } else {
      throw "Payment failed or timed out.";
    }
  }

  Widget _buildPastQuestionTile(
    CourseMaterial question,
    List<CourseMaterial> relatedAnswers,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: Colors.orange),
        title: Text(
          question.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Past Question • ${relatedAnswers.length} Answers",
          style: GoogleFonts.outfit(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _handleDownload(question),
        ),
        children: [
          if (relatedAnswers.isEmpty)
            const ListTile(
              dense: true,
              title: Text(
                "No answers uploaded yet",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            )
          else
            ...relatedAnswers.map(
              (a) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 18,
                ),
                title: Text(a.title, style: GoogleFonts.outfit(fontSize: 13)),
                subtitle: const Text(
                  "Answer • 300 XAF",
                  style: TextStyle(fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download, size: 18),
                  onPressed: () => _handleDownload(a),
                ),
                onTap: () {
                  if (a.fileType.toLowerCase() == 'pdf') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PDFViewerScreen(url: a.fileUrl, title: a.title),
                      ),
                    );
                  } else {
                    _handleDownload(a);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addMaterial({
    String? initialCategory,
    String? initialQuestionId,
  }) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    FilePickerResult? result;
    bool isLoading = false;
    String selectedCategory = initialCategory ?? 'regular';
    String? selectedQuestionId = initialQuestionId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Course Material"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: const [
                      DropdownMenuItem(
                        value: 'regular',
                        child: Text("General"),
                      ),
                      DropdownMenuItem(
                        value: 'past_question',
                        child: Text("Past Question"),
                      ),
                      DropdownMenuItem(value: 'answer', child: Text("Answer")),
                    ],
                    onChanged: (v) {
                      setState(() {
                        selectedCategory = v!;
                        if (selectedCategory != 'answer') {
                          selectedQuestionId = null;
                        }
                      });
                    },
                  ),
                  if (selectedCategory == 'answer') ...[
                    const SizedBox(height: 10),
                    StreamBuilder<List<CourseMaterial>>(
                      stream: _dbService.getCourseMaterials(widget.course.id),
                      builder: (context, snapshot) {
                        final questions =
                            snapshot.data
                                ?.where(
                                  (m) => m.materialCategory == 'past_question',
                                )
                                .toList() ??
                            [];
                        return DropdownButtonFormField<String>(
                          value: selectedQuestionId,
                          decoration: const InputDecoration(
                            labelText: "Link to Question",
                            hintText: "Select the question this answer is for",
                          ),
                          items: questions
                              .map(
                                (q) => DropdownMenuItem(
                                  value: q.id,
                                  child: Text(
                                    q.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => selectedQuestionId = v),
                          validator: (v) =>
                              selectedCategory == 'answer' && v == null
                              ? "Required for answers"
                              : null,
                        );
                      },
                    ),
                  ],
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 20),
                  result == null
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles(
                              withData: true,
                            );
                            if (res != null) setState(() => result = res);
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text("Select File"),
                        )
                      : Text("Selected: ${result!.files.single.name}"),
                  const SizedBox(height: 8),
                  const Text(
                    "Note: Uploads are now free!",
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate() && result != null) {
                        setState(() => isLoading = true);
                        try {
                          final file = result!.files.single;
                          final url = await _dbService.uploadMaterialFile(
                            file.bytes!,
                            widget.course.code,
                            file.name,
                            false,
                          );

                          final material = CourseMaterial(
                            title: titleController.text,
                            description: descriptionController.text,
                            fileUrl: url,
                            fileName: file.name,
                            fileType: file.extension ?? 'file',
                            uploadedAt: DateTime.now(),
                            courseId: widget.course.id,
                            materialCategory: selectedCategory,
                            isPastQuestion: selectedCategory == 'past_question',
                            isAnswer: selectedCategory == 'answer',
                            linkedMaterialId: selectedQuestionId,
                          );

                          await _dbService.addMaterial(material);
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        } finally {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text("Upload General Material"),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(initialCategory: 'regular');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_edu, color: Colors.orange),
              title: const Text("Upload Past Question"),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(initialCategory: 'past_question');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Upload Answer"),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(initialCategory: 'answer');
              },
            ),
          ],
        ),
      ),
    );
  }
}
