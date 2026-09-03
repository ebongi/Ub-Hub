import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import 'package:go_study/Screens/UI/preview/Navigation/profile.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/news_composer_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/profile.dart';
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
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _db.adminSearchUsers(trimmed);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
      _lastQuery = trimmed;
    });
  }

  Future<void> _confirmAndUpdateRole(
    UserProfile user,
    UserRole role,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = role == UserRole.admin ? l10n.roleLabelAdmin : l10n.roleLabelContributor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.promoteToRoleTitle(roleLabel),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.promoteUserConfirmBody(user.name ?? l10n.thisUserFallback, roleLabel),
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
              l10n.promoteButton,
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
          content: Text(l10n.userIsNowRoleLabel(user.name ?? l10n.defaultUserName, roleLabel)),
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
                      const SizedBox(height: 16),
                      const _QuickActions(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.manageDepartmentsTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DepartmentsSection(db: _db),
                      const SizedBox(height: 20),
                      _SearchCard(
                        controller: _searchController,
                        onChanged: _handleSearch,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.manageUsersTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          ),
                          onPromoteToAdmin: () => _confirmAndUpdateRole(
                            _searchResults[index],
                            UserRole.admin,
                          ),
                        );
                      },
                      childCount: _isSearching
                          ? 1
                          : (_searchResults.isEmpty ? 1 : _searchResults.length),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.userModel,
  });

  final UserModel userModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
          Text(
            l10n.adminAccessLabel,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userModel.name ?? l10n.administratorFallback,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: _roleDisplayName(l10n, userModel.role)),
              _HeroPill(label: userModel.institutionName ?? l10n.institutionFallback),
              _HeroPill(label: userModel.department ?? l10n.departmentLabel),
            ],
          ),
        ],
      ),
    );
  }
}

String _roleDisplayName(AppLocalizations l10n, UserRole role) {
  switch (role) {
    case UserRole.admin:
      return l10n.roleAdmin;
    case UserRole.contributor:
      return l10n.roleContributor;
    case UserRole.viewer:
      return l10n.roleViewer;
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
        borderRadius: BorderRadius.circular(999),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.person_rounded,
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
            title: l10n.homeToolNews,
            subtitle: l10n.newsComposerNewTitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsComposerScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _DepartmentsSection extends StatelessWidget {
  const _DepartmentsSection({required this.db});

  final DatabaseService db;

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
            child: Text(
              l10n.noDepartmentsAvailableYet,
              style: GoogleFonts.outfit(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
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
              return _DepartmentCard(
                department: department,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepartmentScreen(
                      departmentName: department.name,
                      departmentId: department.id,
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

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.department,
    required this.onTap,
  });

  final Department department;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: 210,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (department.imageUrl != null &&
                        department.imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: department.imageUrl!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          child: Center(
                            child: Icon(
                              Icons.apartment_rounded,
                              color: theme.colorScheme.primary,
                              size: 36,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        child: Center(
                          child: Icon(
                            Icons.apartment_rounded,
                            color: theme.colorScheme.primary,
                            size: 36,
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.70),
                            Colors.black.withOpacity(0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    department.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    department.description.isNotEmpty
                        ? department.description
                        : l10n.noDescriptionAvailable,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    department.schoolId.isNotEmpty
                        ? l10n.schoolLabel(department.schoolId)
                        : l10n.schoolNotSet,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: theme.hintColor,
              ),
            ),
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.35)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: l10n.searchNameMatriculeHint,
          prefixIcon: const Icon(Iconsax.search_normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.theme,
    required this.onPromoteToContributor,
    required this.onPromoteToAdmin,
  });

  final UserProfile user;
  final ThemeData theme;
  final VoidCallback onPromoteToContributor;
  final VoidCallback onPromoteToAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = user.role;
    final canPromoteToContributor = role == UserRole.viewer;
    final canPromoteToAdmin = role != UserRole.admin;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
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
                  style: GoogleFonts.outfit(fontSize: 12, color: theme.hintColor),
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
          const SizedBox(width: 10),
          Column(
            children: [
              if (canPromoteToContributor)
                _MiniActionButton(
                  label: l10n.roleLabelContributor,
                  color: Colors.blue,
                  onTap: onPromoteToContributor,
                ),
              if (canPromoteToAdmin) ...[
                const SizedBox(height: 8),
                _MiniActionButton(
                  label: l10n.roleLabelAdmin,
                  color: Colors.indigo,
                  onTap: onPromoteToAdmin,
                ),
              ],
            ],
          ),
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
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(88, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
