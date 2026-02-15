import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/campus_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampusNavigatorScreen extends StatefulWidget {
  const CampusNavigatorScreen({super.key});

  @override
  State<CampusNavigatorScreen> createState() => _CampusNavigatorScreenState();
}

class _CampusNavigatorScreenState extends State<CampusNavigatorScreen> {
  late GoogleMapController _mapController;
  late final DatabaseService _dbService;
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;

  // University of Buea Main Campus Coordinates
  static const LatLng _ubLocation = LatLng(4.1561, 9.2736);

  Set<Marker> _markers = {};
  List<CampusLocation> _locations = [];
  CampusLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    // In a real app, this would come from the stream.
    // For the demo, we'll listen to the stream and update markers.
    _dbService.getCampusLocations().listen((locations) {
      if (mounted) {
        setState(() {
          _locations = locations;
          _markers = locations
              .map(
                (loc) => Marker(
                  markerId: MarkerId(loc.id),
                  position: LatLng(loc.latitude, loc.longitude),
                  infoWindow: InfoWindow(
                    title: loc.name,
                    snippet: loc.category.toUpperCase(),
                  ),
                  onTap: () => setState(() => _selectedLocation = loc),
                ),
              )
              .toSet();
        });
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _moveToLocation(CampusLocation loc) {
    setState(() => _selectedLocation = loc);
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Campus Navigator",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _ubLocation,
              zoom: 16,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // Search/List Overlay
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: _buildSearchBar(colorScheme),
          ),

          // Selection Detail Card
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: _buildDetailCard(colorScheme),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_ubLocation, 16),
        ),
        child: const Icon(Icons.home_work_rounded),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onTap: () => _showLocationSearch(),
        readOnly: true,
        decoration: InputDecoration(
          hintText: "Search halls, labs, offices...",
          hintStyle: GoogleFonts.outfit(color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedLocation!.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedLocation!.category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedLocation = null),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _selectedLocation!.description,
            style: GoogleFonts.outfit(color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Would link to native maps for turn-by-turn
            },
            icon: const Icon(Icons.directions_rounded),
            label: Text(
              "Get Directions",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "All Locations",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    return ListTile(
                      leading: _getCategoryIcon(loc.category),
                      title: Text(
                        loc.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        loc.category.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _moveToLocation(loc);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'amphi':
        return const Icon(Icons.school_rounded, color: Colors.blue);
      case 'lab':
        return const Icon(Icons.science_rounded, color: Colors.purple);
      case 'restaurant':
        return const Icon(Icons.restaurant_rounded, color: Colors.orange);
      case 'clinic':
        return const Icon(Icons.local_hospital_rounded, color: Colors.red);
      default:
        return const Icon(Icons.location_on_rounded, color: Colors.grey);
    }
  }
}
