import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/core/errors/exceptions.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/data/models/listing_model.dart';

abstract interface class FavoritesRemoteDataSource {
  Future<bool> toggleFavorite(String userId, ListingEntity listing);
  Stream<Set<String>> watchFavoriteIds(String userId);
  Stream<List<ListingEntity>> watchFavoriteListings(String userId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  final FirebaseFirestore _firestore;

  FavoritesRemoteDataSourceImpl(this._firestore);

  @override
  Future<bool> toggleFavorite(String userId, ListingEntity listing) async {
    try {
      // Query for an existing favorite for this user and listing
      final query = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('listingId', isEqualTo: listing.id)
          .get();

      if (query.docs.isNotEmpty) {
        // Exists -> Delete it
        debugPrint('FavoritesRemoteDataSource: Removing favorite ${listing.id}');
        await query.docs.first.reference.delete();
        return false; // Not favorite anymore
      } else {
        // Doesn't exist -> Create it
        debugPrint('FavoritesRemoteDataSource: Adding favorite ${listing.id}');
        await _firestore.collection('favorites').add({
          'userId': userId,
          'listingId': listing.id,
          'title': listing.title,
          'image': listing.allImages.isNotEmpty ? listing.allImages.first : '',
          'price': listing.price,
          'city': listing.city,
          'createdAt': FieldValue.serverTimestamp(),
          // Store minimal fields to reconstruct a partial ListingEntity for display
          'bedrooms': listing.bedrooms,
          'bathrooms': listing.bathrooms,
          'sqft': listing.sqft,
          'address': listing.address, 
          'propertyType': listing.propertyType,
        });
        return true; // Is favorite now
      }
    } catch (e) {
      debugPrint('FavoritesRemoteDataSource: Error during toggle: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<Set<String>> watchFavoriteIds(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc['listingId'] as String).toSet();
    });
  }

  @override
  Stream<List<ListingEntity>> watchFavoriteListings(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final favorites = snapshot.docs.map((doc) {
        final data = doc.data();
        // Use either server timestamp or current date if pending
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        return ListingModel(
          id: data['listingId'] as String? ?? '',
          ownerId: '', // Not stored in favorite summary
          title: data['title'] as String? ?? 'Untitled',
          description: '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          currency: 'INR',
          propertyType: data['propertyType'] as String? ?? 'Apartment',
          furnishing: 'Unfurnished',
          bedrooms: (data['bedrooms'] as num?)?.toInt() ?? 0,
          bathrooms: (data['bathrooms'] as num?)?.toInt() ?? 0,
          sqft: (data['sqft'] as num?)?.toDouble() ?? 0.0,
          address: data['address'] != null 
              ? Map<String, dynamic>.from(data['address'] as Map) 
              : {'city': data['city'] ?? 'Unknown'},
          amenities: [],
          images: [],
          imageUrls: [if (data['image'] != null && data['image'].toString().isNotEmpty) data['image']],
          searchTokens: [],
          status: 'active',
          createdAt: createdAt,
          updatedAt: DateTime.now(),
        );
      }).toList();

      // Sort in-memory to avoid index requirement
      favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return favorites;
    });
  }
}
