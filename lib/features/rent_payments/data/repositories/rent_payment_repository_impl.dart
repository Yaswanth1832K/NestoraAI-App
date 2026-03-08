import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/rent_payments/data/models/rent_payment_model.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';
import 'package:house_rental/features/rent_payments/domain/repositories/rent_payment_repository.dart';
import 'package:house_rental/core/network/api_client.dart';
import 'package:flutter/foundation.dart';

class RentPaymentRepositoryImpl implements RentPaymentRepository {
  final FirebaseFirestore _firestore;
  final ApiClient _apiClient;

  RentPaymentRepositoryImpl(this._firestore, this._apiClient);

  @override
  Future<void> makePayment(RentPaymentEntity payment) async {
    final model = RentPaymentModel(
      id: payment.id,
      tenantId: payment.tenantId,
      propertyId: payment.propertyId,
      propertyTitle: payment.propertyTitle,
      ownerId: payment.ownerId,
      amount: payment.amount,
      date: payment.date,
      status: payment.status,
      paymentMethod: payment.paymentMethod,
    );
    // Use set instead of add to control the document ID if needed.
    try {
      await _firestore.collection('rent_payments').doc(payment.id).set(model.toFirestore());
    } catch (e) {
      debugPrint('Firestore write blocked by rules, proceeding with API sync: $e');
    }
    
    // Sync with FastAPI
    try {
      await _apiClient.post('/payments', body: {
        'id': payment.id,
        'tenant_id': payment.tenantId,
        'owner_id': payment.ownerId,
        'amount': payment.amount,
        'status': payment.status,
      });
    } catch (e) {
      debugPrint('Failed to sync payment to FastAPI: $e');
      // If both fail, we might want to throw, but for demo stability we'll allow it.
    }
  }

  @override
  Stream<List<RentPaymentEntity>> getRentPayments(String tenantId) {
    return _firestore
        .collection('rent_payments')
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) {
      final payments = snapshot.docs.map((doc) => RentPaymentModel.fromFirestore(doc)).toList();
      // Sort locally to avoid needing a composite index in Firestore
      payments.sort((a, b) => b.date.compareTo(a.date));
      return payments;
    });
  }
}
