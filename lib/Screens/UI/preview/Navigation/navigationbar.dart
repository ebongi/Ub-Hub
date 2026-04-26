import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_study/Screens/UI/preview/Navigation/home.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/chatbot_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/dm_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/settings_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/all_departments_screen.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const Home(),
    const AllDepartmentsScreen(),
    const ChatbotScreen(),
    const DmScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width >= 600;

    final userModel = Provider.of<UserModel>(context);
    final institutionId = userModel.institutionId;

    final selectedColor = isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary;
    final unselectedColor = isDarkMode ? Colors.white38 : Colors.grey[500]!;

    Widget buildBottomBar() {
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            activeIcon: Icon(Iconsax.home_1_copy), // Bold/filled version
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.folder_cloud),
            activeIcon: Icon(Iconsax.folder_cloud_copy), // Bold version
            label: 'Departments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.teacher),
            activeIcon: Icon(Iconsax.teacher_copy), // Bold version
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.message),
            activeIcon: Icon(Iconsax.message_2_copy), // Bold version
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.setting),
            activeIcon: Icon(Iconsax.setting_2_copy), // Bold version
            label: 'Settings',
          ),
        ],
      );
    }

    Widget buildNavRail() {
      return NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelType: NavigationRailLabelType.all,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedIconTheme: IconThemeData(color: selectedColor),
        unselectedIconTheme: IconThemeData(color: unselectedColor),
        selectedLabelTextStyle: TextStyle(
          color: selectedColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: unselectedColor,
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        destinations: [
          _buildRailDestination(Iconsax.home, Iconsax.home_1_copy, 'Home'),
          _buildRailDestination(Iconsax.folder_cloud, Iconsax.folder_cloud_copy, 'Departments'),
          _buildRailDestination(Iconsax.teacher, Iconsax.teacher_copy, 'AI Assistant'),
          _buildRailDestination(Iconsax.message, Iconsax.message_2_copy, 'Messages'),
          _buildRailDestination(Iconsax.setting, Iconsax.setting_2_copy, 'Settings'),
        ],
      );
    }

    return StreamProvider<List<Department>?>.value(
      value: DatabaseService().getDepartments(institutionId: institutionId),
      initialData: null,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            if (isLargeScreen) buildNavRail(),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _widgetOptions),
            ),
          ],
        ),
        bottomNavigationBar: isLargeScreen ? null : buildBottomBar(),
      ),
    );
  }

  // Helper for NavigationRail
  NavigationRailDestination _buildRailDestination(
      IconData unselectedIcon,
      IconData selectedIcon,
      String label,
      ) {
    return NavigationRailDestination(
      icon: Icon(unselectedIcon),
      selectedIcon: Icon(selectedIcon),
      label: Text(label),
    );
  }
}