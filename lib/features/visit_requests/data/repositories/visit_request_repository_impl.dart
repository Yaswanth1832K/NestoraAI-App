import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/visit_requests/data/datasources/visit_request_remote_datasource.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/domain/repositories/visit_request_repository.dart';

class VisitRequestRepositoryImpl implements VisitRequestRepository {
  final VisitRequestRemoteDataSource _remoteDataSource;

  VisitRequestRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, void>> createVisitRequest(VisitRequestEntity request) async {
    try {
      await _remoteDataSource.createVisitRequest(request);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId) {
    return _remoteDataSource.getOwnerVisitRequests(ownerId);
  }

  @override
  Stream<List<VisitRequestEntity>> getTenantVisitRequests(String tenantId) {
    return _remoteDataSource.getTenantVisitRequests(tenantId);
  }

  @override
  Future<Either<Failure, void>> updateVisitRequestStatus(String requestId, String status) async {
    try {
      await _remoteDataSource.updateVisitRequestStatus(requestId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rescheduleVisitRequest(String requestId, DateTime date, String time) async {
    try {
      await _remoteDataSource.rescheduleVisitRequest(requestId, date, time);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
