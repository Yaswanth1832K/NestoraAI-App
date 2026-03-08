import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/coupon_entity.dart';

abstract class CouponRepository {
  Future<Either<Failure, void>> createCoupon(CouponEntity coupon);
  Future<Either<Failure, List<CouponEntity>>> getUserCoupons(String userId);
  Future<Either<Failure, Map<String, dynamic>>> validateCoupon(String couponId, String userId);
  Future<Either<Failure, void>> useCoupon(String couponId, String userId);
}
