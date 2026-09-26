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
import 'package:go_study/core/app_tour_keys.dart';

class NavBar extends StatefulWidget {
  final int initialIndex;
  const NavBar({super.key, this.initialIndex = 0});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  static const int _aiTabIndex = 1;
  static const int _homeTabIndex = 0;

  late int _selectedIndex;

  /// The last non-AI tab, so the AI Assistant screen's collapse chevron can
  /// return the user to where they came from (Home by default).
  int _previousIndex = 0;

  /// Set right after a back press on the Home tab shows the "press again to
  /// exit" snackbar; cleared after a short window so a second back press
  /// within that window exits the app instead of being swallowed again.
  DateTime? _lastBackPressAt;

  late final List<Widget> _widgetOptions;

  // Constructed once here rather than in build() — StreamProvider.value
  // resubscribes whenever the `value` Stream instance changes identity, and
  // both of these open a Supabase realtime channel, so rebuilding them per
  // build() (e.g. on every tab tap) would tear down and reopen the
  // subscriptions each time.
  late final Stream<List<FriendRequest>?> _pendingRequestsStream;
  late final Stream<int> _unreadNotificationCountStream;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pendingRequestsStream = FriendsService().getPendingRequestsStream();
    _unreadNotificationCountStream = NotificationService().unreadCountStream;
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

