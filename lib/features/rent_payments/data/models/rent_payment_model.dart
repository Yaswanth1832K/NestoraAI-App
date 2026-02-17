import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';

class RentPaymentModel extends RentPaymentEntity {
  const RentPaymentModel({
    required super.id,
    required super.tenantId,
    required super.propertyId,
    required super.propertyTitle,
    required super.amount,
    required super.date,
    required super.status,
    required super.paymentMethod,
  });

  factory RentPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentPaymentModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      propertyTitle: data['propertyTitle'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'card',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
      'paymentMethod': paymentMethod,
    };
  }
}
