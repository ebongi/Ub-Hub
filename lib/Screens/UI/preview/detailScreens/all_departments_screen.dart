import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/Navigation/home.dart'
    show DepartmentUIData;
import 'package:neo/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:neo/services/department.dart';
import 'package:provider/provider.dart';

class AllDepartmentsScreen extends StatefulWidget {
  const AllDepartmentsScreen({super.key});

  @override
  State<AllDepartmentsScreen> createState() => _AllDepartmentsScreenState();
}

class _AllDepartmentsScreenState extends State<AllDepartmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

    if (departments == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredDepartments = departments.where((dept) {
      final deptName = dept.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return deptName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
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
                maxCrossAxisExtent:
                    200.0, // Each item will have a max width of 200
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.8, // Adjust aspect ratio as needed
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final department = filteredDepartments[index];
                final uiData = DepartmentUIData.fromDepartmentName(
                  department.name,
                );
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DepartmentScreen(
                        departmentName: department.name,
                        departmentId: department.id,
                      ),
                    ),
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: uiData.color.withOpacity(0.1),
                          child:
                              (department.imageUrl != null &&
                                  department.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  department.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  uiData.icon,
                                  size: 40,
                                  color: uiData.color.withOpacity(0.5),
                                ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Text(
                            department.name,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: filteredDepartments.length),
            ),
          ),
        ],
      ),
    );
  }
}
