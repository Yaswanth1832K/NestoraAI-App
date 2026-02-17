import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/visit_requests/data/models/visit_request_model.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

abstract class VisitRequestRemoteDataSource {
  Future<void> createVisitRequest(VisitRequestEntity request);
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId);
  Stream<List<VisitRequestEntity>> getTenantVisitRequests(String tenantId);
  Future<void> updateVisitRequestStatus(String requestId, String status);
  Future<void> rescheduleVisitRequest(String requestId, DateTime date, String time);
}

class VisitRequestRemoteDataSourceImpl implements VisitRequestRemoteDataSource {
  final FirebaseFirestore _firestore;

  VisitRequestRemoteDataSourceImpl(this._firestore);

  @override
  Future<void> createVisitRequest(VisitRequestEntity request) async {
    final model = VisitRequestModel(
      id: request.id,
      listingId: request.listingId,
      listingTitle: request.listingTitle,
      listingImage: request.listingImage,
      ownerId: request.ownerId,
      tenantId: request.tenantId,
      tenantName: request.tenantName,
      date: request.date,
      time: request.time,
      message: request.message,
      status: request.status,
      createdAt: request.createdAt,
    );
    await _firestore.collection('bookings').doc(request.id).set(model.toFirestore());
  }

  @override
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('participants', arrayContains: ownerId)
        .snapshots()
        .handleError((error) {
      debugPrint("================================================================");
      debugPrint("FIRESTORE PERMISSION/INDEX ERROR (OWNER VISITS): $error");
      debugPrint("================================================================");
    }).map((snapshot) {
      final docs = snapshot.docs.map((doc) => VisitRequestModel.fromFirestore(doc)).toList();
      // Sort in memory to avoid index requirements
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  @override
  Stream<List<VisitRequestEntity>> getTenantVisitRequests(String tenantId) {
    return _firestore
        .collection('bookings')
        .where('participants', arrayContains: tenantId)
        .snapshots()
        .handleError((error) {
      debugPrint("================================================================");
      debugPrint("FIRESTORE PERMISSION/INDEX ERROR (TENANT VISITS): $error");
      debugPrint("================================================================");
    }).map((snapshot) {
      final docs = snapshot.docs.map((doc) => VisitRequestModel.fromFirestore(doc)).toList();
      // Sort in memory to avoid index requirements
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  @override
  Future<void> updateVisitRequestStatus(String requestId, String status) async {
    await _firestore.collection('bookings').doc(requestId).update({'status': status});
  }

  @override
  Future<void> rescheduleVisitRequest(String requestId, DateTime date, String time) async {
    await _firestore.collection('bookings').doc(requestId).update({
      'date': Timestamp.fromDate(date),
      'time': time,
      'status': 'pending', // Reset to pending when rescheduled
    });
  }
}
