import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:neo/Screens/UI/preview/Navigation/home.dart';
import 'package:neo/Screens/UI/preview/Navigation/settings_screen.dart';
import 'package:neo/Screens/UI/preview/detailScreens/all_departments_screen.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/department.dart';
import 'package:provider/provider.dart';

import 'package:google_fonts/google_fonts.dart';

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

    return StreamProvider<List<Department>?>.value(
      value: DatabaseService().departments,
      initialData: null,
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: GNav(
                rippleColor: theme.colorScheme.primary.withOpacity(0.1),
                hoverColor: theme.colorScheme.primary.withOpacity(0.1),
                gap: 8,
                activeColor: theme.colorScheme.primary,
                iconSize: 24,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                color: const Color(0xFF64748B), // Slate 500 for inactive
                tabs: const [
                  GButton(icon: Icons.grid_view_rounded, text: 'Dashboard'),
                  GButton(icon: Icons.school_rounded, text: 'Academics'),
                  GButton(icon: Icons.person_rounded, text: 'Profile'),
                  GButton(icon: Icons.settings_rounded, text: 'Settings'),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: _onItemTapped,
                textStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
