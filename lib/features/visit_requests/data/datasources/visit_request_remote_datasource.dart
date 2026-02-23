import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/core/constants/firestore_constants.dart';
import 'package:house_rental/features/visit_requests/data/models/visit_request_model.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:flutter/foundation.dart';

abstract class VisitRequestRemoteDataSource {
  Future<void> createVisitRequest(VisitRequestEntity request);
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId);
  Stream<List<VisitRequestEntity>> getTenantVisitRequests(String tenantId);
  Stream<List<VisitRequestEntity>> getBookingsByChatId(String chatId);
  Future<bool> hasApprovedBookingForDate(String listingId, DateTime date);
  Future<void> createBookingFromChat({
    required String listingId,
    required String ownerId,
    required String renterId,
    required String chatId,
    required DateTime visitDate,
  });
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
    await _firestore.collection(FirestoreConstants.bookings).doc(request.id).set(model.toFirestore());
  }

  @override
  Stream<List<VisitRequestEntity>> getBookingsByChatId(String chatId) {
    return _firestore
        .collection(FirestoreConstants.bookings)
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitRequestModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<bool> hasApprovedBookingForDate(String listingId, DateTime date) async {
    final ts = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    final snapshot = await _firestore
        .collection(FirestoreConstants.bookings)
        .where('listingId', isEqualTo: listingId)
        .where('visitDate', isEqualTo: ts)
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> createBookingFromChat({
    required String listingId,
    required String ownerId,
    required String renterId,
    required String chatId,
    required DateTime visitDate,
  }) async {
    final ts = Timestamp.fromDate(DateTime(visitDate.year, visitDate.month, visitDate.day));
    await _firestore.collection(FirestoreConstants.bookings).add({
      'listingId': listingId,
      'ownerId': ownerId,
      'renterId': renterId,
      'chatId': chatId,
      'participants': [renterId, ownerId],
      'status': 'pending',
      'visitDate': ts,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId) {
    return _firestore
        .collection(FirestoreConstants.bookings)
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
        .collection(FirestoreConstants.bookings)
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
    await _firestore.collection(FirestoreConstants.bookings).doc(requestId).update({'status': status});
  }

  @override
  Future<void> rescheduleVisitRequest(String requestId, DateTime date, String time) async {
    await _firestore.collection(FirestoreConstants.bookings).doc(requestId).update({
      'date': Timestamp.fromDate(date),
      'time': time,
      'status': 'pending', // Reset to pending when rescheduled
    });
  }
}
