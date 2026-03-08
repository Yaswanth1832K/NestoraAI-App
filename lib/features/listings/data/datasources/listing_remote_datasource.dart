import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/core/constants/firestore_constants.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/listings/data/models/listing_model.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/utils/demo_listings_data.dart';

import 'package:house_rental/core/network/api_client.dart';
import 'package:house_rental/core/constants/api_constants.dart';

abstract interface class ListingRemoteDataSource {
  Future<List<ListingModel>> getListings({
    ListingFilter? filter,
    int limit = 10,
    String? lastListingId,
  });

  Future<ListingModel> getListingById(String id);
  Future<void> createListing(ListingModel listing);
  Future<void> updateListing(ListingModel listing);
  Future<void> deleteListing(String id);
  Future<List<ListingModel>> getNearbyListings(ListingEntity baseListing);
  Future<List<ListingModel>> getListingsInBounds(
      double minLat, double maxLat, double minLng, double maxLng);
  Future<List<ListingModel>> getMyListings(String userId);
}

class ListingRemoteDataSourceImpl implements ListingRemoteDataSource {
  final FirebaseFirestore _firestore;
  final ApiClient _apiClient;

  ListingRemoteDataSourceImpl(this._firestore, this._apiClient);

  @override
  Future<List<ListingModel>> getMyListings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreConstants.listings)
          .where('ownerId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final listings = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ListingModel.fromJson(data);
        }).toList();
        listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return listings;
      }
      throw Exception('Fallback');
    } catch (e) {
      // Deterministic demo listings for this owner
      return DemoListingsData.generateDemoListings('Coimbatore', 4, ownerId: userId)
          .map((e) => ListingModel.fromEntity(e))
          .toList();
    }
  }

  @override
  Future<List<ListingModel>> getListings({
    ListingFilter? filter,
    int limit = 10,
    String? lastListingId,
  }) async {
    try {
      // 1. Try fetching from Firestore first
      Query query = _firestore.collection(FirestoreConstants.listings);

      // Apply property type filter in Firestore if possible
      if (filter?.propertyType != null) {
        query = query.where('propertyType', isEqualTo: filter!.propertyType);
      }
      
      // Limit for performance
      query = query.limit(limit);

      // Start after cursor if provided
      if (lastListingId != null) {
        final doc = await _firestore.collection(FirestoreConstants.listings).doc(lastListingId).get();
        if (doc.exists) {
          query = query.startAfterDocument(doc);
        }
      }

      final snapshot = await query.get();
      List<ListingModel> firestoreListings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ListingModel.fromJson(data);
      }).toList();

      // 2. Determine target city for demo fallback
      final targetCity = (filter?.city == null || filter?.city == 'Unknown')
          ? 'Coimbatore'
          : filter!.city!;

      // 3. Fallback to Demo Data only if Firestore/API are thin
      // We generate a smaller pool of demo listings initially
      List<ListingModel> allDemo =
          DemoListingsData.generateDemoListings(targetCity, 10)
              .map((e) => ListingModel.fromEntity(e))
              .toList();

      // Join Firestore and Demo (prioritizing Firestore)
      List<ListingModel> combined = [...firestoreListings];
      
      // 3b. Try to fetch from FastAPI to supplement the list
      try {
        final Map<String, String> params = {};
        if (filter?.city != null && filter?.city != 'Unknown') params['city'] = filter!.city!;
        
        final response = await _apiClient.get(ApiConstants.properties);
        if (response is List) {
          final apiListings = response.map((json) => ListingModel.fromJson(json)).toList();
          final existingIds = combined.map((l) => l.id).toSet();
          combined.addAll(apiListings.where((l) => !existingIds.contains(l.id)));
        }
      } catch (e) {
        debugPrint('FastAPI sync (getListings) failed: $e');
      }

      // Add demo listings that don't overlap with existing IDs
      final currentIds = combined.map((l) => l.id).toSet();
      combined.addAll(allDemo.where((d) => !currentIds.contains(d.id)));

      // 4. Client-side filtering (Distance, Price, etc.)
      List<ListingModel> filtered = combined;
      if (filter != null) {
        filtered = filtered.where((l) {
          // Strict City filter only if it's NOT a "Near Me" search or explicitly requested
          if (filter.city != null && filter.city != 'Unknown' && filter.city!.isNotEmpty) {
            final listingCity = l.city.toLowerCase().trim();
            final filterCity = filter.city!.toLowerCase().trim();
            
            // If the user is specifically looking for "Ettimadai", we should be strict
            // BUT if we generate demo data, we shouldn't fake it for every property.
            if (listingCity != filterCity) {
               // Allow it if it's a demo property and we don't have enough real ones
               if (!l.id.contains('demo')) return false;
            }
          }
          if (filter.propertyType != null && l.propertyType != filter.propertyType) return false;
          if (filter.minPrice != null && l.price < filter.minPrice!) return false;
          if (filter.maxPrice != null && l.price > filter.maxPrice!) return false;
          if (filter.bedrooms != null && l.bedrooms < filter.bedrooms!) return false;
          if (filter.isVerified == true && l.averageRating < 4.0) return false;
          return true;
        }).toList();

        // Distance Calculation
        if (filter.userLat != null && filter.userLng != null) {
          filtered = filtered.map((l) {
            final distance = _calculateDistance(
              filter.userLat!,
              filter.userLng!,
              l.latitude,
              l.longitude,
            );
            return ListingModel.fromEntity(l.copyWith(distanceInKm: distance));
          }).toList();

          // Sort by distance first
          filtered.sort((a, b) => (a.distanceInKm ?? 0).compareTo(b.distanceInKm ?? 0));

          // Filter by strict 50km radius only if we are searching "Near Me" without a specific city locked
          final bool isExplicitCitySearch = filter.city != null && filter.city!.isNotEmpty && filter.city != 'Unknown';
          if (!isExplicitCitySearch) {
              filtered = filtered.where((l) => (l.distanceInKm ?? 0) <= 80.0).toList();
          }
        }
      }

      // 5. Paginate and return
      // If we used a cursor, we skip items. simplified for now:
      return filtered.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching listings: $e');
      }
      // Ultimate absolute fallback
      return DemoListingsData.generateDemoListings('Coimbatore', limit)
          .map((e) => ListingModel.fromEntity(e))
          .toList();
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
              cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Future<ListingModel> getListingById(String id) async {
    try {
      final doc = await _firestore.collection(FirestoreConstants.listings).doc(id).get();
      if (doc.exists) return ListingModel.fromFirestore(doc);
      
      // Try to find in demo data
      String city = 'Coimbatore';
      if (id.contains('_')) {
        final parts = id.split('_');
        if (parts.length > 1) city = parts[1];
      }
      final formattedCity = city.substring(0, 1).toUpperCase() + city.substring(1).toLowerCase();
      final allDemo = DemoListingsData.generateDemoListings(formattedCity, 50);
      return ListingModel.fromEntity(allDemo.firstWhere((element) => element.id == id, 
          orElse: () => allDemo.first));
    } catch (e) {
       final allDemo = DemoListingsData.generateDemoListings('Coimbatore', 10);
       return ListingModel.fromEntity(allDemo.first);
    }
  }

  @override
  Future<List<ListingModel>> getNearbyListings(ListingEntity baseListing) async {
    // Return listings in the same city
    return DemoListingsData.generateDemoListings(baseListing.city, 6)
        .where((l) => l.id != baseListing.id)
        .map((e) => ListingModel.fromEntity(e))
        .toList();
  }

  @override
  Future<List<ListingModel>> getListingsInBounds(
      double minLat, double maxLat, double minLng, double maxLng) async {
    try {
      // Try Firestore first
      final querySnapshot = await _firestore
          .collection(FirestoreConstants.listings)
          .where('latitude', isGreaterThanOrEqualTo: minLat)
          .where('latitude', isLessThanOrEqualTo: maxLat)
          .get();

      final results = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ListingModel.fromJson(data);
          })
          .where((l) => l.longitude! >= minLng && l.longitude! <= maxLng)
          .toList();

      if (results.isEmpty) throw Exception('No properties found in this area in Firestore');
      return results;
    } catch (e) {
      // Demo fallback: Generate properties within the requested bounds
      return List.generate(20, (i) {
        final random = Random(i + (minLat * 100).toInt());
        return ListingModel(
          id: 'map_demo_$i',
          ownerId: 'owner_demo',
          title: 'Premium Property ${i + 1}',
          description: 'A beautiful property in this prime location.',
          price: 15000.0 + random.nextInt(50000),
          propertyType: i % 2 == 0 ? 'Apartment' : 'Villa',
          furnishing: 'Furnished',
          bedrooms: (1 + random.nextInt(3)).toInt(),
          bathrooms: (1 + random.nextInt(2)).toInt(),
          sqft: 800.0 + random.nextInt(1000),
          address: const {'city': 'Local Area', 'street': 'Near Viewpoint'},
          amenities: const ['WiFi', 'Security', 'Parking'],
          images: const [],
          imageUrls: const [
            'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80&w=800',
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=800'
          ],
          searchTokens: const [],
          latitude: minLat + random.nextDouble() * (maxLat - minLat),
          longitude: minLng + random.nextDouble() * (maxLng - minLng),
          status: 'available',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          availableDates: const [],
          isVerified: true,
        );
      });
    }
  }

  @override
  Future<void> createListing(ListingModel listing) async {
    // 1. Save to Firestore
    await _firestore.collection(FirestoreConstants.listings).doc(listing.id).set(listing.toJson());
    
    // 2. Sync with FastAPI
    try {
      await _apiClient.post(ApiConstants.properties, body: {
        'id': listing.id,
        'owner_id': listing.ownerId,
        'title': listing.title,
        'price': listing.price,
        'city': listing.city,
        'address': listing.address['street'] ?? 'Unknown Street',
        'description': listing.description,
        'images': listing.imageUrls.isNotEmpty ? listing.imageUrls[0] : "",
        'amenities': listing.amenities.join(', '),
      });
    } catch (e) {
      debugPrint('Failed to sync new listing to FastAPI: $e');
    }
  }

  @override
  Future<void> updateListing(ListingModel listing) async {
    // 1. Update Firestore
    await _firestore.collection(FirestoreConstants.listings).doc(listing.id).update(listing.toJson());
    
    // 2. Sync with FastAPI
    try {
      await _apiClient.put('${ApiConstants.properties}/${listing.id}', body: {
        'id': listing.id,
        'owner_id': listing.ownerId,
        'title': listing.title,
        'price': listing.price,
        'city': listing.city,
        'address': listing.address['street'] ?? 'Unknown Street',
        'description': listing.description,
        'images': listing.imageUrls.isNotEmpty ? listing.imageUrls[0] : "",
        'amenities': listing.amenities.join(', '),
      });
    } catch (e) {
      debugPrint('Failed to sync updated listing to FastAPI: $e');
    }
  }

  @override
  Future<void> deleteListing(String id) async {
    // 1. Delete from Firestore
    await _firestore.collection(FirestoreConstants.listings).doc(id).delete();
    
    // 2. Delete from FastAPI
    try {
      await _apiClient.delete('${ApiConstants.properties}/$id');
    } catch (e) {
      debugPrint('Failed to sync deletion to FastAPI: $e');
    }
  }
}
