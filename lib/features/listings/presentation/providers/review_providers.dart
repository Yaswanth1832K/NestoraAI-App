import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/listings/data/repositories/review_repository_impl.dart';
import 'package:house_rental/features/listings/domain/entities/review_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/review_repository.dart';
import 'package:house_rental/features/listings/domain/usecases/add_review_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/get_reviews_usecase.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.read(firestoreProvider));
});

final addReviewUseCaseProvider = Provider<AddReviewUseCase>((ref) {
  return AddReviewUseCase(ref.read(reviewRepositoryProvider));
});

final getReviewsUseCaseProvider = Provider<GetReviewsUseCase>((ref) {
  return GetReviewsUseCase(ref.read(reviewRepositoryProvider));
});

final reviewsStreamProvider = StreamProvider.family<List<ReviewEntity>, String>((ref, listingId) {
  return ref.read(getReviewsUseCaseProvider)(listingId);
});
