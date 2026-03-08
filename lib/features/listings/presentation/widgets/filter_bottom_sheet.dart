import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';

import 'package:house_rental/core/widgets/glass_container.dart';

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
  String? _allowedTenants;
  bool _isVerified = false;
  final List<String> _selectedAmenities = [];

  final List<String> _furnishingOptions = ['Furnished', 'Semi-furnished', 'Unfurnished'];
  final List<String> _tenantOptions = ['Bachelors', 'Family', 'Company'];
  final List<String> _amenityOptions = ['Parking', 'Security', 'Lift', 'Gym', 'Pool', 'Backup', 'CCTV'];

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(searchFilterProvider);
    _priceRange = RangeValues(
      (currentFilter.minPrice ?? 0).toDouble().clamp(0.0, 200000.0),
      (currentFilter.maxPrice ?? 200000).toDouble().clamp(0.0, 200000.0),
    );
    _bedrooms = currentFilter.bedrooms;
    _bathrooms = currentFilter.bathrooms;
    _furnishing = currentFilter.furnishing;
    _allowedTenants = currentFilter.allowedTenants;
    _isVerified = currentFilter.isVerified ?? false;
    if (currentFilter.amenities != null) {
      _selectedAmenities.addAll(currentFilter.amenities!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GlassContainer(
      blur: 30, // Extra blur for bottom sheet
      opacity: isDark ? 0.95 : 0.85, // Highly opaque as requested
      color: isDark ? const Color(0xFF0F0F12) : Colors.white, // Very dark base
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(searchFilterProvider.notifier).state = ListingFilter();
                    Navigator.pop(context);
                  },
                  child: Text('Reset', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Price Range
            Text(
              'Price Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 200000,
              divisions: 40,
              activeColor: primaryColor,
              inactiveColor: primaryColor.withOpacity(0.1),
              onChanged: (values) {
                setState(() => _priceRange = values);
              },
            ),

            const SizedBox(height: 32),

            // Bedrooms & Bathrooms
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<int>(
                    label: 'Bedrooms',
                    value: _bedrooms,
                    items: [1, 2, 3, 4, 5],
                    hint: 'Any',
                    onChanged: (v) => setState(() => _bedrooms = v),
                    itemLabel: (v) => '$v BHK',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField<int>(
                    label: 'Bathrooms',
                    value: _bathrooms,
                    items: [1, 2, 3, 4],
                    hint: 'Any',
                    onChanged: (v) => setState(() => _bathrooms = v),
                    itemLabel: (v) => '$v Bath',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Furnishing
            Text(
              'Furnishing', 
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _furnishingOptions.map((e) => _buildChoiceChip(e, _furnishing == e, (selected) {
                setState(() => _furnishing = selected ? e : null);
              })).toList(),
            ),

            const SizedBox(height: 32),

            // Preferred Tenants
            Text(
              'Preferred Tenants', 
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tenantOptions.map((e) => _buildChoiceChip(e, _allowedTenants == e, (selected) {
                setState(() => _allowedTenants = selected ? e : null);
              })).toList(),
            ),

            const SizedBox(height: 32),

            // Verified Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Properties Only',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Show only properties verified by Nestora',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isVerified,
                  activeColor: primaryColor,
                  onChanged: (v) => setState(() => _isVerified = v),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Amenities
            Text(
              'Amenities', 
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _amenityOptions.map((e) => _buildChoiceChip(e, _selectedAmenities.contains(e), (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(e);
                  } else {
                    _selectedAmenities.remove(e);
                  }
                });
              })).toList(),
            ),

            const SizedBox(height: 48),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () {
                  final filter = ListingFilter(
                    minPrice: _priceRange.start,
                    maxPrice: _priceRange.end,
                    bedrooms: _bedrooms,
                    bathrooms: _bathrooms,
                    furnishing: _furnishing,
                    allowedTenants: _allowedTenants,
                    isVerified: _isVerified ? true : null,
                    amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
                  );
                  ref.read(searchFilterProvider.notifier).state = filter;
                  Navigator.pop(context);
                },
                child: const Text('Search Properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
          value: value,
          hint: Text(hint, style: const TextStyle(fontWeight: FontWeight.w500)),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(itemLabel(e)),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool selected, ValueChanged<bool> onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        labelStyle: TextStyle(
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          fontSize: 13,
        ),
        selectedColor: primaryColor,
        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
    );
  }
}
