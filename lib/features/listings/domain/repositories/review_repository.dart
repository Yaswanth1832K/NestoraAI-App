import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Either<Failure, void>> addReview(ReviewEntity review);
  Stream<List<ReviewEntity>> getReviews(String listingId);
}