  Future<void> _handleBackPress() async {
    if (_selectedIndex != _homeTabIndex) {
      _onItemTapped(_homeTabIndex);
      return;
    }

    final now = DateTime.now();
    final lastPress = _lastBackPressAt;
    if (lastPress != null && now.difference(lastPress) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressAt = now;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.pressBackAgainToExit),
          duration: const Duration(seconds: 2),
        ),
      );
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
            icon: _tourWrapNavIcon(
              index: _homeTabIndex,
              isActiveVariant: false,
              tourKey: AppTourKeys.navHome,
              title: l10n.tourNavHomeTitle,
              description: l10n.tourNavHomeDesc,
              child: _navIcon('houseUnselected.svg', unselectedColor),
            ),
            activeIcon: _tourWrapNavIcon(
              index: _homeTabIndex,
              isActiveVariant: true,
              tourKey: AppTourKeys.navHome,
              title: l10n.tourNavHomeTitle,
              description: l10n.tourNavHomeDesc,
              child: _navIcon('houseSelected.svg', selectedColor),
            ),
            label: l10n.navHomeLabel,
          ),
          BottomNavigationBarItem(
            icon: _tourWrapNavIcon(
              index: _aiTabIndex,
              isActiveVariant: false,
              tourKey: AppTourKeys.navAiAssistant,
              title: l10n.tourNavAiAssistantTitle,
              description: l10n.tourNavAiAssistantDesc,
              child: _navIcon('aiUnselected.svg', unselectedColor),
            ),
            activeIcon: _tourWrapNavIcon(
              index: _aiTabIndex,
              isActiveVariant: true,
              tourKey: AppTourKeys.navAiAssistant,
              title: l10n.tourNavAiAssistantTitle,
              description: l10n.tourNavAiAssistantDesc,
              child: _navIcon('aiSelected.svg', selectedColor),
            ),
            label: l10n.navAiAssistantLabel,
          ),
          BottomNavigationBarItem(
            icon: _tourWrapNavIcon(
              index: 2,
              isActiveVariant: false,
              tourKey: AppTourKeys.navMessages,
              title: l10n.tourNavMessagesTitle,
              description: l10n.tourNavMessagesDesc,
              child: Consumer3<MessageProvider, List<FriendRequest>?, int>(
                builder: (context, messageProvider, requests, unreadNotifications, child) {
                  final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
                  return Badge(
                    label: Text('$totalBadge'),
                    isLabelVisible: totalBadge > 0,
                    child: _navIcon('messageUnselected.svg', unselectedColor),
                  );
                },
              ),
            ),
            activeIcon: _tourWrapNavIcon(
              index: 2,
              isActiveVariant: true,
              tourKey: AppTourKeys.navMessages,
              title: l10n.tourNavMessagesTitle,
              description: l10n.tourNavMessagesDesc,
              child: Consumer3<MessageProvider, List<FriendRequest>?, int>(
                builder: (context, messageProvider, requests, unreadNotifications, child) {
                  final totalBadge = messageProvider.unreadCount + (requests?.length ?? 0) + unreadNotifications;
                  return Badge(
                    label: Text('$totalBadge'),
                    isLabelVisible: totalBadge > 0,
                    child: _navIcon('messageSelected.svg', selectedColor),
                  );
                },
              ),
            ),
            label: l10n.navMessagesLabel,
          ),
          BottomNavigationBarItem(
            icon: _tourWrapNavIcon(
              index: 3,
              isActiveVariant: false,
              tourKey: AppTourKeys.navSettings,
              title: l10n.tourNavSettingsTitle,
              description: l10n.tourNavSettingsDesc,
              child: _navIcon('settingsUnselected.svg', unselectedColor),
            ),
            activeIcon: _tourWrapNavIcon(
              index: 3,
              isActiveVariant: true,
              tourKey: AppTourKeys.navSettings,
              title: l10n.tourNavSettingsTitle,
              description: l10n.tourNavSettingsDesc,
              child: _navIcon('settingsSelected.svg', selectedColor),
            ),
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
              index: _homeTabIndex,
              tourKey: AppTourKeys.navHome,
              tourTitle: l10n.tourNavHomeTitle,
              tourDesc: l10n.tourNavHomeDesc,
            ),
            _buildRailDestination(
              'aiUnselected.svg',
              'aiSelected.svg',
              l10n.navAiAssistantLabel,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              index: _aiTabIndex,
              tourKey: AppTourKeys.navAiAssistant,
              tourTitle: l10n.tourNavAiAssistantTitle,
              tourDesc: l10n.tourNavAiAssistantDesc,
            ),
            _buildRailDestination(
              'messageUnselected.svg',
              'messageSelected.svg',
              l10n.navMessagesLabel,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              badgeCount: true,
              index: 2,
              tourKey: AppTourKeys.navMessages,
              tourTitle: l10n.tourNavMessagesTitle,
              tourDesc: l10n.tourNavMessagesDesc,
            ),
            _buildRailDestination(
              'settingsUnselected.svg',
              'settingsSelected.svg',
              l10n.navSettingsLabel,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              index: 3,
              tourKey: AppTourKeys.navSettings,
              tourTitle: l10n.tourNavSettingsTitle,
              tourDesc: l10n.tourNavSettingsDesc,
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
          value: _pendingRequestsStream,
          initialData: null,
        ),
        StreamProvider<int>.value(
          value: _unreadNotificationCountStream,
          initialData: 0,
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackPress();
        },
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
      ),
    );
  }

  // Wraps [child] with the first-launch tour's Showcase for the given nav
  // destination, but only for whichever of the icon/activeIcon pair is the
  // one actually relevant to the current tab selection — BottomNavigationBar
  // and NavigationRail always build both variants, so giving the same
  // GlobalKey to both simultaneously would violate GlobalKey uniqueness.
  Widget _tourWrapNavIcon({
    required int index,
    required bool isActiveVariant,
    required GlobalKey tourKey,
    required String title,
    required String description,
    required Widget child,
  }) {
    final shouldWrap = isActiveVariant ? _selectedIndex == index : _selectedIndex != index;
    if (!shouldWrap) return child;
    return tourShowcase(
      context,
      key: tourKey,
      title: title,
      description: description,
      targetShapeBorder: const CircleBorder(),
      child: child,
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
        required int index,
        required GlobalKey tourKey,
        required String tourTitle,
        required String tourDesc,
        bool badgeCount = false,
      }) {
    final unselectedChild = badgeCount
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
        : _navIcon(unselectedAsset, unselectedColor);
    final selectedChild = badgeCount
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
        : _navIcon(selectedAsset, selectedColor);
    return NavigationRailDestination(
      icon: _tourWrapNavIcon(
        index: index,
        isActiveVariant: false,
        tourKey: tourKey,
        title: tourTitle,
        description: tourDesc,
        child: unselectedChild,
      ),
      selectedIcon: _tourWrapNavIcon(
        index: index,
        isActiveVariant: true,
        tourKey: tourKey,
        title: tourTitle,
        description: tourDesc,
        child: selectedChild,
      ),
      label: Text(label),
    );
  }
}