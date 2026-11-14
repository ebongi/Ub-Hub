import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:go_study/core/error_handler.dart';
import 'package:go_study/core/error_view.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/profile.dart' show UserProfile;
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';

/// AdminPanel's "Subscriptions" tab: active-subscriber counts, a revenue
/// summary, and the most recent payment transactions across all users
/// (enabled by the admin-only "Admins can view all transactions" RLS policy
/// — see supabase/migrations/*_add_admin_subscription_management.sql).
class AdminSubscriptionsTab extends StatefulWidget {
  const AdminSubscriptionsTab({super.key, required this.db});

  final DatabaseService db;

  @override
  State<AdminSubscriptionsTab> createState() => _AdminSubscriptionsTabState();
}

class _AdminSubscriptionsTabState extends State<AdminSubscriptionsTab> {
  late Future<_SubscriptionsOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SubscriptionsOverview> _load() async {
    final stats = await widget.db.adminGetSubscriptionStats();
    final revenue = await widget.db.adminGetRevenueSummary();
    final transactions = await widget.db.adminGetRecentTransactions();
    final profiles = await widget.db.adminGetProfilesByIds(
      transactions.map((t) => t.userId).toList(),
    );
    return _SubscriptionsOverview(
      stats: stats,
      revenue: revenue,
      transactions: transactions,
      profilesById: profiles,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<_SubscriptionsOverview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(
            title: ErrorHandler.getFriendlyMessage(snapshot.error),
            icon: Icons.receipt_long_rounded,
            onRetry: _reload,
          );
        }

        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: [
                _StatTile(
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF2563EB),
                  label: l10n.activeMonthlyStatLabel,
                  value: '${data.stats['activeMonthly'] ?? 0}',
                ),
                _StatTile(
                  icon: Icons.event_available_rounded,
                  color: const Color(0xFF059669),
                  label: l10n.activeYearlyStatLabel,
                  value: '${data.stats['activeYearly'] ?? 0}',
                ),
                _StatTile(
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFEA580C),
                  label: l10n.activeTrialStatLabel,
                  value: '${data.stats['activeTrial'] ?? 0}',
                ),
                _StatTile(
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF9333EA),
                  label: l10n.activeAiStatLabel,
                  value: '${data.stats['activeAi'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF16A34A),
                    label: l10n.totalRevenueStatLabel,
                    value: _formatXaf(data.revenue['totalRevenue'] ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF0EA5E9),
                    label: l10n.monthlyRevenueStatLabel,
                    value: _formatXaf(data.revenue['monthRevenue'] ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.recentTransactionsTitle,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (data.transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    l10n.noTransactionsYetMessage,
                    style: GoogleFonts.outfit(color: Theme.of(context).hintColor),
                  ),
                ),
              )
            else
              ...data.transactions.map(
                (t) => _TransactionRow(
                  transaction: t,
                  payerName: data.profilesById[t.userId]?.name,
                ),
              ),
          ],
        );
      },
    );
  }

  static String _formatXaf(num amount) => '${amount.toStringAsFixed(0)} XAF';
}

class _SubscriptionsOverview {
  _SubscriptionsOverview({
    required this.stats,
    required this.revenue,
    required this.transactions,
    required this.profilesById,
  });

  final Map<String, int> stats;
  final Map<String, num> revenue;
  final List<PaymentTransaction> transactions;
  final Map<String, UserProfile> profilesById;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.payerName});

  final PaymentTransaction transaction;
  final String? payerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAdminAction = transaction.itemType.startsWith('admin_');
    final statusColor = switch (transaction.status) {
      PaymentStatus.success => const Color(0xFF16A34A),
      PaymentStatus.pending => const Color(0xFFEA580C),
      PaymentStatus.failed => const Color(0xFFDC2626),
      PaymentStatus.cancelled => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payerName ?? transaction.userId,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd().add_jm().format(transaction.createdAt),
                  style: GoogleFonts.outfit(fontSize: 11, color: theme.hintColor),
                ),
                if (isAdminAction) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.adminGrantBadgeLabel,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.indigo),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  transaction.status.name,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
