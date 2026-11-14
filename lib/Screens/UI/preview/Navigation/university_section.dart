import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/institution_about_screen.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/institution.dart';

/// Always-browsable set of every institution GoStudy supports, shown as a
/// row of selectable chips. Tapping a chip selects/switches the signed-in
/// user's institution — see [_handleSelect] for the select-vs-switch
/// distinction.
class UniversitySection extends StatelessWidget {
  const UniversitySection({
    super.key,
    required this.institutions,
    required this.selectedInstitutionId,
  });

  final List<Institution> institutions;
  final String? selectedInstitutionId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: institutions
              .map(
                (institution) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: UniversityChip(
                    institution: institution,
                    isSelected: institution.id == selectedInstitutionId,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class UniversityChip extends StatelessWidget {
  const UniversityChip({
    super.key,
    required this.institution,
    required this.isSelected,
  });

  final Institution institution;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasLogo = institution.logoUrl != null && institution.logoUrl!.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildChip(context, theme, isDark, hasLogo),
        Positioned(
          right: -2,
          top: -2,
          child: Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InstitutionAboutScreen(institution: institution),
                ),
              ),
              child: Tooltip(
                message: l10n.aboutInstitutionTooltip(institution.name),
                child: const Padding(
                  padding: EdgeInsets.all(3.0),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, ThemeData theme, bool isDark, bool hasLogo) {
    return ChoiceChip(
      avatar: CircleAvatar(
        backgroundColor: isSelected
            ? Colors.white.withOpacity(0.25)
            : theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
        backgroundImage: hasLogo
            ? CachedNetworkImageProvider(institution.logoUrl!)
            : null,
        onBackgroundImageError: hasLogo ? (_, __) {} : null,
        child: hasLogo
            ? null
            : Icon(
                Icons.account_balance_rounded,
                size: 14,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
              ),
      ),
      label: Text(
        institution.name,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (selected) {
        if (!selected) return;
        _handleSelect(context, institution);
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: const StadiumBorder(),
    );
  }

  Future<void> _handleSelect(BuildContext context, Institution institution) async {
    final userModel = context.read<UserModel>();
    if (institution.id == userModel.institutionId) return;

    final hasExistingInstitution =
        userModel.institutionId != null && userModel.institutionId!.isNotEmpty;

    if (hasExistingInstitution) {
      final confirmed = await _showSwitchConfirmDialog(context, institution.name);
      if (confirmed != true) return;
    }

    if (!context.mounted) return;

    final previousId = userModel.institutionId;
    final previousName = userModel.institutionName;

    HapticFeedback.lightImpact();
    userModel.setInstitutionId(institution.id);
    userModel.setInstitutionName(institution.name);

    try {
      await DatabaseService(
        uid: userModel.uid,
      ).updateUserData(institutionId: institution.id);
    } catch (e) {
      userModel.setInstitutionId(previousId);
      userModel.setInstitutionName(previousName);
      if (context.mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<bool?> _showSwitchConfirmDialog(BuildContext context, String newName) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Text(
          l10n.switchUniversityTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.switchUniversityBody(newName),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.switchUniversityConfirmButton,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
