import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:house_rental/core/providers/cloudinary_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';

class PostPropertyPage extends ConsumerStatefulWidget {
  final ListingEntity? existingListing;
  const PostPropertyPage({super.key, this.existingListing});

  @override
  ConsumerState<PostPropertyPage> createState() => _PostPropertyPageState();
}

class _PostPropertyPageState extends ConsumerState<PostPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  // Form Fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  int _bedrooms = 1;
  int _bathrooms = 1;
  final _sqftController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _latController = TextEditingController(text: '11.0168');
  final _lngController = TextEditingController(text: '76.9558');

  List<String> _existingImageUrls = [];
  List<XFile> _images = [];
  List<DateTime> _availableDates = [];
  bool _isLoading = false;
  String? _uploadStatus;

  @override
  void initState() {
    super.initState();
    if (widget.existingListing != null) {
      final listing = widget.existingListing!;
      _titleController.text = listing.title;
      _descController.text = listing.description;
      _priceController.text = listing.price.toStringAsFixed(0);
      _cityController.text = listing.city;
      _bedrooms = listing.bedrooms;
      _bathrooms = listing.bathrooms;
      _sqftController.text = listing.sqft.toStringAsFixed(0);
      _amenitiesController.text = listing.amenities.join(', ');
      _latController.text = listing.latitude.toString();
      _lngController.text = listing.longitude.toString();
      _existingImageUrls = List.from(listing.imageUrls);
      _availableDates = List.from(listing.availableDates);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _sqftController.dispose();
    _amenitiesController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalImages = _images.length + _existingImageUrls.length;
    if (totalImages >= 5) return;
    
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        limit: 5 - totalImages,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles);
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open gallery: $e')),
        );
      }
    }
  }

  Future<List<String>> _uploadImages(String listingId) async {
    List<String> urls = [];
    final cloudinaryService = ref.read(cloudinaryServiceProvider);

    for (int i = 0; i < _images.length; i++) {
      setState(() => _uploadStatus = 'Uploading image ${i + 1}/${_images.length}...');
      
      try {
        String url;
        if (kIsWeb) {
          final bytes = await _images[i].readAsBytes();
          url = await cloudinaryService.uploadImage(bytes);
        } else {
          url = await cloudinaryService.uploadImage(File(_images[i].path));
        }
        urls.add(url);
      } catch (e) {
        debugPrint('Cloudinary Upload Error for image $i: $e');
        if (e.toString().contains('timeout')) {
          throw Exception('Upload timed out. Please check your internet connection.');
        }
        rethrow;
      }
    }
    return urls;
  }

  Future<void> _fetchCoordinatesFromCity() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use Nominatim API (OpenStreetMap)
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$city&format=json&limit=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'HouseRentalApp/1.0',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = data[0]['lat'];
          final lon = data[0]['lon'];
          
          setState(() {
            _latController.text = lat.toString();
            _lngController.text = lon.toString();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Coordinates updated for $city!')),
            );
          }
        } else {
          throw Exception('City not found');
        }
      } else {
        throw Exception('Geocoding service error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch coordinates: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );

    if (picked != null && !_availableDates.contains(picked)) {
      setState(() {
        _availableDates.add(picked);
        _availableDates.sort();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_images.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least 1 image')),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post/update a property')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Starting upload...';
    });

    try {
      final isEditing = widget.existingListing != null;
      final listingId = isEditing ? widget.existingListing!.id : const Uuid().v4();
      
      // 1. Upload New Images
      final newImageUrls = await _uploadImages(listingId);
      final finalImageUrls = [..._existingImageUrls, ...newImageUrls];

      // 2. Create Listing Entity
      final double lat = double.tryParse(_latController.text.trim()) ?? 11.0168;
      final double lng = double.tryParse(_lngController.text.trim()) ?? 76.9558;
      
      final listing = ListingEntity(
        id: listingId,
        ownerId: isEditing ? widget.existingListing!.ownerId : user.uid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        address: {
          'city': _cityController.text.trim(),
          'lat': lat,
          'lng': lng,
        },
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        sqft: double.parse(_sqftController.text.trim()),
        amenities: _amenitiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        propertyType: 'apartment', // Default
        images: finalImageUrls,
        imageUrls: finalImageUrls,
        searchTokens: [], 
        latitude: lat,
        longitude: lng,
        status: 'active',
        createdAt: isEditing ? widget.existingListing!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        availableDates: _availableDates,
      );

      // 3. Save/Update to Firestore
      Either<Failure, void> result;
      if (isEditing) {
        result = await ref.read(updateListingUseCaseProvider)(listing);
      } else {
        result = await ref.read(createListingUseCaseProvider)(listing);
      }

      if (!mounted) return;

      result.fold(
        (failure) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to ${isEditing ? 'update' : 'post'}: ${failure.message}')),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Property ${isEditing ? 'updated' : 'posted'} successfully!')),
          );
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingListing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Property' : 'Post Your Property')),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_uploadStatus ?? 'Processing...'),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Property Images (Add at least 1)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Existing Images
                      ...List.generate(_existingImageUrls.length, (index) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_existingImageUrls[index], width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _existingImageUrls.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      // New Images
                      ...List.generate(_images.length, (index) => _ImageThumbnail(
                        file: _images[index],
                        onRemove: () => setState(() => _images.removeAt(index)),
                      )),
                      if (_images.length + _existingImageUrls.length < 5)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Icon(Icons.add_a_photo, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_titleController, 'Title', 'e.g. Luxury 2BHK in Indiranagar'),
                  _buildTextField(_descController, 'Description', 'Describe the property...', maxLines: 3),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_priceController, 'Price (₹)', '0', keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            _buildTextField(_cityController, 'City', 'e.g. Bangalore'),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16, right: 8),
                              child: IconButton(
                                icon: const Icon(Icons.location_searching, color: Colors.blue),
                                tooltip: 'Fetch Coordinates',
                                onPressed: _fetchCoordinatesFromCity,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bedrooms,
                          decoration: InputDecoration(
                            labelText: 'Bedrooms',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: List.generate(10, (index) => index + 1)
                              .map((e) => DropdownMenuItem(value: e, child: Text('$e BHK')))
                              .toList(),
                          onChanged: (v) => setState(() => _bedrooms = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bathrooms,
                          decoration: InputDecoration(
                            labelText: 'Bathrooms',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: List.generate(10, (index) => index + 1)
                              .map((e) => DropdownMenuItem(value: e, child: Text('$e Bath')))
                              .toList(),
                          onChanged: (v) => setState(() => _bathrooms = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                   _buildTextField(_sqftController, 'Area (Sqft)', '0', keyboardType: TextInputType.number),
                   _buildTextField(_amenitiesController, 'Amenities', 'Wifi, Parking, Lift (comma separated)'),
                   Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_latController, 'Latitude', '11.0168', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(_lngController, 'Longitude', '76.9558', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Set Availability (Renter Visit Dates)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._availableDates.map((date) => Chip(
                        label: Text('${date.day}/${date.month}/${date.year}'),
                        onDeleted: () => setState(() => _availableDates.remove(date)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                      )),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Add Date'),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: Text(isEditing ? 'Update Property' : 'Publish Property', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (keyboardType == const TextInputType.numberWithOptions(decimal: true) || 
              keyboardType == TextInputType.number) {
            if (double.tryParse(v) == null) return 'Invalid number';
          }
          return null;
        },
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _ImageThumbnail({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(file.path, width: 80, height: 80, fit: BoxFit.cover)
                : Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
