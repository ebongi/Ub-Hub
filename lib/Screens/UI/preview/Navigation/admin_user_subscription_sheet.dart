import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';

/// Bottom sheet letting an admin grant/extend/revoke a target user's App
/// Plan and Unlimited AI subscription, adjust their AI credit balance, and
/// reset their free-download count / trial eligibility. Opened from
/// AdminPanel's Users tab; [onChanged] lets the caller refresh its own view
/// of the user after a successful action.
Future<void> showAdminUserSubscriptionSheet(
  BuildContext context, {
  required UserProfile user,
  required DatabaseService db,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _AdminUserSubscriptionSheet(user: user, db: db, onChanged: onChanged),
  );
}

class _AdminUserSubscriptionSheet extends StatefulWidget {
  const _AdminUserSubscriptionSheet({
    required this.user,
    required this.db,
    required this.onChanged,
  });

  final UserProfile user;
  final DatabaseService db;
  final VoidCallback onChanged;

  @override
  State<_AdminUserSubscriptionSheet> createState() =>
      _AdminUserSubscriptionSheetState();
}

class _AdminUserSubscriptionSheetState
    extends State<_AdminUserSubscriptionSheet> {
  late UserProfile _user;
  bool _busy = false;
  final _creditsController = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void dispose() {
    _creditsController.dispose();
    super.dispose();
  }

  String get _userName => _user.name ?? AppLocalizations.of(context)!.thisUserFallback;

  Future<bool> _confirm(String actionLabel) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        title: Text(
          l10n.confirmAdminActionTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.confirmAdminActionBody(actionLabel, _userName),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.confirmActionButton,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _run(String actionLabel, Future<void> Function() action) async {
    if (!await _confirm(actionLabel)) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(
        context,
        AppLocalizations.of(context)!.adminActionSuccessMessage(_userName),
      );
      widget.onChanged();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grantSubscription(String tier, int days, {bool extend = false}) {
    final l10n = AppLocalizations.of(context)!;
    final label = extend
        ? l10n.extend30DaysButton
        : (tier == 'monthly' ? l10n.grantMonthlyButton : l10n.grantYearlyButton);
    return _run(label, () async {
      final expiry = await widget.db.adminSetSubscription(
        _user.id,
        tier: tier,
        days: days,
        extend: extend,
      );
      setState(() => _user = _user.copyWith(
            subscriptionTier: SubscriptionTier.fromString(tier),
            subscriptionExpiry: expiry,
            freeDownloadCount: 0,
          ));
    });
  }

  /// Ends whatever App Plan period is currently active — a paid
  /// monthly/yearly subscription or an in-progress free trial — immediately.
  /// The trial-used flag is left untouched, so a terminated trial still
  /// needs [_resetTrialEligibility] before the user can claim another one.
  Future<void> _endAppPlan(String actionLabel) {
    return _run(actionLabel, () async {
      await widget.db.adminSetSubscription(_user.id, tier: 'free');
      setState(() => _user = _user.copyWith(
            subscriptionTier: SubscriptionTier.free,
            clearSubscriptionExpiry: true,
            isTrialSubscription: false,
          ));
    });
  }

  Future<void> _revokeSubscription() => _endAppPlan(AppLocalizations.of(context)!.revokeButton);

  Future<void> _terminateTrial() =>
      _endAppPlan(AppLocalizations.of(context)!.terminateTrialButton);

  Future<void> _grantAiSubscription(int days, {bool extend = false}) {
    final l10n = AppLocalizations.of(context)!;
    final label = extend
        ? l10n.extend30DaysButton
        : (days >= 365 ? l10n.grantYearlyButton : l10n.grantMonthlyButton);
    return _run(label, () async {
      final expiry = await widget.db.adminSetAiSubscription(_user.id, days: days, extend: extend);
      setState(() => _user = _user.copyWith(aiSubscriptionExpiry: expiry));
    });
  }

  Future<void> _revokeAiSubscription() {
    final l10n = AppLocalizations.of(context)!;
    return _run(l10n.revokeButton, () async {
      await widget.db.adminSetAiSubscription(_user.id, days: 0);
      setState(() => _user = _user.copyWith(clearAiSubscriptionExpiry: true));
    });
  }

  Future<void> _adjustCredits(bool positive) {
    final l10n = AppLocalizations.of(context)!;
    final amount = int.tryParse(_creditsController.text.trim()) ?? 0;
    if (amount <= 0) return Future.value();
    final delta = positive ? amount : -amount;
    return _run(
      '${positive ? l10n.addCreditsButton : l10n.removeCreditsButton} ($amount)',
      () async {
        final newBalance = await widget.db.adminAdjustAiCredits(_user.id, delta);
        setState(() => _user = _user.copyWith(aiCredits: newBalance));
      },
    );
  }

  Future<void> _resetFreeDownloads() {
    final l10n = AppLocalizations.of(context)!;
    return _run(l10n.resetToZeroButton, () async {
      await widget.db.adminResetFreeDownloads(_user.id);
      setState(() => _user = _user.copyWith(freeDownloadCount: 0));
    });
  }

  Future<void> _resetTrialEligibility() {
    final l10n = AppLocalizations.of(context)!;
    return _run(l10n.resetTrialButton, () async {
      await widget.db.adminResetTrialEligibility(_user.id);
      setState(() => _user = _user.copyWith(trialUsed: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: AbsorbPointer(
          absorbing: _busy,
          child: Opacity(
            opacity: _busy ? 0.6 : 1,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  l10n.subscriptionManagementTitle,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(_userName, style: GoogleFonts.outfit(color: theme.hintColor)),
                const SizedBox(height: AppSpacing.xl),

                _Section(
                  title: l10n.appPlanSectionTitle,
                  statusLine: _user.subscriptionTier == SubscriptionTier.free
                      ? l10n.noActivePlanLabel
                      : '${l10n.currentPlanLabel(_user.isTrialActive ? l10n.trialActiveLabel : _user.subscriptionTier.name.toUpperCase())}'
                          '${_user.subscriptionExpiry != null ? '\n${l10n.expiresOnLabel(DateFormat.yMMMd().format(_user.subscriptionExpiry!))}' : ''}',
                  actions: [
                    _ActionChip(label: l10n.grantMonthlyButton, onTap: () => _grantSubscription('monthly', 30)),
                    _ActionChip(label: l10n.grantYearlyButton, onTap: () => _grantSubscription('yearly', 365)),
                    _ActionChip(
                      label: l10n.extend30DaysButton,
                      onTap: _user.subscriptionTier == SubscriptionTier.free
                          ? null
                          : () => _grantSubscription(_user.subscriptionTier.name, 30, extend: true),
                    ),
                    _ActionChip(
                      label: l10n.revokeButton,
                      destructive: true,
                      onTap: _user.subscriptionTier == SubscriptionTier.free ? null : _revokeSubscription,
                    ),
                  ],
                ),

                _Section(
                  title: l10n.aiSubscriptionSectionTitle,
                  statusLine: _user.aiSubscriptionExpiry != null && _user.aiSubscriptionExpiry!.isAfter(DateTime.now())
                      ? l10n.expiresOnLabel(DateFormat.yMMMd().format(_user.aiSubscriptionExpiry!))
                      : l10n.aiSubscriptionInactiveLabel,
                  actions: [
                    _ActionChip(label: l10n.grantMonthlyButton, onTap: () => _grantAiSubscription(30)),
                    _ActionChip(label: l10n.grantYearlyButton, onTap: () => _grantAiSubscription(365)),
                    _ActionChip(label: l10n.extend30DaysButton, onTap: () => _grantAiSubscription(30, extend: true)),
                    _ActionChip(
                      label: l10n.revokeButton,
                      destructive: true,
                      onTap: (_user.aiSubscriptionExpiry != null && _user.aiSubscriptionExpiry!.isAfter(DateTime.now()))
                          ? _revokeAiSubscription
                          : null,
                    ),
                  ],
                ),

                _Section(
                  title: l10n.aiCreditsSectionTitle,
                  statusLine: '${_user.aiCredits}',
                  actions: [],
                  trailing: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _creditsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l10n.creditsAmountHint,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionChip(label: l10n.addCreditsButton, onTap: () => _adjustCredits(true)),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionChip(label: l10n.removeCreditsButton, destructive: true, onTap: () => _adjustCredits(false)),
                    ],
                  ),
                ),

                _Section(
                  title: l10n.freeDownloadsSectionTitle,
                  statusLine: l10n.freeDownloadsUsedLabel(_user.freeDownloadCount),
                  actions: [
                    _ActionChip(
                      label: l10n.resetToZeroButton,
                      onTap: _user.freeDownloadCount == 0 ? null : _resetFreeDownloads,
                    ),
                  ],
                ),

                _Section(
                  title: l10n.trialEligibilitySectionTitle,
                  statusLine: _user.isTrialActive
                      ? '${l10n.trialActiveLabel}\n${l10n.expiresOnLabel(DateFormat.yMMMd().format(_user.subscriptionExpiry!))}'
                      : (_user.trialUsed ? l10n.trialUsedLabel : l10n.trialAvailableLabel),
                  actions: [
                    if (_user.isTrialActive)
                      _ActionChip(
                        label: l10n.terminateTrialButton,
                        destructive: true,
                        onTap: _terminateTrial,
                      ),
                    _ActionChip(
                      label: l10n.resetTrialButton,
                      onTap: (!_user.isTrialActive && _user.trialUsed)
                          ? _resetTrialEligibility
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.statusLine,
    required this.actions,
    this.trailing,
  });

  final String title;
  final String statusLine;
  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(statusLine, style: GoogleFonts.outfit(fontSize: 13, color: theme.hintColor)),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.md),
            trailing!,
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap, this.destructive = false});

  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : Theme.of(context).colorScheme.primary;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: onTap == null ? color.withOpacity(0.25) : color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
