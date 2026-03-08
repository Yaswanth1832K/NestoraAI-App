import 'package:flutter/material.dart';
import 'dart:async';
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
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:house_rental/features/location/location_provider.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  ListingEntity? _selectedListing;
  bool _isLoading = false;
  Position? _userPosition;
  
  // Default center: Coimbatore
  static const LatLng _coimbatoreCenter = LatLng(11.0168, 76.9558);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialListings();
    });
  }

  // Removed local _locateUser logic in favor of global userLocationProvider
  
  Timer? _moveTimer;

  void _onCameraMove(LatLngBounds? bounds) {
    if (bounds == null) return;
    _moveTimer?.cancel();
    _moveTimer = Timer(const Duration(milliseconds: 1000), () => _fetchListingsInBounds(bounds));
  }

  Future<void> _fetchListingsInBounds(LatLngBounds bounds) async {
    final result = await ref.read(getListingsInBoundsUseCaseProvider)(
      bounds.southWest.latitude,
      bounds.northEast.latitude,
      bounds.southWest.longitude,
      bounds.northEast.longitude,
    );

    result.fold(
      (failure) => null, // Ignore errors on move
      (listings) {
        if (!mounted) return;
        // Merge with existing unique listings to avoid flickering
        final current = ref.read(mapSearchResultsProvider);
        final existingIds = current.map((e) => e.id).toSet();
        final newListings = listings.where((l) => !existingIds.contains(l.id)).toList();
        if (newListings.isNotEmpty) {
           ref.read(mapSearchResultsProvider.notifier).state = [...current, ...newListings];
        }
      },
    );
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
    final locState = ref.watch(userLocationProvider);
    final userPos = locState.position;
    
    // Auto-refresh when filters change
    ref.listen(searchFilterProvider, (_, _) {
      _fetchInitialListings();
    });
    // Build Property Markers
    final markers = _buildMarkers(listings);
    
    // Add User Location Marker
    if (userPos != null) {
      markers.add(
        Marker(
          point: LatLng(userPos.latitude, userPos.longitude),
          width: 60,
          height: 60,
          child: Column(
            children: [
               Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(height: 4),
              GlassContainer.standard(
                context: context,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                borderRadius: 8,
                child: const Text('You', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos != null 
                  ? LatLng(userPos.latitude, userPos.longitude) 
                  : _coimbatoreCenter,
              initialZoom: 12,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedListing = null;
                });
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _onCameraMove(position.visibleBounds);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.nestora.app',
                maxZoom: 20,
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

          // Controls Group (Zoom & Location)
          Positioned(
            right: 24,
            bottom: _selectedListing != null ? 180 : 100,
            child: Column(
              children: [
                _buildMapActionIcon(Icons.my_location_rounded, () {
                  final pos = ref.read(userLocationProvider).position;
                  if (pos != null) {
                    _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
                  } else {
                    ref.read(userLocationProvider.notifier).updateLocation();
                  }
                }),
                const SizedBox(height: 12),
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
      child: GlassContainer(
        opacity: 0.9,
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.all(12),
        border: Border.all(color: Colors.white24, width: 1),
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
                    : Container(color: AppColors.primary.withOpacity(0.1)),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 16, 
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${listing.price.toInt()}',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${listing.city}, ${listing.propertyType}',
                          style: const TextStyle(
                            color: Colors.white60, 
                            fontSize: 12, 
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
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
