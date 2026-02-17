import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/rent_payments/data/repositories/rent_payment_repository_impl.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';
import 'package:house_rental/features/rent_payments/domain/repositories/rent_payment_repository.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/presentation/providers/visit_request_providers.dart';

final rentPaymentRepositoryProvider = Provider<RentPaymentRepository>((ref) {
  return RentPaymentRepositoryImpl(ref.read(firestoreProvider));
});

final rentPaymentsProvider = StreamProvider.family<List<RentPaymentEntity>, String>((ref, tenantId) {
  return ref.watch(rentPaymentRepositoryProvider).getRentPayments(tenantId);
});

final makePaymentUseCaseProvider = Provider((ref) {
  return (RentPaymentEntity payment) {
    return ref.read(rentPaymentRepositoryProvider).makePayment(payment);
  };
});

final activeRentalProvider = StreamProvider.family<VisitRequestEntity?, String>((ref, tenantId) {
  return ref.watch(visitRequestRemoteDataSourceProvider)
      .getTenantVisitRequests(tenantId)
      .map((requests) {
        // Find the first 'approved' request, assuming it's the active rental
        try {
          return requests.firstWhere((r) => r.status == 'approved');
        } catch (_) {
          return null;
        }
      });
});
