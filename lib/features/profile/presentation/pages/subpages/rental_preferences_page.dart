import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class RentalPreferencesPage extends StatefulWidget {
  const RentalPreferencesPage({super.key});

  @override
  State<RentalPreferencesPage> createState() => _RentalPreferencesPageState();
}

class _RentalPreferencesPageState extends State<RentalPreferencesPage> {
  // Existing
  String _currency = 'USD';
  String _unitSystem = 'Metric';
  bool _instantBook = false;

  // New Fields
  String _propertyType = 'Apartment';
  final List<String> _propertyTypes = ['Apartment', 'House', 'Villa', 'Condo', 'Studio'];
  
  RangeValues _budgetRange = const RangeValues(500, 3000);
  final TextEditingController _locationController = TextEditingController();
  
  int _bedrooms = 1;
  
  final Map<String, bool> _amenities = {
    'Wi-Fi': false,
    'Parking': false,
    'Air Conditioning': false,
    'Gym': false,
    'Pool': false,
    'Kitchen': false,
  };

  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preferences saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rental Preferences")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Regional Settings"),
          ListTile(
            title: const Text("Currency"),
            subtitle: Text(_currency),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _currency = _currency == 'USD' ? 'EUR' : 'USD';
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Currency changed to $_currency")));
            },
          ),
          ListTile(
            title: const Text("Unit System"),
            subtitle: Text(_unitSystem),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
               setState(() {
                _unitSystem = _unitSystem == 'Metric' ? 'Imperial' : 'Metric';
              });
            },
          ),
          const Divider(),
          
          _buildSectionHeader("Booking Settings"),
          SwitchListTile(
            title: const Text("Instant Book"),
            subtitle: const Text("Allow guests to book without approval"),
            value: _instantBook,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _instantBook = val),
          ),
          const Divider(),

          _buildSectionHeader("Property Preferences"),
          
          // Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Preferred Location",
                hintText: "e.g. Downtown, Suburbs",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
          ),
          
          // Property Type
          ListTile(
            title: const Text("Property Type"),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _propertyType,
                items: _propertyTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _propertyType = val);
                },
              ),
            ),
          ),

          // Budget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Budget Range (Monthly)"),
                    Text(
                      "\$${_budgetRange.start.round()} - \$${_budgetRange.end.round()}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _budgetRange,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  activeColor: AppColors.primary,
                  labels: RangeLabels(
                    "\$${_budgetRange.start.round()}",
                    "\$${_budgetRange.end.round()}",
                  ),
                  onChanged: (values) => setState(() => _budgetRange = values),
                ),
              ],
            ),
          ),

          // Bedrooms
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bedrooms"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(4, (index) {
                    final count = index + 1;
                    final isSelected = _bedrooms == count;
                    return ChoiceChip(
                      label: Text(count == 4 ? "4+" : "$count"),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _bedrooms = count);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          
          // Amenities
          ExpansionTile(
            title: const Text("Preferred Amenities"),
            children: _amenities.keys.map((key) {
              return CheckboxListTile(
                title: Text(key),
                value: _amenities[key],
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _amenities[key] = val ?? false);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _savePreferences,
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
