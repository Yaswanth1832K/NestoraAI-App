import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/listings/presentation/widgets/filter_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  ListingEntity? _selectedListing;
  bool _isLoading = false;
  
  // Default center: Coimbatore
  static const LatLng _coimbatoreCenter = LatLng(11.0168, 76.9558);

  @override
  void initState() {
    super.initState();
    // Initial fetch
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
    ref.listen(searchFilterProvider, (_, __) {
      _fetchInitialListings();
    });

    // Group listings by coordinate to detect overlaps
    final Map<String, int> coordinateCounts = {};
    
    final markers = listings.map<Marker>((listing) {
      final String coordKey = '${listing.latitude}_${listing.longitude}';
      final int count = coordinateCounts[coordKey] ?? 0;
      coordinateCounts[coordKey] = count + 1;

      // Apply a tiny offset (jitter) for overlapping markers
      // 0.00008 is roughly 8-10 meters, enough to separate them at high zoom
      double jitterLat = listing.latitude;
      double jitterLng = listing.longitude;
      
      if (count > 0) {
        // Spiral-like offset based on how many share the point
        jitterLat += 0.0001 * (count % 2 == 0 ? 1 : -1) * (count / 2).ceil();
        jitterLng += 0.0001 * (count % 3 == 0 ? 1 : -1) * (count / 3).ceil();
      }

      return Marker(
        markerId: MarkerId(listing.id),
        position: LatLng(jitterLat, jitterLng),
        infoWindow: InfoWindow(
          title: listing.title,
          snippet: '₹${listing.price.toStringAsFixed(0)}',
        ),
        onTap: () {
          setState(() {
            _selectedListing = listing;
          });
        },
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchInitialListings(),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: _coimbatoreCenter,
              zoom: 12,
            ),
            markers: markers,
            onTap: (_) {
              setState(() {
                _selectedListing = null;
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          if (_isLoading)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading listings...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_selectedListing != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildListingPreviewCard(_selectedListing!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListingPreviewCard(ListingEntity listing) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          rootNavigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => ListingDetailsPage(listing: listing),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: listing.allImages.isNotEmpty
                      ? Image.network(
                          listing.allImages.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(color: Colors.white),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.blue.shade50,
                            child: const Icon(Icons.broken_image, color: Colors.blue),
                          ),
                        )
                      : Container(
                          color: Colors.blue.shade50,
                          child: const Icon(Icons.home, color: Colors.blue),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${listing.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          listing.city,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      rootNavigatorKey.currentState!.push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailsPage(listing: listing),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
