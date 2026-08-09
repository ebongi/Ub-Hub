import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_study/services/marketplace_listing.dart';
import 'package:go_study/services/friends_service.dart';
import 'package:go_study/Screens/UI/preview/Navigation/private_chat_screen.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListingDetailScreen extends StatelessWidget {
  final MarketplaceListing listing;
  final String currentUserId;

  const ListingDetailScreen({
    super.key,
    required this.listing,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = listing.vendorId == currentUserId;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: listing.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: listing.imageUrls.length,
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => _showFullScreenImage(context, listing.imageUrls[i]),
                        child: CachedNetworkImage(
                          imageUrl: listing.imageUrls[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        _getCategoryIcon(listing.category),
                        size: 100,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(listing.category.toUpperCase(), Colors.blue),
                      if (listing.condition != null)
                        _buildBadge(listing.condition!, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    listing.title,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${listing.price.toInt()} XAF",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.descriptionLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listing.description ?? l10n.noDescriptionProvided,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!isMe)
                    Column(
                      children: [
                        PremiumSubmitButton(
                          label: l10n.messageSellerButton,
                          isLoading: false,
                          onPressed: () => _messageSeller(context),
                        ),
                        if (listing.itemType == 'digital') ...[
                          const SizedBox(height: 12),
                          PremiumSubmitButton(
                            label: l10n.buyNowButton,
                            isLoading: false,
                            onPressed: () => _handleDigitalPurchase(context),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices_other_rounded;
      case 'Books & PDFs':
        return Icons.book_rounded;
      case 'Stationery':
        return Icons.edit_note_rounded;
      case 'Services':
        return Icons.build_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _messageSeller(BuildContext context) async {
    final vendorData = await Supabase.instance.client
        .from('profiles')
        .select('id, name, avatar_url')
        .eq('id', listing.vendorId)
        .single();

    final vendor = FriendProfile.fromJson(vendorData);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrivateChatScreen(
            friend: vendor,
            myId: currentUserId,
          ),
        ),
      );
    }
  }

  void _handleDigitalPurchase(BuildContext context) {
    ErrorHandler.showErrorSnackBar(
      context,
      AppLocalizations.of(context)!.digitalPurchaseComingSoonMessage,
    );
  }
}
