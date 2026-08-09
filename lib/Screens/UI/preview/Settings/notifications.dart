import 'package:flutter/material.dart';
import 'package:go_study/services/notification_service.dart';
import 'package:go_study/services/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _studyRemindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Clear the notification badge when viewing notifications
    NotificationService().markAllAsRead();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('push_notifications') ?? true;
      _emailEnabled = prefs.getBool('email_notifications') ?? false;
      _studyRemindersEnabled = prefs.getBool('study_reminders') ?? false;
    });
  }

  Future<void> _togglePush(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
    setState(() => _pushEnabled = value);
  }

  Future<void> _toggleEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', value);
    setState(() => _emailEnabled = value);
  }

  Future<void> _toggleStudyReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('study_reminders', value);
    setState(() => _studyRemindersEnabled = value);
    
    if (value) {
      await NotificationService().scheduleStudyReminders();
    } else {
      await NotificationService().cancelStudyReminders();
    }
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: l10n.clearAllNotificationsTitle,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumDialogHeader(
              title: l10n.clearAllNotificationsTitle,
              subtitle: l10n.deleteChatDialogSubtitle,
              icon: Icons.delete_sweep_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    l10n.confirmClearAllNotificationsBody,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PremiumSubmitButton(
                          label: l10n.clearAllButtonShort,
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await NotificationService().clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      // backgroundColor: ,
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _clearAll,
            tooltip: l10n.clearAllButtonShort,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerLow
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    l10n.pushNotificationsTitle,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.receiveAlertsNewCoursesSubtitle,
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  value: _pushEnabled,
                  onChanged: _togglePush,
                ),
                SwitchListTile(
                  title: Text(
                    l10n.emailUpdatesTitle,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.receiveDigestEmailsSubtitle,
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  value: _emailEnabled,
                  onChanged: _toggleEmail,
                ),
                SwitchListTile(
                  title: Text(
                    l10n.studyRemindersTitle,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.dailyReminderSubtitle,
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  value: _studyRemindersEnabled,
                  onChanged: _toggleStudyReminders,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentActivityTitle,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAll,
                        child: Text(
                          l10n.clearAllButtonShort,
                          style: GoogleFonts.outfit(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: NotificationService().notifications,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<NotificationModel>> snapshot,
                  ) {
                    if (snapshot.hasError) {
                      final error = snapshot.error.toString();
                      if (error.contains('PGRST205')) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 50,
                                  color: Colors.orange,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Notification table not found!",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Please run the SQL script in 'supabase_setup.md' to create it.",
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Center(child: Text(l10n.errorLoadingMessages(snapshot.error.toString())));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(l10n.noNotificationsFound),
                      );
                    }

                    final notifications = snapshot.data!;

                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final isDarkInItem =
                            theme.brightness == Brightness.dark;
                        IconData icon;

                        switch (item.type) {
                          case NotificationType.message:
                            icon = Icons.chat_bubble_outline_rounded;
                            break;
                          case NotificationType.department:
                            icon = Icons.business_rounded;
                            break;
                          case NotificationType.course:
                            icon = Icons.book_rounded;
                            break;
                          case NotificationType.material:
                            icon = Icons.file_present_rounded;
                            break;
                          case NotificationType.subscription:
                            icon = Icons.card_membership_rounded;
                            break;
                          case NotificationType.friendRequest:
                            icon = Icons.person_add_rounded;
                            break;
                          default:
                            icon = Icons.info_outline_rounded;
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkInItem
                                ? theme.colorScheme.surfaceContainerLow
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDarkInItem
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: GoogleFonts.outfit(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 16,
                                color: isDarkInItem
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: isDarkInItem
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.formattedDate,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              NotificationService().markAsRead(item.id);
                            },
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}
