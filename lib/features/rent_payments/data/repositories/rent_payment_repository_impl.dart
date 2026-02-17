import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/rent_payments/data/models/rent_payment_model.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';
import 'package:house_rental/features/rent_payments/domain/repositories/rent_payment_repository.dart';

class RentPaymentRepositoryImpl implements RentPaymentRepository {
  final FirebaseFirestore _firestore;

  RentPaymentRepositoryImpl(this._firestore);

  @override
  Future<void> makePayment(RentPaymentEntity payment) async {
    final model = RentPaymentModel(
      id: payment.id,
      tenantId: payment.tenantId,
      propertyId: payment.propertyId,
      propertyTitle: payment.propertyTitle,
      amount: payment.amount,
      date: payment.date,
      status: payment.status,
      paymentMethod: payment.paymentMethod,
    );
    // Use set instead of add to control the document ID if needed, 
    // or let Firestore generate it if ID is empty. 
    // Here we use payment.id which should be a UUID.
    await _firestore.collection('rent_payments').doc(payment.id).set(model.toFirestore());
  }

  @override
  Stream<List<RentPaymentEntity>> getRentPayments(String tenantId) {
    return _firestore
        .collection('rent_payments')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RentPaymentModel.fromFirestore(doc)).toList();
    });
  }
}
