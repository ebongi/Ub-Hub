import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/course_material.dart';

import 'package:go_study/services/course_model.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/fapshi_service.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/storage_service.dart';
import 'package:go_study/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final DatabaseService _dbService;
  UserProfile? _userProfile;

  late final Stream<List<CourseMaterial>> _materialStream;
  final List<CourseMaterial> _optimisticMaterials = [];

  @override
  void initState() {
    super.initState();
    final currentUser = Supabase.instance.client.auth.currentUser;
    _dbService = DatabaseService(uid: currentUser?.id);

    _materialStream = _dbService.getCourseMaterials(widget.course.id);

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.course.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.forum_outlined, color: theme.colorScheme.primary),
            tooltip: l10n.joinDiscussionTooltip,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  roomId: widget.course.id,
                  title: l10n.courseDiscussionTitle(widget.course.code),
                  subtitle: l10n.courseDiscussionRoomSubtitle,
                ),
              ),
            ),
          ),
          if (_userProfile?.canUploadMaterial ?? false)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showUploadSelection(),
            ),
        ],
      ),
      body: StreamBuilder<List<CourseMaterial>>(
        stream: _materialStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _optimisticMaterials.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorLoadingMessages(snapshot.error.toString())));
          }

          final serverMaterials = snapshot.data ?? [];

          // Reconciliation
          _optimisticMaterials.removeWhere(
            (optimistic) => serverMaterials.any(
              (server) => server.title == optimistic.title,
            ),
          );

          final allMaterials = [..._optimisticMaterials, ...serverMaterials];

          if (allMaterials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMaterialsYetMessage,
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final regularMaterials = allMaterials
              .where((m) => m.materialCategory == 'regular')
              .toList();
          final questions = allMaterials
              .where((m) => m.materialCategory == 'past_question')
              .toList();
          final answers = allMaterials
              .where((m) => m.materialCategory == 'answer')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (regularMaterials.isNotEmpty) ...[
                _buildHeader(l10n.generalResourcesHeader),
                ...regularMaterials.map((m) => _buildMaterialTile(m)),
              ],
              if (questions.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildHeader(l10n.pastQuestionsAndAnswersHeader),
                ...questions.map((q) {
                  final relatedAnswers = answers
                      .where((a) => a.linkedMaterialId == q.id)
                      .toList();
                  return _buildPastQuestionTile(q, relatedAnswers);
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;
    switch (category) {
      case 'past_question':
        color = Colors.orange;
        label = l10n.pqBadge;
        break;
      case 'answer':
        color = Colors.green;
        label = l10n.ansBadge;
        break;
      default:
        color = Colors.blue;
        label = l10n.docBadge;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.white70 : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMaterialTile(CourseMaterial material) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final isPdf = material.fileType.toLowerCase() == 'pdf';
    final isPending = material.id.isEmpty || material.id.startsWith('temp_');

    return Opacity(
      opacity: isPending ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.15),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPdf ? Colors.red : Colors.blue).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.description_outlined,
              color: isPdf ? Colors.red[400] : Colors.blue[400],
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  material.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isPending)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              const SizedBox(width: 8),
              _buildCategoryBadge(material.materialCategory),
            ],
          ),
          subtitle:
              material.description != null && material.description!.isNotEmpty
              ? Text(
                  material.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                )
              : null,
          trailing:
              (material.uploaderId == _dbService.uid ||
                  widget.course.adminId == _dbService.uid)
              ? PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : theme.colorScheme.primary,
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.deleteMaterialDialogTitle),
                          content: Text(
                            l10n.confirmDeleteMaterialBody(material.title),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                l10n.deleteButton,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _dbService.deleteMaterial(material.id);
                        if (mounted) {
                          ErrorHandler.showSuccessSnackBar(
                            context,
                            l10n.materialDeletedMessage,
                          );
                        }
                      }
                    } else if (value == 'download') {
                      _handleDownload(material);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          const Icon(Icons.download_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.downloadMenuItem),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.deleteButton, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              : IconButton(
                  icon: Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: isPending
                        ? Colors.grey
                        : (isDark ? Colors.white70 : theme.colorScheme.primary),
                  ),
                  onPressed: isPending ? null : () => _handleDownload(material),
                ),
          onTap: isPending
              ? null
              : () {
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
      ),
    );
  }

  Future<void> _handleDownload(CourseMaterial material) async {
    // Secure for offline use
    await _secureForOffline(material);

    final uri = Uri.parse(material.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          "Could not launch download link",
        );
      }
    }
  }

  Future<void> _secureForOffline(CourseMaterial material) async {
    try {
      await StorageService().downloadAndEncrypt(
        material.fileUrl,
        material.id,
        material.fileName,
      );
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          AppLocalizations.of(context)!.materialSecuredOfflineMessage,
        );
      }
    } catch (e) {
      print("Offline cache failed: $e");
    }
  }

  Widget _buildPastQuestionTile(
    CourseMaterial question,
    List<CourseMaterial> relatedAnswers,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.help_outline_rounded,
            color: Colors.orange[400],
            size: 20,
          ),
        ),
        title: Text(
          question.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          l10n.pastQuestionAnswersCountSubtitle(relatedAnswers.length),
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing:
            (question.uploaderId == _dbService.uid ||
                widget.course.adminId == _dbService.uid)
            ? PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white70 : colorScheme.primary,
                  size: 20,
                ),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deletePastQuestionDialogTitle),
                        content: Text(
                          l10n.confirmDeleteMaterialBody(question.title),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              l10n.deleteButton,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _dbService.deleteMaterial(question.id);
                      if (mounted) {
                        ErrorHandler.showSuccessSnackBar(
                          context,
                          l10n.pastQuestionDeletedMessage,
                        );
                      }
                    }
                  } else if (value == 'download') {
                    _handleDownload(question);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        const Icon(Icons.download_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.downloadMenuItem),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.deleteButton, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : IconButton(
                icon: Icon(
                  Icons.download_rounded,
                  color: isDark ? Colors.white70 : colorScheme.primary,
                  size: 20,
                ),
                onPressed: () => _handleDownload(question),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (relatedAnswers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      l10n.noAnswersUploadedYet,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  )
                else
                  ...relatedAnswers.map(
                    (a) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green[400],
                        size: 20,
                      ),
                      title: Text(
                        a.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        l10n.verifiedAnswerFeeSubtitle(FapshiService.getAnswerDownloadFee().toInt()),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : colorScheme.primary,
                        ),
                        onPressed: () => _handleDownload(a),
                      ),
                      onTap: () {
                        if (a.fileType.toLowerCase() == 'pdf') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PDFViewerScreen(
                                url: a.fileUrl,
                                title: a.title,
                              ),
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
          ),
        ],
      ),
    );
  }

  Future<void> _addMaterial({
    String? initialCategory,
    String? initialQuestionId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_userProfile?.canUploadMaterial ?? false)) {
      ErrorHandler.showErrorSnackBar(
        context,
        l10n.onlyContributorsCanUploadMessage,
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    FilePickerResult? result;
    String selectedCategory = initialCategory ?? 'regular';
    String? selectedQuestionId = initialQuestionId;

    await showPremiumGeneralDialog(
      context: context,
      barrierLabel: l10n.addMaterialTitle,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              surfaceTintColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumDialogHeader(
                      title: l10n.addMaterialTitle,
                      subtitle: l10n.shareResourcesSubtitle,
                      icon: Icons.note_add_rounded,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            PremiumDropdownField<String>(
                              value: selectedCategory,
                              label: l10n.categoryLabel,
                              hint: l10n.selectCategoryHint,
                              icon: Icons.category_rounded,
                              items: [
                                DropdownMenuItem(
                                  value: 'regular',
                                  child: Text(l10n.generalMaterialOption),
                                ),
                                DropdownMenuItem(
                                  value: 'past_question',
                                  child: Text(l10n.pastQuestionOption),
                                ),
                                DropdownMenuItem(
                                  value: 'answer',
                                  child: Text(l10n.answerOption),
                                ),
                              ],
                              onChanged: (v) {
                                setDialogState(() {
                                  selectedCategory = v!;
                                  if (selectedCategory != 'answer') {
                                    selectedQuestionId = null;
                                  }
                                });
                              },
                            ),
                            if (selectedCategory == 'answer') ...[
                              const SizedBox(height: 16),
                              StreamBuilder<List<CourseMaterial>>(
                                stream: _materialStream,
                                builder: (context, snapshot) {
                                  final questions =
                                      snapshot.data
                                          ?.where(
                                            (m) =>
                                                m.materialCategory ==
                                                'past_question',
                                          )
                                          .toList() ??
                                      [];
                                  return PremiumDropdownField<String>(
                                    value: selectedQuestionId,
                                    label: l10n.linkToQuestionLabel,
                                    hint: l10n.selectTheQuestionHint,
                                    icon: Icons.link_rounded,
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
                                    onChanged: (v) => setDialogState(
                                      () => selectedQuestionId = v,
                                    ),
                                    validator: (v) =>
                                        selectedCategory == 'answer' &&
                                            v == null
                                        ? l10n.requiredValidator
                                        : null,
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            PremiumTextField(
                              controller: titleController,
                              label: l10n.titleLabel,
                              hint: l10n.titleHintExample,
                              icon: Icons.title_rounded,
                              validator: (v) =>
                                  v == null || v.isEmpty ? l10n.requiredValidator : null,
                            ),
                            const SizedBox(height: 16),
                            PremiumTextField(
                              controller: descriptionController,
                              label: l10n.descriptionOptionalLabel,
                              hint: l10n.brieflyDescribeContentHint,
                              icon: Icons.description_rounded,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),
                            // Premium File Selection Zone
                            GestureDetector(
                              onTap: () async {
                                final res = await FilePicker.platform.pickFiles(
                                  withData: true,
                                );
                                if (res != null) {
                                  setDialogState(() => result = res);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: result != null
                                      ? Colors.green.withOpacity(
                                          isDark ? 0.1 : 0.05,
                                        )
                                      : (isDark
                                            ? Colors.white.withOpacity(0.04)
                                            : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: result != null
                                        ? Colors.green.withOpacity(0.3)
                                        : (isDark
                                              ? Colors.white10
                                              : Colors.black12),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      result != null
                                          ? Icons.check_circle_rounded
                                          : Icons.cloud_upload_outlined,
                                      size: 32,
                                      color: result != null
                                          ? Colors.green
                                          : theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      result != null
                                          ? result!.files.single.name
                                          : l10n.selectMaterialFileLabel,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      result != null
                                          ? l10n.fileSelectedSuccessfully
                                          : (selectedCategory == 'past_question'
                                                ? l10n.uploadPdfOrWordHint
                                                : l10n.supportsPdfDocImagesHint),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      l10n.cancel,
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: PremiumSubmitButton(
                                    label: l10n.uploadMaterialButton,
                                    isLoading: false,
                                    onPressed: () {
                                      if (formKey.currentState!.validate() &&
                                          result != null) {
                                        final tempMaterial = CourseMaterial(
                                          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                          title: titleController.text,
                                          description:
                                              descriptionController.text,
                                          fileUrl: '',
                                          fileName: result!.files.single.name,
                                          fileType:
                                              result!.files.single.extension ??
                                              'file',
                                          uploadedAt: DateTime.now(),
                                          courseId: widget.course.id,
                                          departmentId:
                                              widget.course.departmentId,
                                          materialCategory: selectedCategory,
                                          isPastQuestion:
                                              selectedCategory ==
                                              'past_question',
                                          isAnswer:
                                              selectedCategory == 'answer',
                                          linkedMaterialId: selectedQuestionId,
                                          uploaderId: _dbService.uid,
                                        );

                                        setState(() {
                                          _optimisticMaterials.add(
                                            tempMaterial,
                                          );
                                        });

                                        Navigator.pop(context);

                                        _uploadLogic(
                                          title: titleController.text,
                                          desc: descriptionController.text,
                                          result: result!,
                                          category: selectedCategory,
                                          linkedId: selectedQuestionId,
                                        );
                                      } else if (result == null) {
                                        ErrorHandler.showErrorSnackBar(
                                          context,
                                          l10n.pleaseSelectFileMessage,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadLogic({
    required String title,
    required String desc,
    required FilePickerResult result,
    String category = 'regular',
    String? linkedId,
  }) async {
    try {
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw "Could not read file";

      final url = await _dbService.uploadMaterialFile(
        bytes,
        widget.course.code,
        file.name,
        false,
      );

      final material = CourseMaterial(
        title: title,
        description: desc,
        fileUrl: url,
        fileName: file.name,
        fileType: file.extension ?? 'file',
        uploadedAt: DateTime.now(),
        courseId: widget.course.id,
        departmentId: widget.course.departmentId,
        materialCategory: category,
        isPastQuestion: category == 'past_question',
        isAnswer: category == 'answer',
        linkedMaterialId: linkedId,
        uploaderId: _dbService.uid,
      );

      await _dbService.addMaterial(material);

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, AppLocalizations.of(context)!.uploadSuccessfulMessage);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _showUploadSelection() {
    final l10n = AppLocalizations.of(context)!;
    if (!(_userProfile?.canUploadMaterial ?? false)) {
      ErrorHandler.showErrorSnackBar(
        context,
        l10n.onlyContributorsCanUploadMessage,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.uploadMaterialButton,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectMaterialTypeSubtitle,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  ),
                  _buildUgcGuidelinesCard(Theme.of(context)),
                  const SizedBox(height: 12),
                  _buildUploadOption(
                    icon: Icons.note_add_rounded,
                    color: Colors.blue,
                    title: l10n.generalResourcesHeader,
                    subtitle: l10n.lectureNotesSubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      _addMaterial(initialCategory: 'regular');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildUploadOption(
                    icon: Icons.history_edu_rounded,
                    color: Colors.orange,
                    title: l10n.pastQuestionOption,
                    subtitle: l10n.previousExamPapersSubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      _addMaterial(initialCategory: 'past_question');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildUploadOption(
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    title: l10n.verifiedAnswerTitle,
                    subtitle: l10n.solutionsToPastQuestionsSubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      _addMaterial(initialCategory: 'answer');
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUgcGuidelinesCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.communityContributionCodeTitle,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem(
            Icons.done_all_rounded,
            l10n.guidelineReadableContent,
            theme,
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(
            Icons.find_in_page_rounded,
            l10n.guidelineCheckDuplicate,
            theme,
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(
            Icons.school_rounded,
            l10n.guidelineAcademicOnly,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
