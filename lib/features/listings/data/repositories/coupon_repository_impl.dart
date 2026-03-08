import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/data/datasources/coupon_remote_datasource.dart';
import 'package:house_rental/features/listings/data/models/coupon_model.dart';
import 'package:house_rental/features/listings/domain/entities/coupon_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/coupon_repository.dart';

class CouponRepositoryImpl implements CouponRepository {
  final CouponRemoteDataSource _remoteDataSource;

  CouponRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, void>> createCoupon(CouponEntity coupon) async {
    try {
      final model = CouponModel(
        id: coupon.id,
        userId: coupon.userId,
        type: coupon.type,
        title: coupon.title,
        discountPercent: coupon.discountPercent,
        discountAmount: coupon.discountAmount,
        serviceType: coupon.serviceType,
        expiryDate: coupon.expiryDate,
        isUsed: coupon.isUsed,
        createdAt: coupon.createdAt,
      );
      await _remoteDataSource.createCoupon(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CouponEntity>>> getUserCoupons(String userId) async {
    try {
      final coupons = await _remoteDataSource.getUserCoupons(userId);
      return Right(coupons);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> validateCoupon(String couponId, String userId) async {
    try {
      final result = await _remoteDataSource.validateCoupon(couponId, userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> useCoupon(String couponId, String userId) async {
    try {
      await _remoteDataSource.useCoupon(couponId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
