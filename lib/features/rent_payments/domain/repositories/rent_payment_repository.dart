import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';

abstract class RentPaymentRepository {
  Future<void> makePayment(RentPaymentEntity payment);
  Stream<List<RentPaymentEntity>> getRentPayments(String tenantId);
}
