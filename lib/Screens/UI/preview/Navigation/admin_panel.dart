import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import 'package:go_study/Screens/UI/preview/Navigation/profile.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/news_composer_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/all_departments_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/Screens/Shared/content_media_card.dart';
import 'package:go_study/Screens/Shared/department_ui_data.dart';
import 'package:go_study/Screens/Shared/section_header.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/departments_provider.dart';
import 'package:go_study/services/institution.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';
import 'package:go_study/Screens/Shared/constanst.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final DatabaseService _db = DatabaseService(
    uid: Authentication().currentUser?.id,
  );
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearchError = false;
  String _lastQuery = '';
  Timer? _debounce;
  int _searchToken = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _handleSearch(query),
    );
  }

  Future<void> _handleSearch(String query) async {
    final trimmed = query.trim();
    final token = ++_searchToken;

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearchError = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearchError = false;
    });

    try {
      final results = await _db.adminSearchUsers(trimmed);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _lastQuery = trimmed;
      });
    } catch (e) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearchError = true;
        _lastQuery = trimmed;
      });
    }
  }

  Future<void> _confirmAndUpdateRole(
    UserProfile user,
    UserRole role, {
    required bool isPromotion,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = _roleDisplayName(l10n, role);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isPromotion
              ? l10n.promoteToRoleTitle(roleLabel)
              : l10n.demoteToRoleTitle(roleLabel),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPromotion
              ? l10n.promoteUserConfirmBody(
                  user.name ?? l10n.thisUserFallback,
                  roleLabel,
                )
              : l10n.demoteUserConfirmBody(
                  user.name ?? l10n.thisUserFallback,
                  roleLabel,
                ),
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
              isPromotion ? l10n.promoteButton : l10n.demoteButton,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.updateUserRole(user.id, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.userIsNowRoleLabel(
              user.name ?? l10n.defaultUserName,
              roleLabel,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _handleSearch(_lastQuery);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAllDepartments(BuildContext context) {
    // AdminPanel is pushed as its own route (from Settings/Profile), so it
    // sits outside the DepartmentsProvider that navigationbar.dart scopes to
    // the tab shell — there's no ancestor instance to read here, unlike
    // Home's "See all", which lives inside that shell. Create one instead.
    final institutionId =
        context.read<UserModel>().institutionId ?? kDefaultInstitutionId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<DepartmentsProvider>(
          create: (_) => DepartmentsProvider()..updateInstitutionId(institutionId),
          child: const AllDepartmentsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.adminDashboardTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: userModel.role != UserRole.admin
          ? Center(child: Text(l10n.adminAccessRequired))
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _DashboardHero(userModel: userModel),
                      const SizedBox(height: AppSpacing.lg),
                      _StatsRow(db: _db),
                      const SizedBox(height: AppSpacing.lg),
                      const _QuickActions(),
                      SectionHeader(
                        title: l10n.manageDepartmentsTitle,
                        trailing: TextButton(
                          onPressed: () => _openAllDepartments(context),
                          child: Text(
                            l10n.seeAllButton,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      _DepartmentsSection(
                        db: _db,
                        onManageDepartments: () => _openAllDepartments(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SearchCard(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        theme: theme,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.manageUsersTitle,
                        style: AppText.sectionTitle(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (_isSearching) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (_hasSearchError) {
                          return _SearchErrorState(
                            theme: theme,
                            onRetry: () => _handleSearch(_lastQuery),
                          );
                        }
                        if (_searchResults.isEmpty) {
                          return _EmptyState(
                            query: _searchController.text,
                            theme: theme,
                          );
                        }
                        return _UserCard(
                          user: _searchResults[index],
                          theme: theme,
                          onPromoteToContributor: () => _confirmAndUpdateRole(
                            _searchResults[index],
                            UserRole.contributor,
                            isPromotion: true,
                          ),
                          onPromoteToAdmin: () => _confirmAndUpdateRole(
                            _searchResults[index],
                            UserRole.admin,
                            isPromotion: true,
                          ),
                          onDemoteToViewer: () => _confirmAndUpdateRole(
                            _searchResults[index],
                            UserRole.viewer,
                            isPromotion: false,
                          ),
                          onDemoteToContributor: () => _confirmAndUpdateRole(
                            _searchResults[index],
                            UserRole.contributor,
                            isPromotion: false,
                          ),
                        );
                      },
                      childCount: _isSearching || _hasSearchError
                          ? 1
                          : (_searchResults.isEmpty
                                ? 1
                                : _searchResults.length),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }
}

String _roleDisplayName(AppLocalizations l10n, UserRole role) {
  switch (role) {
    case UserRole.admin:
      return l10n.roleLabelAdmin;
    case UserRole.contributor:
      return l10n.roleLabelContributor;
    case UserRole.viewer:
      return l10n.roleLabelViewer;
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.userModel});

  final UserModel userModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Iconsax.shield_tick,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.adminAccessLabel,
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            userModel.name ?? l10n.administratorFallback,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.adminDashboardSubtitle,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: _roleDisplayName(l10n, userModel.role)),
              _HeroPill(
                label: userModel.institutionName ?? l10n.institutionFallback,
              ),
              _HeroPill(label: userModel.department ?? l10n.departmentLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.db});

  final DatabaseService db;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int>(
            future: db.getTotalUsersCount(),
            builder: (context, snapshot) {
              return _StatCard(
                icon: Iconsax.people,
                color: const Color(0xFF2563EB),
                label: l10n.totalUsersStatLabel,
                value: snapshot.data?.toString() ?? '—',
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<Department>>(
            stream: db.getDepartments(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length;
              return _StatCard(
                icon: Iconsax.teacher,
                color: const Color(0xFF059669),
                label: l10n.totalDepartmentsStatLabel,
                value: count?.toString() ?? '—',
                isLoading: !snapshot.hasData,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isLoading,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLoading ? '—' : value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardSubtitle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.person_rounded,
              color: const Color(0xFF7C3AED),
              title: l10n.myProfileTitle,
              subtitle: l10n.reviewYourAccountSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Profile()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.newspaper_rounded,
              color: const Color(0xFFEA580C),
              title: l10n.homeToolNews,
              subtitle: l10n.newsComposerNewTitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewsComposerScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentsSection extends StatelessWidget {
  const _DepartmentsSection({
    required this.db,
    required this.onManageDepartments,
  });

  final DatabaseService db;
  final VoidCallback onManageDepartments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Department>>(
      stream: db.getDepartments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final departments = snapshot.data ?? [];
        if (departments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noDepartmentsAvailableYet,
                  style: GoogleFonts.outfit(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onManageDepartments,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    l10n.newDeptButton,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: departments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final department = departments[index];
              final uiData = DepartmentUIData.fromDepartmentName(
                department.name,
              );
              return SizedBox(
                width: 170,
                child: ContentMediaCard(
                  title: department.name,
                  subtitle: department.description.isNotEmpty
                      ? department.description
                      : l10n.noDescriptionAvailable,
                  imageUrl: department.imageUrl,
                  icon: uiData.icon,
                  primaryColor: uiData.primaryColor,
                  secondaryColor: uiData.secondaryColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DepartmentScreen(
                        departmentName: department.name,
                        departmentId: department.id,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppText.cardSubtitle(context)),
          ],
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.onChanged,
    required this.theme,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: l10n.searchNameMatriculeHint,
          prefixIcon: const Icon(Iconsax.search_normal),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.theme});

  final String query;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Center(
        child: Column(
          children: [
            Icon(
              query.isEmpty ? Iconsax.user_search : Iconsax.search_status,
              size: 56,
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? l10n.searchForUserLabel : l10n.noUsersFound,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({required this.theme, required this.onRetry});

  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.searchResultsErrorTitle,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(
                l10n.retryButton,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.theme,
    required this.onPromoteToContributor,
    required this.onPromoteToAdmin,
    required this.onDemoteToViewer,
    required this.onDemoteToContributor,
  });

  final UserProfile user;
  final ThemeData theme;
  final VoidCallback onPromoteToContributor;
  final VoidCallback onPromoteToAdmin;
  final VoidCallback onDemoteToViewer;
  final VoidCallback onDemoteToContributor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = user.role;
    final canPromoteToContributor = role == UserRole.viewer;
    final canPromoteToAdmin = role != UserRole.admin;
    final canDemoteToContributor = role == UserRole.admin;
    final canDemoteToViewer = role == UserRole.contributor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? l10n.unknownUserFallback,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.matricule ?? l10n.noMatriculeFallback,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _RoleBadge(label: _roleDisplayName(l10n, role)),
                        if ((user.department ?? '').isNotEmpty)
                          _RoleBadge(label: user.department!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canPromoteToContributor ||
              canPromoteToAdmin ||
              canDemoteToContributor ||
              canDemoteToViewer) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canPromoteToContributor)
                  _MiniActionButton(
                    label: l10n.roleLabelContributor,
                    color: Colors.blue,
                    icon: Icons.arrow_upward_rounded,
                    onTap: onPromoteToContributor,
                  ),
                if (canPromoteToAdmin)
                  _MiniActionButton(
                    label: l10n.roleLabelAdmin,
                    color: Colors.indigo,
                    icon: Icons.arrow_upward_rounded,
                    onTap: onPromoteToAdmin,
                  ),
                if (canDemoteToContributor)
                  _MiniActionButton(
                    label: l10n.roleLabelContributor,
                    color: Colors.orange,
                    icon: Icons.arrow_downward_rounded,
                    onTap: onDemoteToContributor,
                  ),
                if (canDemoteToViewer)
                  _MiniActionButton(
                    label: l10n.roleLabelViewer,
                    color: Colors.grey,
                    icon: Icons.arrow_downward_rounded,
                    onTap: onDemoteToViewer,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
