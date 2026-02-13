import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/ai_services/data/datasources/ai_remote_datasource.dart';
import 'package:house_rental/features/ai_services/domain/usecases/natural_language_search_usecase.dart';
import 'package:house_rental/features/ai_services/domain/usecases/predict_price_usecase.dart';

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// AI Data Source Provider
final aiRemoteDataSourceProvider = Provider<AIRemoteDataSource>((ref) {
  return AIRemoteDataSourceImpl(ref.read(httpClientProvider));
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
