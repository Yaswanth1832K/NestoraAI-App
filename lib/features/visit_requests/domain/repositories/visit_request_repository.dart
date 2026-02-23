import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';

abstract class VisitRequestRepository {
  Future<Either<Failure, void>> createVisitRequest(VisitRequestEntity request);
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId);
  Stream<List<VisitRequestEntity>> getTenantVisitRequests(String tenantId);
  Stream<List<VisitRequestEntity>> getBookingsByChatId(String chatId);
  Future<bool> hasApprovedBookingForDate(String listingId, DateTime date);
  Future<Either<Failure, void>> createBookingFromChat({
    required String listingId,
    required String ownerId,
    required String renterId,
    required String chatId,
    required DateTime visitDate,
  });
  Future<Either<Failure, void>> updateVisitRequestStatus(String requestId, String status);
  Future<Either<Failure, void>> rescheduleVisitRequest(String requestId, DateTime date, String time);
}
