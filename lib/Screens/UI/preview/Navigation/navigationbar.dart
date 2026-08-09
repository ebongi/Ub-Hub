import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_study/Screens/UI/preview/Navigation/home.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/chatbot_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/dm_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/settings_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/all_departments_screen.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/friends_service.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/message_provider.dart';
import 'package:go_study/services/notification_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class NavBar extends StatefulWidget {
  final int initialIndex;
  const NavBar({super.key, this.initialIndex = 0});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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
    final l10n = AppLocalizations.of(context)!;
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.home),
            activeIcon: const Icon(Iconsax.home_1_copy), // Bold/filled version
            label: l10n.navHomeLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.folder_cloud),
            activeIcon: const Icon(Iconsax.folder_cloud_copy), // Bold version
            label: l10n.navDepartmentsLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.teacher),
            activeIcon: const Icon(Iconsax.teacher_copy), // Bold version
            label: l10n.navAiAssistantLabel,
          ),
          BottomNavigationBarItem(
            icon: Consumer3<MessageProvider, List<FriendRequest>?, int>(
              builder: (context, messageProvider, requests, unreadNotifications, child) {
                final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
                return Badge(
                  label: Text('$totalBadge'),
                  isLabelVisible: totalBadge > 0,
                  child: const Icon(Iconsax.message),
                );
              },
            ),
            activeIcon: Consumer3<MessageProvider, List<FriendRequest>?, int>(
              builder: (context, messageProvider, requests, unreadNotifications, child) {
                final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
                return Badge(
                  label: Text('$totalBadge'),
                  isLabelVisible: totalBadge > 0,
                  child: const Icon(Iconsax.message_2_copy),
                );
              },
            ),
            label: l10n.navMessagesLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Iconsax.setting),
            activeIcon: const Icon(Iconsax.setting_2_copy), // Bold version
            label: l10n.navSettingsLabel,
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
          _buildRailDestination(Iconsax.home, Iconsax.home_1_copy, l10n.navHomeLabel),
          _buildRailDestination(Iconsax.folder_cloud, Iconsax.folder_cloud_copy, l10n.navDepartmentsLabel),
          _buildRailDestination(Iconsax.teacher, Iconsax.teacher_copy, l10n.navAiAssistantLabel),
          _buildRailDestination(
            Iconsax.message,
            Iconsax.message_2_copy,
            l10n.navMessagesLabel,
            badgeCount: true,
          ),
          _buildRailDestination(Iconsax.setting, Iconsax.setting_2_copy, l10n.navSettingsLabel),
        ],
      );
    }

    return MultiProvider(
      providers: [
        StreamProvider<List<Department>?>.value(
          value: DatabaseService().getDepartments(institutionId: institutionId),
          initialData: null,
        ),
        StreamProvider<List<FriendRequest>?>.value(
          value: FriendsService().getPendingRequestsStream(),
          initialData: null,
        ),
        StreamProvider<int>.value(
          value: NotificationService().unreadCountStream,
          initialData: 0,
        ),
      ],
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
      String label, {
        bool badgeCount = false,
      }) {
    return NavigationRailDestination(
      icon: badgeCount
          ? Consumer3<MessageProvider, List<FriendRequest>?, int>(
        builder: (context, messageProvider, requests, unreadNotifications, child) {
          final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
          return Badge(
            label: Text('$totalBadge'),
            isLabelVisible: totalBadge > 0,
            child: Icon(unselectedIcon),
          );
        },
      )
          : Icon(unselectedIcon),
      selectedIcon: badgeCount
          ? Consumer3<MessageProvider, List<FriendRequest>?, int>(
        builder: (context, messageProvider, requests, unreadNotifications, child) {
          final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
          return Badge(
            label: Text('$totalBadge'),
            isLabelVisible: totalBadge > 0,
            child: Icon(selectedIcon),
          );
        },
      )
          : Icon(selectedIcon),
      label: Text(label),
    );
  }
}