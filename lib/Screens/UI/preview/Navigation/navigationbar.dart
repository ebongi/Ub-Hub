import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_study/Screens/UI/preview/Navigation/home.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/chatbot_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/dm_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/settings_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/all_departments_screen.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';

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

    final userModel = Provider.of<UserModel>(context);
    final institutionId = userModel.institutionId;

    return StreamProvider<List<Department>?>.value(
      value: DatabaseService().getDepartments(institutionId: institutionId),
      initialData: null,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: isDarkMode
              ? Colors.cyanAccent
              : theme.colorScheme.primary,
          unselectedItemColor: isDarkMode ? Colors.white38 : Colors.grey[500],
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/home.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white38 : Colors.grey[500]!,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/home.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/department.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white38 : Colors.grey[500]!,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/department.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Departments',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons8-ai.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white38 : Colors.grey[500]!,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/icons8-ai.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'AI Assistant',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/message.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white38 : Colors.grey[500]!,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/message.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/settings.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white38 : Colors.grey[500]!,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/settings.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.cyanAccent : theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
