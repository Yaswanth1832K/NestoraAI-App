import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

// Class to store user search preferences in memory
class UserSearchPreferences {
  final int? bedrooms;
  final double? maxPrice;

  const UserSearchPreferences({this.bedrooms, this.maxPrice});

  bool get isEmpty => bedrooms == null && maxPrice == null;
}

// Notifier for user preferences
class UserPreferencesNotifier extends StateNotifier<UserSearchPreferences> {
  UserPreferencesNotifier() : super(const UserSearchPreferences());

  void updatePreferences({int? bedrooms, double? maxPrice}) {
    state = UserSearchPreferences(
      bedrooms: bedrooms ?? state.bedrooms,
      maxPrice: maxPrice ?? state.maxPrice,
    );
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserSearchPreferences>((ref) {
  return UserPreferencesNotifier();
});

// State for the list of found listings
class SearchNotifier extends StateNotifier<AsyncValue<List<ListingEntity>>> {
  final Ref ref;

  SearchNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.isEmpty) return;

    state = const AsyncValue.loading();

    final searchUseCase = ref.read(naturalLanguageSearchUseCaseProvider);

    final result = await searchUseCase(query: query);

    result.fold(
      (failure) => state = AsyncValue.error(failure.message ?? 'Search failed', StackTrace.current),
      (searchResult) {
        state = AsyncValue.data(searchResult.listings);
        
        // Capture preferences from the successful search
        ref.read(userPreferencesProvider.notifier).updatePreferences(
          bedrooms: searchResult.filter.bedrooms,
          maxPrice: searchResult.filter.maxPrice,
        );
      },
    );
  }

  void clearResults() {
    state = const AsyncValue.data([]);
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<ListingEntity>>>((ref) {
  return SearchNotifier(ref);
});

// Recommendations Provider
final recommendationsProvider = FutureProvider<List<ListingEntity>>((ref) async {
  final preferences = ref.watch(userPreferencesProvider);
  if (preferences.isEmpty) return [];

  final repository = ref.read(listingRepositoryProvider);
  
  final result = await repository.getListings(
    filter: ListingFilter(
      bedrooms: preferences.bedrooms,
      maxPrice: preferences.maxPrice,
    ),
  );

  return result.fold(
    (failure) => [],
    (listings) => listings,
  );
});

