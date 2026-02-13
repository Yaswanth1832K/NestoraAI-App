import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/data/datasources/favorites_remote_datasource.dart';
import 'package:house_rental/features/listings/data/repositories/favorites_repository_impl.dart';
import 'package:house_rental/features/listings/domain/repositories/favorites_repository.dart';
import 'package:house_rental/features/listings/domain/usecases/watch_favorite_ids_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/watch_favorite_listings_usecase.dart';
import 'package:house_rental/features/listings/domain/usecases/toggle_favorite_usecase.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';

// Data Layer
final favoritesRemoteDataSourceProvider = Provider<FavoritesRemoteDataSource>((ref) {
  return FavoritesRemoteDataSourceImpl(ref.read(firestoreProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.read(favoritesRemoteDataSourceProvider));
});

// Use Cases
final toggleFavoriteUseCaseProvider = Provider<ToggleFavoriteUseCase>((ref) {
  return ToggleFavoriteUseCase(ref.read(favoritesRepositoryProvider));
});

final watchFavoriteIdsUseCaseProvider = Provider<WatchFavoriteIdsUseCase>((ref) {
  return WatchFavoriteIdsUseCase(ref.read(favoritesRepositoryProvider));
});

final watchFavoriteListingsUseCaseProvider = Provider<WatchFavoriteListingsUseCase>((ref) {
  return WatchFavoriteListingsUseCase(ref.read(favoritesRepositoryProvider));
});
