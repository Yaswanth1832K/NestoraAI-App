import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late RangeValues _priceRange;
  int? _bedrooms;
  int? _bathrooms;
  String? _furnishing;
  final List<String> _selectedAmenities = [];

  final List<String> _furnishingOptions = ['Furnished', 'Semi-furnished', 'Unfurnished'];
  final List<String> _amenityOptions = ['Parking', 'WiFi', 'AC', 'Gym', 'Pool'];

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(searchFilterProvider);
    _priceRange = RangeValues(
      currentFilter.minPrice ?? 0,
      currentFilter.maxPrice ?? 100000,
    );
    _bedrooms = currentFilter.bedrooms;
    _bathrooms = currentFilter.bathrooms;
    _furnishing = currentFilter.furnishing;
    if (currentFilter.amenities != null) {
      _selectedAmenities.addAll(currentFilter.amenities!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchFilterProvider.notifier).state = ListingFilter();
                  Navigator.pop(context);
                },
                child: const Text('Reset All'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          // Price Range
          Text(
            'Price Range (₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 200000,
            divisions: 20,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.blueAccent.withOpacity(0.2),
            labels: RangeLabels(
              '₹${_priceRange.start.round()}',
              '₹${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
          ),

          const SizedBox(height: 24),

          // Bedrooms & Bathrooms
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bedrooms', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      initialValue: _bedrooms,
                      hint: const Text('Any'),
                      items: [1, 2, 3, 4].map((e) => DropdownMenuItem(
                        value: e,
                        child: Text('$e BHK'),
                      )).toList(),
                      onChanged: (v) => setState(() => _bedrooms = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bathrooms', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      initialValue: _bathrooms,
                      hint: const Text('Any'),
                      items: [1, 2, 3].map((e) => DropdownMenuItem(
                        value: e,
                        child: Text('$e Bath'),
                      )).toList(),
                      onChanged: (v) => setState(() => _bathrooms = v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Furnishing
          Text(
            'Furnishing', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _furnishingOptions.map((e) => ChoiceChip(
              label: Text(e),
              selected: _furnishing == e,
              onSelected: (selected) {
                setState(() => _furnishing = selected ? e : null);
              },
            )).toList(),
          ),

          const SizedBox(height: 24),

          // Amenities
          Text(
            'Amenities', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Wrap(
            spacing: 8,
            children: _amenityOptions.map((e) => FilterChip(
              label: Text(e),
              selected: _selectedAmenities.contains(e),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(e);
                  } else {
                    _selectedAmenities.remove(e);
                  }
                });
              },
            )).toList(),
          ),

          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final filter = ListingFilter(
                  minPrice: _priceRange.start,
                  maxPrice: _priceRange.end,
                  bedrooms: _bedrooms,
                  bathrooms: _bathrooms,
                  furnishing: _furnishing,
                  amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
                );
                ref.read(searchFilterProvider.notifier).state = filter;
                Navigator.pop(context);
              },
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
