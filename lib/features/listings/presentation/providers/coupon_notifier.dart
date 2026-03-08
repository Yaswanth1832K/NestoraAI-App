import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/repositories/coupon_repository.dart';

class CouponNotifier extends StateNotifier<AsyncValue<List<CouponEntity>>> {
  final CouponRepository _repository;

  CouponNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> fetchUserCoupons(String userId) async {
    // state = const AsyncValue.loading();
    final result = await _repository.getUserCoupons(userId);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (coupons) => AsyncValue.data(coupons),
    );
  }

  Future<void> createCoupon(CouponEntity coupon) async {
    final result = await _repository.createCoupon(coupon);
    result.fold(
      (failure) => null, 
      (_) {
        if (state.hasValue) {
          final current = state.value!;
          state = AsyncValue.data([...current, coupon]);
        }
      },
    );
  }

  Future<bool> useCoupon(String couponId, String userId) async {
    final result = await _repository.useCoupon(couponId, userId);
    return result.fold(
      (failure) => false,
      (_) {
        if (state.hasValue) {
          final current = state.value!;
          state = AsyncValue.data(current.map((c) => c.id == couponId ? CouponEntity(
            id: c.id,
            userId: c.userId,
            type: c.type,
            title: c.title,
            discountPercent: c.discountPercent,
            discountAmount: c.discountAmount,
            serviceType: c.serviceType,
            expiryDate: c.expiryDate,
            isUsed: true,
            createdAt: c.createdAt,
          ) : c).toList());
        }
        return true;
      },
    );
  }
}
