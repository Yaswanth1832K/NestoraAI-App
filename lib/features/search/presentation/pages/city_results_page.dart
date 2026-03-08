import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/utils/demo_listings_data.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/l10n/generated/app_localizations.dart';
import 'package:house_rental/features/listings/presentation/widgets/filter_bottom_sheet.dart';

class CityResultsPage extends ConsumerStatefulWidget {
  final String city;
  final String? category;

  const CityResultsPage({super.key, required this.city, this.category});

  @override
  ConsumerState<CityResultsPage> createState() => _CityResultsPageState();
}

class _CityResultsPageState extends ConsumerState<CityResultsPage> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  late List<ListingEntity> _listings;
  late LatLng _cityCenter;

  @override
  void initState() {
    super.initState();
    _listings = DemoListingsData.generateDemoListings(widget.city, 12, category: widget.category);
    final coords = DemoListingsData.cityCenters[widget.city] ?? [11.0168, 76.9558];
    _cityCenter = LatLng(coords[0], coords[1]);
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    if (_sheetController.size > 0.5) {
      _sheetController.animateTo(0.25, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _sheetController.animateTo(0.95, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.city, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${l10n.bookingAvailable} • ${widget.category ?? l10n.allHomes}',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // Map in background
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _cityCenter,
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: _listings.map((l) {
                    return Marker(
                      point: LatLng(l.latitude, l.longitude),
                      width: 80,
                      height: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            '₹${l.price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Draggable Scrollable Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.6,
            minChildSize: 0.25,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: _listings.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _toggleSheet,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.rentalsIn(_listings.length.toString(), widget.city),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => FilterBottomSheet(),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.tune, size: 20),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListingCard(
                        listing: _listings[index - 2],
                        isVerticalFeed: true,
                        margin: const EdgeInsets.only(bottom: 24),
                        heroPrefix: 'city_results',
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
