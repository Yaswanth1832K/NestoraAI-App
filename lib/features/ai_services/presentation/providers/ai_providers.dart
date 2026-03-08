import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/ai_services/data/datasources/ai_remote_datasource.dart';
import 'package:house_rental/features/ai_services/domain/usecases/natural_language_search_usecase.dart';
import 'package:house_rental/features/ai_services/domain/usecases/predict_price_usecase.dart';
import 'package:house_rental/features/ai_services/domain/usecases/get_recommendations_usecase.dart';
import 'package:house_rental/core/network/api_client.dart';
import 'package:house_rental/features/ai_services/data/property_chat_service.dart';

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(httpClientProvider));
});

// AI Data Source Provider
final aiRemoteDataSourceProvider = Provider<AIRemoteDataSource>((ref) {
  return AIRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

// Use Case Providers
final naturalLanguageSearchUseCaseProvider =
    Provider<NaturalLanguageSearchUseCase>((ref) {
  return NaturalLanguageSearchUseCase(
    ref.read(aiRemoteDataSourceProvider),
    ref.read(listingRepositoryProvider),
  );
});

final predictPriceUseCaseProvider = Provider<PredictPriceUseCase>((ref) {
  return PredictPriceUseCase(ref.read(aiRemoteDataSourceProvider));
});

final listingPredictedPriceProvider = FutureProvider.family<double, ListingEntity>((ref, listing) async {
  final useCase = ref.read(predictPriceUseCaseProvider);
  final result = await useCase(
    city: listing.city,
    sqft: listing.sqft,
    bedrooms: listing.bedrooms,
    bathrooms: listing.bathrooms,
  );
  
  return result.fold(
    (failure) => throw failure,
    (price) => price,
  );
});

final getRecommendationsUseCaseProvider = Provider<GetRecommendationsUseCase>((ref) {
  return GetRecommendationsUseCase(ref.read(aiRemoteDataSourceProvider));
});

// Service Providers
final propertyChatServiceProvider = Provider<PropertyChatService>((ref) {
  return PropertyChatService(ref.watch(apiClientProvider));
});
