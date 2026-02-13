import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:house_rental/features/listings/data/datasources/listing_remote_datasource.dart';
import 'package:house_rental/features/listings/data/repositories/listing_repository_impl.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/listings/domain/usecases/create_listing_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/delete_listing_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/get_listing_by_id_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/get_listings_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/get_listings_in_bounds_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/get_nearby_listings_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/update_listing_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/get_my_listings_usecase.dart';

// Data Layer Providers
final listingRemoteDataSourceProvider = Provider<ListingRemoteDataSource>((ref) {
  return ListingRemoteDataSourceImpl(ref.read(firestoreProvider));
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepositoryImpl(ref.read(listingRemoteDataSourceProvider));
});

// Domain Layer Providers (UseCases)
final getListingsUseCaseProvider = Provider<GetListingsUseCase>((ref) {
  return GetListingsUseCase(ref.read(listingRepositoryProvider));
});

final getListingByIdUseCaseProvider = Provider<GetListingByIdUseCase>((ref) {
  return GetListingByIdUseCase(ref.read(listingRepositoryProvider));
});

final createListingUseCaseProvider = Provider<CreateListingUseCase>((ref) {
  return CreateListingUseCase(ref.read(listingRepositoryProvider));
});

final updateListingUseCaseProvider = Provider<UpdateListingUseCase>((ref) {
  return UpdateListingUseCase(ref.read(listingRepositoryProvider));
});

final deleteListingUseCaseProvider = Provider<DeleteListingUseCase>((ref) {
  return DeleteListingUseCase(ref.read(listingRepositoryProvider));
});

final getMyListingsUseCaseProvider = Provider<GetMyListingsUseCase>((ref) {
  return GetMyListingsUseCase(ref.read(listingRepositoryProvider));
});

final getNearbyListingsUseCaseProvider = Provider<GetNearbyListingsUseCase>((ref) {
  return GetNearbyListingsUseCase(ref.read(listingRepositoryProvider));
});

final nearbyListingsProvider = FutureProvider.family<List<ListingEntity>, ListingEntity>((ref, baseListing) async {
  final result = await ref.read(getNearbyListingsUseCaseProvider)(baseListing);
  return result.fold(
    (failure) => throw failure,
    (listings) => listings,
  );
});

final listingProvider = FutureProvider.family<ListingEntity, String>((ref, id) async {
  final result = await ref.read(getListingByIdUseCaseProvider)(id);
  return result.fold(
    (failure) => throw failure,
    (listing) => listing,
  );
});

final getListingsInBoundsUseCaseProvider = Provider<GetListingsInBoundsUseCase>((ref) {
  return GetListingsInBoundsUseCase(ref.read(listingRepositoryProvider));
});

// Provider to store map search results
final mapSearchResultsProvider = StateProvider<List<ListingEntity>>((ref) => []);

final searchFilterProvider = StateProvider<ListingFilter>((ref) => ListingFilter());

final filteredListingsProvider = FutureProvider<List<ListingEntity>>((ref) async {
  final filter = ref.watch(searchFilterProvider);
  final result = await ref.read(getListingsUseCaseProvider)(filter: filter);
  return result.fold(
    (failure) => throw failure,
    (listings) => listings,
  );
});
