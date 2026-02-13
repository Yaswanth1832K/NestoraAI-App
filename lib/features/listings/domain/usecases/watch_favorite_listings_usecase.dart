import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/favorites_repository.dart';

class WatchFavoriteListingsUseCase {
  final FavoritesRepository _repository;

  WatchFavoriteListingsUseCase(this._repository);

  Stream<List<ListingEntity>> call(String userId) {
    return _repository.watchFavoriteListings(userId);
  }
}
