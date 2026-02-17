import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/data/models/review_model.dart';
import 'package:house_rental/features/listings/domain/entities/review_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, void>> addReview(ReviewEntity review) async {
    try {
      final reviewModel = ReviewModel(
        id: review.id,
        listingId: review.listingId,
        listingTitle: review.listingTitle,
        ownerId: review.ownerId,
        reviewerId: review.reviewerId,
        reviewerName: review.reviewerName,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.createdAt,
      );

      final listingRef = _firestore.collection('listings').doc(review.listingId);
      final reviewRef = _firestore.collection('reviews').doc(review.id);

      await _firestore.runTransaction((transaction) async {
        final listingSnapshot = await transaction.get(listingRef);
        if (!listingSnapshot.exists) {
          throw Exception('Listing does not exist');
        }

        final listingData = listingSnapshot.data() as Map<String, dynamic>;
        final double currentAvgRating = (listingData['averageRating'] as num?)?.toDouble() ?? 0.0;
        final int currentReviewCount = (listingData['reviewCount'] as int?) ?? 0;

        final int newReviewCount = currentReviewCount + 1;
        final double totalRatingPoints = (currentAvgRating * currentReviewCount) + review.rating;
        final double newAvgRating = totalRatingPoints / newReviewCount;

        transaction.set(reviewRef, reviewModel.toFirestore());
        transaction.update(listingRef, {
          'averageRating': newAvgRating,
          'reviewCount': newReviewCount,
        });
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<ReviewEntity>> getReviews(String listingId) {
    return _firestore
        .collection('reviews')
        .where('listingId', isEqualTo: listingId)
        .snapshots()
        .handleError((error) {
      debugPrint("================================================================");
      debugPrint("FIRESTORE INDEX ERROR: $error");
      debugPrint("================================================================");
    }).map((snapshot) {
      final reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
      // Sort in-memory to avoid index requirement
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }
}
