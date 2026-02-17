import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';

abstract class VisitRequestRepository {
  Future<Either<Failure, void>> createVisitRequest(VisitRequestEntity request);
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId);
  Stream<List<VisitRequestEntity>> getTenantVisitRequests(String tenantId);
  Future<Either<Failure, void>> updateVisitRequestStatus(String requestId, String status);
  Future<Either<Failure, void>> rescheduleVisitRequest(String requestId, DateTime date, String time);
}
