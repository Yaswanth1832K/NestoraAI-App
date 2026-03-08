import 'package:house_rental/core/constants/api_constants.dart';
import 'package:house_rental/core/network/api_client.dart';
import 'package:house_rental/features/listings/data/models/coupon_model.dart';

abstract interface class CouponRemoteDataSource {
  Future<void> createCoupon(CouponModel coupon);
  Future<List<CouponModel>> getUserCoupons(String userId);
  Future<Map<String, dynamic>> validateCoupon(String couponId, String userId);
  Future<void> useCoupon(String couponId, String userId);
}

class CouponRemoteDataSourceImpl implements CouponRemoteDataSource {
  final ApiClient _apiClient;

  CouponRemoteDataSourceImpl(this._apiClient);

  @override
  Future<void> createCoupon(CouponModel coupon) async {
    await _apiClient.post('${ApiConstants.coupons}/create', body: coupon.toJson());
  }

  @override
  Future<List<CouponModel>> getUserCoupons(String userId) async {
    final response = await _apiClient.get('${ApiConstants.coupons}/$userId');
    if (response is List) {
      return response.map((json) => CouponModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> validateCoupon(String couponId, String userId) async {
    final response = await _apiClient.post(ApiConstants.validateCoupon, body: {
      'coupon_id': couponId,
      'user_id': userId,
    });
    return response as Map<String, dynamic>;
  }

  @override
  Future<void> useCoupon(String couponId, String userId) async {
    await _apiClient.post(ApiConstants.useCoupon, body: {
      'coupon_id': couponId,
      'user_id': userId,
    });
  }
}
