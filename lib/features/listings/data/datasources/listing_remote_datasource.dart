import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/core/constants/firestore_constants.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/listings/data/models/listing_model.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/utils/demo_listings_data.dart';

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

  ListingRemoteDataSourceImpl(this._firestore);

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
      if (lastListingId != null) return [];

      final targetCity = (filter?.city == null || filter?.city == 'Unknown')
          ? 'Coimbatore'
          : filter!.city!;

      // Always generate a large pool of demo listings for the target city
      List<ListingModel> allDemo =
          DemoListingsData.generateDemoListings(targetCity, 50)
              .map((e) => ListingModel.fromEntity(e))
              .toList();

      // Manual filtering on the demo data to match user's UI filters
      if (filter != null) {
        allDemo = allDemo.where((l) {
          if (filter.propertyType != null && l.propertyType != filter.propertyType) return false;
          if (filter.minPrice != null && l.price < filter.minPrice!) return false;
          if (filter.maxPrice != null && l.price > filter.maxPrice!) return false;
          if (filter.bedrooms != null && l.bedrooms < filter.bedrooms!) return false;
          if (filter.isVerified == true && l.averageRating < 4.0) return false;
          return true;
        }).toList();
      }
      return allDemo.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching listings: $e');
      }
      return [];
    }
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

      if (results.isNotEmpty) return results;
      throw Exception('Fallback');
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
    await _firestore.collection(FirestoreConstants.listings).doc(listing.id).set(listing.toJson());
  }

  @override
  Future<void> updateListing(ListingModel listing) async {
    await _firestore.collection(FirestoreConstants.listings).doc(listing.id).update(listing.toJson());
  }

  @override
  Future<void> deleteListing(String id) async {
    await _firestore.collection(FirestoreConstants.listings).doc(id).delete();
  }
}
