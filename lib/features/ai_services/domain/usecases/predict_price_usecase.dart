import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/ai_services/data/datasources/ai_remote_datasource.dart';

class PredictPriceUseCase {
  final AIRemoteDataSource _aiRemoteDataSource;

  const PredictPriceUseCase(this._aiRemoteDataSource);

  Future<Either<Failure, double>> call({
    required String city,
    required double sqft,
    required int bedrooms,
    required int bathrooms,
  }) async {
    try {
      final predictedPrice = await _aiRemoteDataSource.predictPrice(
        city: city,
        sqft: sqft,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
      );
      return Right(predictedPrice);
    } catch (e) {
      return Left(ServerFailure(message: 'Price Prediction Error: $e'));
    }
  }
}
