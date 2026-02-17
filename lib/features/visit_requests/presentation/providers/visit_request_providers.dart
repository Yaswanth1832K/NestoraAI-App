import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/features/visit_requests/data/datasources/visit_request_remote_datasource.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/domain/repositories/visit_request_repository.dart';
import 'package:house_rental/features/notifications/domain/services/notification_service.dart';
import 'package:house_rental/features/visit_requests/data/repositories/visit_request_repository_impl.dart';

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
  return (VisitRequestEntity request) async {
    // 1. Create Request
    await ref.read(visitRequestRepositoryProvider).createVisitRequest(request);
    
    // 2. Notify Owner & Tenant via NotificationService
    final notificationService = ref.read(notificationServiceProvider);
    
    await notificationService.notifyVisitRequestCreated(
      ownerId: request.ownerId,
      propertyTitle: request.listingTitle,
      tenantName: request.tenantName,
    );

    await notificationService.sendNotification(
      userId: request.tenantId,
      title: "Request Sent",
      body: "Your visit request for ${request.listingTitle} has been sent.",
      type: 'booking',
      data: {'requestId': request.id, 'listingId': request.listingId},
    );
  };
});

final updateVisitStatusUseCaseProvider = Provider((ref) {
  return (VisitRequestEntity request, String status) async {
    // 1. Update Status
    await ref.read(visitRequestRepositoryProvider).updateVisitRequestStatus(request.id, status);
    
    // 2. Notify Tenant via NotificationService
    await ref.read(notificationServiceProvider).notifyVisitRequestStatusChanged(
      tenantId: request.tenantId,
      propertyTitle: request.listingTitle,
      status: status,
    );
  };
});

final rescheduleVisitUseCaseProvider = Provider((ref) {
  return (VisitRequestEntity request, DateTime newDate, String newTime) async {
    // 1. Reschedule in Repository
    await ref.read(visitRequestRepositoryProvider).rescheduleVisitRequest(request.id, newDate, newTime);
    
    // 2. Notify via NotificationService
    await ref.read(notificationServiceProvider).sendNotification(
      userId: request.tenantId,
      title: "Visit Rescheduled",
      body: "Your visit for ${request.listingTitle} has been rescheduled to ${DateFormat('MMM dd').format(newDate)} at $newTime.",
      type: 'alert',
      data: {'requestId': request.id, 'listingId': request.listingId},
    );
  };
});

final cancelVisitUseCaseProvider = Provider((ref) {
  return (VisitRequestEntity request, String userId) async {
    // 1. Update Status to cancelled
    await ref.read(visitRequestRepositoryProvider).updateVisitRequestStatus(request.id, 'cancelled');
    
    // 2. Notify other party via NotificationService
    final otherId = userId == request.ownerId ? request.tenantId : request.ownerId;
    final role = userId == request.ownerId ? "Owner" : "Tenant";
    
    await ref.read(notificationServiceProvider).sendNotification(
      userId: otherId,
      title: "Visit Cancelled",
      body: "The visit for ${request.listingTitle} has been cancelled by the $role.",
      type: 'alert',
      data: {'requestId': request.id, 'listingId': request.listingId},
    );
  };
});
