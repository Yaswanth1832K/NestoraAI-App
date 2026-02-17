import 'package:equatable/equatable.dart';

class RentPaymentEntity extends Equatable {
  final String id;
  final String tenantId;
  final String propertyId;
  final String propertyTitle;
  final double amount;
  final DateTime date;
  final String status; // 'success', 'pending', 'failed'
  final String paymentMethod; // 'card', 'upi', 'cash'

  const RentPaymentEntity({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.propertyTitle,
    required this.amount,
    required this.date,
    required this.status,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [id, tenantId, propertyId, propertyTitle, amount, date, status, paymentMethod];
}
