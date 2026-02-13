import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/favorites_providers.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';

/// Notifier to manage the set of favorite listing IDs.
/// Uses StreamNotifier to handle real-time updates from Firestore.
class FavoritesNotifier extends StreamNotifier<Set<String>> {
  @override
  Stream<Set<String>> build() {
    // Automatically watch authState. If user logs in/out, build() re-runs.
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    
    if (user == null) {
      return Stream.value({});
    }

    // Subscribe to real-time updates from Firestore
    return ref.read(watchFavoriteIdsUseCaseProvider).call(user.uid);
  }

  /// Toggles the favorite status of a listing.
  /// Implements optimistic updates for a snappy UI.
  Future<Either<Failure, bool>> toggleFavorite(ListingEntity listing) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      debugPrint('FavoritesNotifier: Toggle failed - User is null');
      return Left(ServerFailure(message: 'User must be logged in'));
    }

    final listingId = listing.id;
    // We can't easily do optimistic updates with StreamNotifier + Firestore 
    // because the stream will emit the new state shortly after.
    // However, for immediate UI feedback, the local state change is usually enough for simple toggles
    // if we weren't depending solely on the stream.
    // Given the speed of Firestore listeners, we'll rely on the stream for the "source of truth"
    // but the UI (heart icon) can toggle visually while awaiting the future if needed.
    
    debugPrint('FavoritesNotifier: Toggling ${listing.title} ($listingId)');

    final result = await ref.read(toggleFavoriteUseCaseProvider)(
      userId: user.uid,
      listing: listing,
    );

    return result.fold(
      (failure) {
        debugPrint('FavoritesNotifier: Toggle failure: ${failure.message}');
        return Left(failure);
      },
      (isNowFavorite) {
        debugPrint('FavoritesNotifier: Successfully toggled to $isNowFavorite');
        return Right(isNowFavorite);
      },
    );
  }

  /// Helper to check if a specific listing is favorited.
  bool isFavorite(String listingId) {
    return state.value?.contains(listingId) ?? false;
  }
}

/// Provider for the FavoritesNotifier.
final favoritesNotifierProvider = StreamNotifierProvider<FavoritesNotifier, Set<String>>(() {
  return FavoritesNotifier();
});

/// Provider to stream the list of favorite listings (summaries) for the Favorites Page.
final favoriteListingsProvider = StreamProvider<List<ListingEntity>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  return ref.read(watchFavoriteListingsUseCaseProvider).call(user.uid);
});
