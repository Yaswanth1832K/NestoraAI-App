import 'package:house_rental/features/listings/domain/repositories/favorites_repository.dart';

class WatchFavoriteIdsUseCase {
  final FavoritesRepository _repository;

  WatchFavoriteIdsUseCase(this._repository);

  Stream<Set<String>> call(String userId) {
    return _repository.watchFavoriteIds(userId);
  }
}
