import 'package:flutter/material.dart';
import 'package:go_study/Screens/UI/preview/Navigation/home.dart'
    show NoInternetWidget;
import 'package:go_study/Screens/UI/preview/detailScreens/department_grid_card.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/departments_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/UI/preview/ComputerCourses/add_department_dialog.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

class AllDepartmentsScreen extends StatefulWidget {
  const AllDepartmentsScreen({super.key});

  @override
  State<AllDepartmentsScreen> createState() => _AllDepartmentsScreenState();
}

class _AllDepartmentsScreenState extends State<AllDepartmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Department> _optimisticDepartments = [];

  void _addDepartment() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    showAddDepartmentDialog(
      context,
      defaultSchoolId: userModel.institutionId,
      onOptimisticCreate: (dept) {
        setState(() {
          _optimisticDepartments.add(dept);
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
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
    final departmentsProvider = Provider.of<DepartmentsProvider>(context);
    final departments = departmentsProvider.departments;
    final userModel = Provider.of<UserModel>(context);
    final canCreate = userModel.role == UserRole.admin;
    final screenTitle = l10n.allDepartmentsTitle;

    if (departments == null) {
      if (departmentsProvider.hasError) {
        return Scaffold(
          appBar: AppBar(title: Text(screenTitle)),
          body: NoInternetWidget(onRetry: departmentsProvider.retry),
        );
      }
      return const Scaffold(body: GridShimmer());
    }

    final serverDepartments = departments;
    
    // Reconciliation: Remove optimistic depts only if they are confirmed locally or exist in server data
    _optimisticDepartments.removeWhere((optimistic) =>
        serverDepartments.any((server) => 
          server.name == optimistic.name && server.schoolId == optimistic.schoolId));

    final allDepartments = [..._optimisticDepartments, ...serverDepartments];

    final filteredDepartments = allDepartments.where((dept) {
      final deptName = dept.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return deptName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: departmentsProvider.retry,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: Text(screenTitle, style: AppText.sectionTitle(context)),
              floating: true,
              pinned: true,
              snap: false,
              bottom: AppBar(
                automaticallyImplyLeading: false,
                title: Container(
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(isDark ? 0.4 : 0.6),
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _searchController,
                      style: AppText.body(context),
                      decoration: InputDecoration(
                        isDense: true,
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
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
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
                    final department = filteredDepartments[index];
                    final isPending = department.id.startsWith('temp_');

                    return FadeInSlide(
                      delay: index * 0.05,
                      child: DepartmentGridCard(
                        department: department,
                        isPending: isPending,
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
                  childCount: filteredDepartments.length,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _addDepartment,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.newDeptButton),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              extendedTextStyle: AppText.cardTitle(context).copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            )
          : null,
    );
  }
}
