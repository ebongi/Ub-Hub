import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/UI/preview/Navigation/home.dart'
    show DepartmentUIData;
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/services/department.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/UI/preview/ComputerCourses/add_department_dialog.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/profile.dart';

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
    final departments = Provider.of<List<Department>?>(context);
    final userModel = Provider.of<UserModel>(context);
    final canCreate = userModel.role == UserRole.contributor || userModel.role == UserRole.admin;

    if (departments == null) {
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
        onRefresh: () async {
          setState(() {
            // Re-trigger build to refresh provider data if necessary
          });
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: const Text('All Departments'),
              floating: true,
              pinned: true,
              snap: false,
              bottom: AppBar(
                automaticallyImplyLeading: false,
                title: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for a department...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
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
                    final uiData = DepartmentUIData.fromDepartmentName(
                      department.name,
                    );
                    final isPending = department.id.startsWith('temp_');
                    
                    return FadeInSlide(
                      delay: index * 0.05,
                      child: GestureDetector(
                        onTap: isPending
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DepartmentScreen(
                                      departmentName: department.name,
                                      departmentId: department.id,
                                    ),
                                  ),
                                ),
                        child: Opacity(
                          opacity: isPending ? 0.6 : 1.0,
                          child: Card(
                            elevation: 4,
                            shadowColor: uiData.primaryColor.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: uiData.primaryColor.withOpacity(0.1),
                                  child: (department.imageUrl != null &&
                                          department.imageUrl!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: department.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: uiData.primaryColor.withOpacity(0.1),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  uiData.primaryColor,
                                                  uiData.secondaryColor,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Icon(
                                              uiData.icon,
                                              size: 40,
                                              color: Colors.white.withOpacity(0.2),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                uiData.primaryColor,
                                                uiData.secondaryColor,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Icon(
                                            uiData.icon,
                                            size: 40,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      stops: const [0.0, 0.4],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Icon(
                                    uiData.icon,
                                    size: 20,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Text(
                                    department.name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
              label: const Text("New Dept"),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }
}
