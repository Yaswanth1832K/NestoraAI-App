import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/core/constants/firestore_constants.dart';
import 'package:house_rental/core/errors/exceptions.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/listings/data/models/listing_model.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';

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

      final listings = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ListingModel.fromJson(data);
      }).toList();

      // Sort in-memory
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ListingModel>> getListings({
    ListingFilter? filter,
    int limit = 10,
    String? lastListingId,
  }) async {
    try {
      Query query = _firestore.collection(FirestoreConstants.listings);

      // Apply Filters
      if (filter != null) {
        if (filter.minPrice != null) {
          query = query.where('price', isGreaterThanOrEqualTo: filter.minPrice);
        }
        if (filter.maxPrice != null) {
          query = query.where('price', isLessThanOrEqualTo: filter.maxPrice);
        }
        if (filter.city != null) {
          query = query.where('address.city', isEqualTo: filter.city);
        }
        if (filter.bedrooms != null) {
          query = query.where('bedrooms', isEqualTo: filter.bedrooms);
        }
        if (filter.bathrooms != null) {
          query = query.where('bathrooms', isEqualTo: filter.bathrooms);
        }
        if (filter.furnishing != null) {
          query = query.where('furnishing', isEqualTo: filter.furnishing);
        }
        if (filter.propertyType != null) {
          query = query.where('propertyType', isEqualTo: filter.propertyType);
        }
        if (filter.amenities != null && filter.amenities!.isNotEmpty) {
          // Firestore only supports one array-contains per query.
          // For simplicity in this capstone, we filter by the first amenity.
          query = query.where('amenities', arrayContains: filter.amenities!.first);
        }
      }

      // Pagination
      if (lastListingId != null) {
        final lastDocSnapshot = await _firestore.collection(FirestoreConstants.listings).doc(lastListingId).get();
        if (lastDocSnapshot.exists) {
          query = query.startAfterDocument(lastDocSnapshot);
        }
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Fallback handle: ensure ID is present from document ID
        return ListingModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ListingModel> getListingById(String id) async {
    try {
      final docSnapshot = await _firestore.collection(FirestoreConstants.listings).doc(id).get();
      if (!docSnapshot.exists) {
        throw const ServerException(message: 'Listing not found');
      }
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id; // Map doc ID back to entity
      return ListingModel.fromJson(data);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> createListing(ListingModel listing) async {
    try {
      await _firestore.collection(FirestoreConstants.listings).doc(listing.id).set(listing.toJson());
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateListing(ListingModel listing) async {
    try {
      await _firestore.collection(FirestoreConstants.listings).doc(listing.id).update(listing.toJson());
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteListing(String id) async {
    try {
      await _firestore.collection(FirestoreConstants.listings).doc(id).delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ListingModel>> getNearbyListings(ListingEntity baseListing) async {
    try {
      final minPrice = baseListing.price * 0.8;
      final maxPrice = baseListing.price * 1.2;
      
      // Bedrooms ±1: [b-1, b, b+1]
      final bedroomList = {
        if (baseListing.bedrooms > 1) baseListing.bedrooms - 1,
        baseListing.bedrooms,
        baseListing.bedrooms + 1,
      }.toList();

      Query query = _firestore.collection(FirestoreConstants.listings);

      // Price Filter (Inequality)
      query = query.where('price', isGreaterThanOrEqualTo: minPrice)
                   .where('price', isLessThanOrEqualTo: maxPrice);

      // Bedrooms Filter (whereIn)
      query = query.where('bedrooms', whereIn: bedroomList);

      final snapshot = await query.limit(6).get(); // Limit extra to exclude self

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return ListingModel.fromJson(data);
          })
          .where((item) => item.id != baseListing.id)
          .take(5)
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ListingModel>> getListingsInBounds(
      double minLat, double maxLat, double minLng, double maxLng) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreConstants.listings)
          .where('latitude', isGreaterThanOrEqualTo: minLat)
          .where('latitude', isLessThanOrEqualTo: maxLat)
          .where('longitude', isGreaterThanOrEqualTo: minLng)
          .where('longitude', isLessThanOrEqualTo: maxLng)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ListingModel.fromJson(data);
          })
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
