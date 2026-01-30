import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:neo/Screens/UI/preview/Navigation/home.dart';
import 'package:neo/Screens/UI/preview/Chatbot/chatbot_screen.dart';
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

  final List<Widget> _widgetOptions = <Widget>[
    const Home(),
    const AllDepartmentsScreen(),
    const ChatbotScreen(),
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
        body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 8,
              ),
              child: GNav(
                rippleColor: isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05),
                hoverColor: isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05),
                gap: 8,
                activeColor: isDarkMode
                    ? Colors.cyanAccent
                    : theme.colorScheme.primary,
                iconSize: 24,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: isDarkMode
                    ? Colors.cyanAccent.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
                color: isDarkMode ? Colors.white38 : Colors.grey[600],
                tabs: const [
                  GButton(icon: Icons.home_rounded, text: 'Home'),
                  GButton(icon: Icons.grid_view_rounded, text: 'Depts'),
                  GButton(icon: Icons.smart_toy_rounded, text: 'AI Buddy'),
                  GButton(icon: Icons.settings_rounded, text: 'Settings'),
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
