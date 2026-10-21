import 'package:flutter/material.dart';

/// Centralized [GlobalKey]s for the first-launch guided tour (see
/// [AppTourService]), so widgets in [Home] and [NavBar] can be showcased
/// together via a single `ShowcaseView.get().startShowCase(AppTourKeys.ordered)`
/// call regardless of which widget subtree they live in.
class AppTourKeys {
  AppTourKeys._();

  static final avatar = GlobalKey();
  static final aiCredits = GlobalKey();
  static final notifications = GlobalKey();
  static final weeklyProgress = GlobalKey();
  static final departments = GlobalKey();
  static final toolbox = GlobalKey();
  static final chatFab = GlobalKey();
  static final navHome = GlobalKey();
  static final navAiAssistant = GlobalKey();
  static final navMessages = GlobalKey();
  static final navSettings = GlobalKey();

  /// The order the tour walks through: Home's dashboard top-to-bottom, then
  /// the bottom-nav destinations, so it reads as "here's your dashboard,
  /// here's how to get around."
  static final List<GlobalKey> ordered = [
    avatar,
    aiCredits,
    notifications,
    weeklyProgress,
    departments,
    toolbox,
    chatFab,
    navHome,
    navAiAssistant,
    navMessages,
    navSettings,
  ];
}
