import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/listings/presentation/widgets/filter_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  ListingEntity? _selectedListing;
  bool _isLoading = false;
  
  // Default center: Coimbatore
  static const LatLng _coimbatoreCenter = LatLng(11.0168, 76.9558);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialListings();
    });
  }

  Future<void> _fetchInitialListings() async {
    setState(() => _isLoading = true);
    final filter = ref.read(searchFilterProvider);
    final result = await ref.read(getListingsUseCaseProvider)(filter: filter);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${failure.message}')),
      ),
      (listings) {
        ref.read(mapSearchResultsProvider.notifier).state = listings;
      },
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(mapSearchResultsProvider);
    
    // Auto-refresh when filters change
    ref.listen(searchFilterProvider, (_, _) {
      _fetchInitialListings();
    });

    final Map<String, int> coordinateCounts = {};
    
    final markers = listings.map<Marker>((listing) {
      final String coordKey = '${listing.latitude}_${listing.longitude}';
      final int count = coordinateCounts[coordKey] ?? 0;
      coordinateCounts[coordKey] = count + 1;

      double jitterLat = listing.latitude;
      double jitterLng = listing.longitude;
      
      if (count > 0) {
        jitterLat += 0.0001 * (count % 2 == 0 ? 1 : -1) * (count / 2).ceil();
        jitterLng += 0.0001 * (count % 3 == 0 ? 1 : -1) * (count / 3).ceil();
      }

      return Marker(
        point: LatLng(jitterLat, jitterLng),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedListing = listing;
            });
            _mapController.move(LatLng(jitterLat, jitterLng), 14);
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  '₹${listing.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 30),
            ],
          ),
        ),
      );
    }).toList();
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _coimbatoreCenter,
              initialZoom: 12,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedListing = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.nestora.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          
          // Premium AppBar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20),
              child: Row(
                children: [
                  _buildMapActionIcon(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  const Spacer(),
                  _buildMapActionIcon(Icons.tune_rounded, () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const FilterBottomSheet(),
                    );
                  }),
                  const SizedBox(width: 12),
                  _buildMapActionIcon(Icons.refresh_rounded, _fetchInitialListings),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: GlassContainer.standard(
                  context: context,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  borderRadius: 30,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Scanning area...', 
                        style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).primaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_selectedListing != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildPremiumListingPreview(_selectedListing!),
              ),
            ),

          // Zoom Controls
          Positioned(
            right: 24,
            bottom: _selectedListing != null ? 220 : 100,
            child: Column(
              children: [
                _buildMapActionIcon(Icons.add_rounded, () {
                  final zoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, zoom);
                }),
                const SizedBox(height: 12),
                _buildMapActionIcon(Icons.remove_rounded, () {
                  final zoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, zoom);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionIcon(IconData icon, VoidCallback onTap) {
    return GlassContainer.standard(
      context: context,
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: IconButton(
        icon: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMarkerIcon(ListingEntity listing, bool isSelected) {
    final primaryColor = Theme.of(context).primaryColor;
    return Column(
      children: [
        AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isSelected ? 1.2 : 1.0,
          child: GlassContainer.standard(
            context: context,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            borderRadius: 12,
            child: Text(
              '₹${listing.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ),
        ),
        Icon(
          Icons.location_on_rounded, 
          color: isSelected ? primaryColor : primaryColor.withOpacity(0.7), 
          size: isSelected ? 40 : 34,
        ),
      ],
    );
  }

  Widget _buildPremiumListingPreview(ListingEntity listing) {
    return InkWell(
      onTap: () => context.push(AppRouter.listingDetails, extra: listing),
      child: GlassContainer.standard(
        context: context,
        borderRadius: 30,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 100,
                height: 100,
                child: listing.allImages.isNotEmpty
                    ? Image.network(
                        listing.allImages.first,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Theme.of(context).primaryColor.withOpacity(0.1)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${listing.price.toInt()}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.city}, ${listing.propertyType}',
                        style: TextStyle(
                          color: Theme.of(context).hintColor.withOpacity(0.6), 
                          fontSize: 12, 
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right_rounded, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  // Update build markers
  List<Marker> _buildMarkers(List<ListingEntity> listings) {
    final Map<String, int> coordinateCounts = {};
    return listings.map<Marker>((listing) {
      final String coordKey = '${listing.latitude}_${listing.longitude}';
      final int count = coordinateCounts[coordKey] ?? 0;
      coordinateCounts[coordKey] = count + 1;

      double jitterLat = listing.latitude;
      double jitterLng = listing.longitude;
      
      if (count > 0) {
        jitterLat += 0.0001 * (count % 2 == 0 ? 1 : -1) * (count / 2).ceil();
        jitterLng += 0.0001 * (count % 3 == 0 ? 1 : -1) * (count / 3).ceil();
      }

      final isSelected = _selectedListing?.id == listing.id;

      return Marker(
        point: LatLng(jitterLat, jitterLng),
        width: 100,
        height: 100,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedListing = listing);
            _mapController.move(LatLng(jitterLat, jitterLng), 14.5);
          },
          child: _buildMarkerIcon(listing, isSelected),
        ),
      );
    }).toList();
  }
}
