import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:neo/Screens/UI/preview/Navigation/home.dart';
import 'package:neo/Screens/UI/preview/Navigation/settings_screen.dart';
import 'package:neo/Screens/UI/preview/detailScreens/all_departments_screen.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/department.dart';
import 'package:provider/provider.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const Home(),
    const AllDepartmentsScreen(),
    const Center(child: Text('Profile Screen (Placeholder)')),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return StreamProvider<List<Department>?>.value(
      value: DatabaseService().departments,
      initialData: null,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: theme.splashColor,
              hoverColor: theme.hoverColor,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.blue.shade700,
              color: isDarkMode ? Colors.white70 : Colors.black,
              tabs: const [
                GButton(icon: Icons.home_outlined, text: 'Home'),
                GButton(icon: Icons.school_outlined, text: 'Departments'),
                GButton(icon: Icons.person_outline, text: 'Profile'),
                GButton(icon: Icons.settings_outlined, text: 'Settings'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
      ),
    );
  }
}