import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/core/constants/firestore_constants.dart';
import 'package:house_rental/features/visit_requests/data/models/visit_request_model.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/core/errors/exceptions.dart';
import 'package:house_rental/core/network/api_client.dart';

abstract class VisitRequestRemoteDataSource {
  Future<void> createVisitRequest(VisitRequestEntity request);
  Stream<List<VisitRequestEntity>> getOwnerVisitRequests(String ownerId);
  Stream<List<VisitRequestEntity>> getTenantVisitRequests(String tenantId);
  Stream<List<VisitRequestEntity>> getBookingsByChatId(String chatId, String userId);
  Future<bool> hasApprovedBookingForDate(String listingId, DateTime date);
  Future<void> createBookingFromChat({
    required String listingId,
    required String listingTitle,
    required String listingImage,
    required String tenantName,
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
  final ApiClient _apiClient;

  VisitRequestRemoteDataSourceImpl(this._firestore, this._apiClient);

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
    
    // Sync with FastAPI
    try {
      await _apiClient.post('/visits', body: {
        'id': request.id,
        'property_id': request.listingId,
        'tenant_id': request.tenantId,
        'date': request.date,
        'time': request.time,
        'status': request.status,
      });
    } catch (e) {
      debugPrint('Failed to sync visit to FastAPI: $e');
    }
  }

  @override
  Stream<List<VisitRequestEntity>> getBookingsByChatId(String chatId, String userId) {
    return _firestore
        .collection(FirestoreConstants.bookings)
        .where('chatId', isEqualTo: chatId)
        .where('participants', arrayContains: userId)
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
    required String listingTitle,
    required String listingImage,
    required String tenantName,
    required String ownerId,
    required String renterId,
    required String chatId,
    required DateTime visitDate,
  }) async {
    final ts = Timestamp.fromDate(DateTime(visitDate.year, visitDate.month, visitDate.day));
    final docRef = await _firestore.collection(FirestoreConstants.bookings).add({
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'tenantName': tenantName,
      'ownerId': ownerId,
      'renterId': renterId,
      'chatId': chatId,
      'participants': [renterId, ownerId],
      'status': 'pending',
      'visitDate': ts,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Sync with FastAPI
    try {
      await _apiClient.post('/visits', body: {
        'id': docRef.id,
        'property_id': listingId,
        'tenant_id': renterId,
        'date': visitDate.toIso8601String(),
        'time': 'TBD', // Chat-based bookings might not have a set time yet
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Failed to sync booking from chat to FastAPI: $e');
    }
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
    try {
      // 1. Always update Firestore first
      await _firestore
          .collection(FirestoreConstants.bookings)
          .doc(requestId)
          .update({'status': status});

      // 2. Sync with FastAPI - but don't let it crash the whole operation if it fails
      try {
        await _apiClient.patch('/visits/$requestId', body: {'status': status});
      } catch (apiError) {
        // Log the error but don't rethrow, so Firestore update is considered successful
        debugPrint('FastAPI Sync Error: $apiError');
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> rescheduleVisitRequest(String requestId, DateTime date, String time) async {
    await _firestore.collection(FirestoreConstants.bookings).doc(requestId).update({
      'date': Timestamp.fromDate(date),
      'visitDate': Timestamp.fromDate(date), // Sync both fields for robustness
      'time': time,
      'status': 'pending', // Reset to pending when rescheduled
    });

    // Sync with FastAPI
    try {
      await _apiClient.patch('/visits/$requestId', body: {
        'visit_date': date.toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('FastAPI Reschedule Sync Error: $e');
    }
  }
}
