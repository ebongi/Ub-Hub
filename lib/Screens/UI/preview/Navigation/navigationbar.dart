import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_study/Screens/UI/preview/Navigation/home.dart';
import 'package:go_study/Screens/UI/preview/Chatbot/chatbot_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/dm_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/settings_screen.dart';
import 'package:go_study/services/departments_provider.dart';
import 'package:go_study/services/friends_service.dart';
import 'package:go_study/services/institution.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/message_provider.dart';
import 'package:go_study/services/notification_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavBar extends StatefulWidget {
  final int initialIndex;
  const NavBar({super.key, this.initialIndex = 0});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  static const int _aiTabIndex = 1;

  late int _selectedIndex;

  /// The last non-AI tab, so the AI Assistant screen's collapse chevron can
  /// return the user to where they came from (Home by default).
  int _previousIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _widgetOptions = <Widget>[
      const Home(),
      ChatbotScreen(onCollapse: () => _onItemTapped(_previousIndex)),
      const DmScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIndex != _aiTabIndex) _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width >= 600;

    final userModel = Provider.of<UserModel>(context);
    final institutionId = userModel.institutionId ?? kDefaultInstitutionId;

    // Sourced from the theme's bottomNavigationBarTheme/navigationRailTheme
    // (see ThemeProvider) so both light and dark mode follow the user's
    // chosen accent color consistently, instead of a hardcoded dark-mode
    // override.
    final selectedColor = theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary;
    final unselectedColor = theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[500]!;

    Widget buildBottomBar() {
      return Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
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
            icon: _navIcon('houseUnselected.svg', unselectedColor),
            activeIcon: _navIcon('houseSelected.svg', selectedColor),
            label: l10n.navHomeLabel,
          ),
          BottomNavigationBarItem(
            icon: _navIcon('aiUnselected.svg', unselectedColor),
            activeIcon: _navIcon('aiSelected.svg', selectedColor),
            label: l10n.navAiAssistantLabel,
          ),
          BottomNavigationBarItem(
            icon: Consumer3<MessageProvider, List<FriendRequest>?, int>(
              builder: (context, messageProvider, requests, unreadNotifications, child) {
                final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
                return Badge(
                  label: Text('$totalBadge'),
                  isLabelVisible: totalBadge > 0,
                  child: _navIcon('messageUnselected.svg', unselectedColor),
                );
              },
            ),
            activeIcon: Consumer3<MessageProvider, List<FriendRequest>?, int>(
              builder: (context, messageProvider, requests, unreadNotifications, child) {
                final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
                return Badge(
                  label: Text('$totalBadge'),
                  isLabelVisible: totalBadge > 0,
                  child: _navIcon('messageSelected.svg', selectedColor),
                );
              },
            ),
            label: l10n.navMessagesLabel,
          ),
          BottomNavigationBarItem(
            icon: _navIcon('settingsUnselected.svg', unselectedColor),
            activeIcon: _navIcon('settingsSelected.svg', selectedColor),
            label: l10n.navSettingsLabel,
          ),
          ],
        ),
      );
    }

    Widget buildNavRail() {
      return Container(
        decoration: BoxDecoration(
          color: theme.navigationRailTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
          border: Border(right: BorderSide(color: theme.dividerColor)),
        ),
        child: NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.transparent,
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
            _buildRailDestination(
              'houseUnselected.svg',
              'houseSelected.svg',
              l10n.navHomeLabel,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
            ),
            _buildRailDestination(
              'aiUnselected.svg',
              'aiSelected.svg',
              l10n.navAiAssistantLabel,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
            ),
            _buildRailDestination(
              'messageUnselected.svg',
              'messageSelected.svg',
              l10n.navMessagesLabel,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              badgeCount: true,
            ),
            _buildRailDestination(
              'settingsUnselected.svg',
              'settingsSelected.svg',
              l10n.navSettingsLabel,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
            ),
          ],
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProxyProvider<UserModel, DepartmentsProvider>(
          create: (_) => DepartmentsProvider()..updateInstitutionId(institutionId),
          update: (_, userModel, departmentsProvider) {
            final provider = departmentsProvider ?? DepartmentsProvider();
            provider.updateInstitutionId(userModel.institutionId ?? kDefaultInstitutionId);
            return provider;
          },
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
        // Hidden on the AI Assistant tab, which owns the full screen; the
        // header's collapse chevron brings it back. Animated so it slides
        // away rather than popping.
        bottomNavigationBar: isLargeScreen
            ? null
            : AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _selectedIndex == _aiTabIndex
                    ? const SizedBox(width: double.infinity)
                    : buildBottomBar(),
              ),
      ),
    );
  }

  // Renders one of the SVGs dropped in assets/icons/nav/, tinted to match
  // the selected/unselected color the rest of the nav bar uses.
  Widget _navIcon(String assetName, Color color) {
    return SvgPicture.asset(
      'assets/icons/nav/$assetName',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  // Helper for NavigationRail
  NavigationRailDestination _buildRailDestination(
      String unselectedAsset,
      String selectedAsset,
      String label, {
        required Color selectedColor,
        required Color unselectedColor,
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
            child: _navIcon(unselectedAsset, unselectedColor),
          );
        },
      )
          : _navIcon(unselectedAsset, unselectedColor),
      selectedIcon: badgeCount
          ? Consumer3<MessageProvider, List<FriendRequest>?, int>(
        builder: (context, messageProvider, requests, unreadNotifications, child) {
          final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
          return Badge(
            label: Text('$totalBadge'),
            isLabelVisible: totalBadge > 0,
            child: _navIcon(selectedAsset, selectedColor),
          );
        },
      )
          : _navIcon(selectedAsset, selectedColor),
      label: Text(label),
    );
  }
}