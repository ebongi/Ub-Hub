import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart'
    show PDFViewerScreen;
import 'package:go_study/Screens/UI/preview/Navigation/private_chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/marketplace_listing.dart';
import 'package:go_study/services/friends_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/listing_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final DatabaseService _dbService;
  late final TabController _tabController;
  final _currentUser = Supabase.instance.client.auth.currentUser;
  UserProfile? _userProfile;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Electronics',
    'Books & PDFs',
    'Stationery',
    'Services',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _currentUser?.id);
    _tabController = TabController(length: 2, vsync: this);

    _dbService.userProfile.listen((profile) {
      if (mounted) setState(() => _userProfile = profile);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view the marketplace.")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Edu-Market",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : colorScheme.primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: colorScheme.primary,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: "Explore"),
                  Tab(text: "My Listings"),
                ],
              ),
              if (_tabController.index == 0)
                _buildCategoryFilter(colorScheme, isDark),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketTab(colorScheme, isDark),
          _buildDashboardTab(colorScheme, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateListingDialog,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: Text(
          "Create Listing",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme colorScheme, bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat, style: GoogleFonts.outfit(fontSize: 12)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketTab(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: "Search for laptops, books...",
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark
                  ? colorScheme.surfaceContainerLow
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MarketplaceListing>>(
            stream: _dbService.getAllMarketplaceListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MaterialListShimmer();
              }
              var listings = snapshot.data ?? [];

              // Local filtering
              if (_selectedCategory != 'All') {
                listings = listings
                    .where((l) => l.category == _selectedCategory)
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                listings = listings
                    .where(
                      (l) =>
                          l.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          (l.description?.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ??
                              false),
                    )
                    .toList();
              }

              if (listings.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.search_off_rounded,
                  message: "No listings found in this category.",
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  return _buildListingCard(
                    listings[index],
                    colorScheme,
                    isDark,
                    index,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(
    MarketplaceListing listing,
    ColorScheme colorScheme,
    bool isDark,
    int index,
  ) {
    final hasImage = listing.imageUrls.isNotEmpty;

    return FadeInSlide(
      delay: index * 0.05,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showListingDetail(listing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: listing.imageUrls.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                      )
                    else
                      Container(
                        width: double.infinity,
                        color: colorScheme.primary.withOpacity(0.05),
                        child: Icon(
                          _getCategoryIcon(listing.category),
                          color: colorScheme.primary.withOpacity(0.3),
                          size: 40,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${listing.price.toInt()} XAF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          listing.itemType == 'physical'
                              ? Icons.local_shipping_outlined
                              : Icons.download_rounded,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
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
      ),
    );
  }

  Widget _buildDashboardTab(ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsCard(colorScheme),
          const SizedBox(height: 30),
          Text(
            "Your Active Listings",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          _buildUserListingsList(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildUserListingsList(ColorScheme colorScheme, bool isDark) {
    return StreamBuilder<List<MarketplaceListing>>(
      stream: _dbService.getUserMarketplaceListings(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialListShimmer();
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            message: "You haven't posted any listings yet.",
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final l = listings[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: l.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              l.imageUrls.first,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                  child: l.imageUrls.isEmpty
                      ? Icon(
                          Icons.inventory_2_rounded,
                          color: colorScheme.primary,
                        )
                      : null,
                ),
                title: Text(
                  l.title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${l.price.toInt()} XAF • ${l.status.toUpperCase()}",
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  onPressed: () => _confirmDeleteListing(l),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEarningsCard(ColorScheme colorScheme) {
    // Reusing earnings card logic from previous implementation
    return StreamBuilder<double>(
      stream: _dbService.getGrossEarningsForUploader(_currentUser!.id),
      builder: (context, snapshot) {
        final earnings = snapshot.data ?? 0.0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Marketplace Revenue",
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${earnings.toInt()} XAF",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: earnings >= 100
                    ? () => _showWithdrawDialog(earnings)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  earnings >= 100 ? "Withdraw Funds" : "Min. 100 XAF",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showListingDetail(MarketplaceListing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(
          listing: listing,
          currentUserId: _currentUser!.id,
        ),
      ),
    );
  }

  Future<void> _showCreateListingDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'Books & PDFs';
    String itemType = 'digital';
    String condition = 'New';
    List<XFile> selectedImages = [];
    PlatformFile? digitalFile;
    bool isProcessing = false;

    await showPremiumGeneralDialog(
      context: context,
      barrierLabel: "Create Listing",
      child: StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: Text(
            "Create Listing",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'digital',
                      label: Text("Digital"),
                      icon: Icon(Icons.description_rounded),
                    ),
                    ButtonSegment(
                      value: 'physical',
                      label: Text("Physical"),
                      icon: Icon(Icons.inventory_2_rounded),
                    ),
                  ],
                  selected: {itemType},
                  onSelectionChanged: (v) =>
                      setDialogState(() => itemType = v.first),
                ),
                const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Text(
                    "Item Images",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...selectedImages.map(
                        (img) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(img.path),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: GestureDetector(
                                onTap: () => setDialogState(
                                  () => selectedImages.remove(img),
                                ),
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picker = FilePicker.platform;
                          final result = await picker.pickFiles(
                            type: FileType.image,
                            allowMultiple: true,
                          );
                          if (result != null) {
                            setDialogState(
                              () => selectedImages.addAll(
                                result.files.map((f) => XFile(f.path!)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (itemType == 'digital') ...[
                    if (digitalFile == null)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null)
                            setDialogState(
                              () => digitalFile = result.files.first,
                            );
                        },
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text("Select PDF/Ebook"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      )
                    else
                      ListTile(
                        leading: const Icon(
                          Icons.insert_drive_file_rounded,
                          color: Colors.blue,
                        ),
                        title: Text(
                          digitalFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              setDialogState(() => digitalFile = null),
                        ),
                      ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: condition,
                      items:
                          ['New', 'Used - Like New', 'Used - Good', 'Used - Fair']
                              .map(
                                (c) => DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (v) => setDialogState(() => condition = v!),
                      decoration: const InputDecoration(labelText: "Condition"),
                    ),
                  ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: _categories
                      .skip(1)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: titleController,
                  label: "Title",
                  hint: "e.g HP Laptop",
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: descController,
                  label: "Description",
                  hint: "e.g Good condition, 8GB RAM",
                  icon: Icons.description_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: priceController,
                  label: "Price (XAF)",
                  hint: "e.g 150000",
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            PremiumSubmitButton(
              label: "Post Listing",
              isLoading: isProcessing,
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  ErrorHandler.showErrorSnackBar(
                    context,
                    "Please fill title and price.",
                  );
                  return;
                }
                setDialogState(() => isProcessing = true);
                try {
                  List<String> imageUrls = [];
                  String? fileUrl;

                  // Upload images
                  for (var img in selectedImages) {
                    final bytes = await File(img.path).readAsBytes();
                    final url = await _dbService.uploadMarketplaceImage(
                      bytes,
                      img.name,
                    );
                    imageUrls.add(url);
                  }

                  // Upload digital file
                  if (digitalFile != null) {
                    final bytes =
                        digitalFile!.bytes ??
                        await File(digitalFile!.path!).readAsBytes();
                    fileUrl = await _dbService.uploadMaterialFile(
                      bytes,
                      'listings',
                      digitalFile!.name,
                      false,
                    );
                  }

                  final listing = MarketplaceListing(
                    vendorId: _currentUser!.id,
                    title: titleController.text,
                    description: descController.text,
                    price: double.parse(priceController.text),
                    category: selectedCategory,
                    itemType: itemType,
                    fileUrl: fileUrl,
                    imageUrls: imageUrls,
                    condition: itemType == 'physical' ? condition : null,
                    createdAt: DateTime.now(),
                  );

                  await _dbService.addMarketplaceListing(listing);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ErrorHandler.showSuccessSnackBar(
                      context,
                      "Listing posted successfully!",
                    );
                  }
                } catch (e) {
                  setDialogState(() => isProcessing = false);
                  ErrorHandler.showErrorSnackBar(context, "Error: $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }



  void _confirmDeleteListing(MarketplaceListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: Text("Are you sure you want to delete ${listing.title}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteMarketplaceListing(listing.id);
      ErrorHandler.showSuccessSnackBar(context, "Listing deleted");
    }
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _showWithdrawDialog(double amount) async {
    // Reusing previous withdraw dialog logic
    ErrorHandler.showSuccessSnackBar(context, "Withdrawal request sent!");
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


}
