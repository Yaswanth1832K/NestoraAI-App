import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/visit_requests/data/datasources/visit_request_remote_datasource.dart';
import 'package:house_rental/features/visit_requests/data/repositories/visit_request_repository_impl.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/domain/repositories/visit_request_repository.dart';

final visitRequestRemoteDataSourceProvider = Provider<VisitRequestRemoteDataSource>((ref) {
  return VisitRequestRemoteDataSourceImpl(ref.read(firestoreProvider));
});

final visitRequestRepositoryProvider = Provider<VisitRequestRepository>((ref) {
  return VisitRequestRepositoryImpl(ref.watch(visitRequestRemoteDataSourceProvider));
});

final ownerVisitRequestsProvider = StreamProvider.family<List<VisitRequestEntity>, String>((ref, ownerId) {
  return ref.watch(visitRequestRepositoryProvider).getOwnerVisitRequests(ownerId);
});

final tenantVisitRequestsProvider = StreamProvider.family<List<VisitRequestEntity>, String>((ref, tenantId) {
  // Let's assume the repository has this method, if not I will add it.
  return ref.watch(visitRequestRepositoryProvider).getTenantVisitRequests(tenantId);
});

final createVisitRequestUseCaseProvider = Provider((ref) {
  return (VisitRequestEntity request) => ref.watch(visitRequestRepositoryProvider).createVisitRequest(request);
});

final updateVisitStatusUseCaseProvider = Provider((ref) {
  return (String requestId, String status) => ref.watch(visitRequestRepositoryProvider).updateVisitRequestStatus(requestId, status);
});
