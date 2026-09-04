import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_grid_card.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/institution.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// Read-only "About this institution" preview — description + a
/// searchable grid of its subjects/departments. Deliberately independent of
/// the shared, user-scoped [DepartmentsProvider] and has no admin "add
/// department" affordance, since it may be showing an institution the
/// signed-in user hasn't selected as their own.
class InstitutionAboutScreen extends StatefulWidget {
  const InstitutionAboutScreen({super.key, required this.institution});

  final Institution institution;

  @override
  State<InstitutionAboutScreen> createState() => _InstitutionAboutScreenState();
}

class _InstitutionAboutScreenState extends State<InstitutionAboutScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final Stream<List<Department>> _departmentStream;

  @override
  void initState() {
    super.initState();
    _departmentStream = DatabaseService().getDepartments(
      institutionId: widget.institution.id,
    );
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final institution = widget.institution;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(institution.name),
            pinned: true,
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          isDark ? 0.15 : 0.08,
                        ),
                        backgroundImage:
                            (institution.logoUrl != null && institution.logoUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(institution.logoUrl!)
                                : null,
                        onBackgroundImageError:
                            (institution.logoUrl != null && institution.logoUrl!.isNotEmpty)
                                ? (_, __) {}
                                : null,
                        child: (institution.logoUrl == null || institution.logoUrl!.isEmpty)
                            ? Icon(
                                Icons.account_balance_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              institution.name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                              ),
                              child: Text(
                                l10n.institutionTypeUniversityBadge,
                                style: AppText.caption(context).copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((institution.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MarkdownBody(
                      data: institution.description!,
                      styleSheet: MarkdownStyleSheet(
                        h1: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
                        h2: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                        p: GoogleFonts.outfit(fontSize: 14, height: 1.5),
                        listBullet: GoogleFonts.outfit(fontSize: 14),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    l10n.sectionDepartmentsFaculties,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: AppText.body(context),
                    decoration: InputDecoration(
                      hintText: l10n.searchForDepartmentHint,
                      hintStyle: AppText.body(context).copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor:
                          isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            isDark ? 0.4 : 0.6,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            isDark ? 0.4 : 0.6,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Department>>(
            stream: _departmentStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: GridShimmer());
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(l10n.errorLoadingMessages(snapshot.error.toString())),
                    ),
                  ),
                );
              }

              final departments = snapshot.data ?? [];
              final filtered = departments
                  .where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text(l10n.noDepartmentsAvailable)),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(10.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final department = filtered[index];
                      return FadeInSlide(
                        delay: index * 0.05,
                        child: DepartmentGridCard(
                          department: department,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepartmentScreen(
                                departmentName: department.name,
                                departmentId: department.id,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
