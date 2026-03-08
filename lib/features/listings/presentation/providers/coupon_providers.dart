import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/network/api_client.dart';
import 'package:house_rental/core/providers/network_provider.dart';
import 'package:house_rental/features/listings/data/datasources/coupon_remote_datasource.dart';
import 'package:house_rental/features/listings/data/repositories/coupon_repository_impl.dart';
import 'package:house_rental/features/listings/domain/entities/coupon_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/coupon_repository.dart';
import 'coupon_notifier.dart';

final couponRemoteDataSourceProvider = Provider<CouponRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CouponRemoteDataSourceImpl(apiClient);
});

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  final remoteDataSource = ref.watch(couponRemoteDataSourceProvider);
  return CouponRepositoryImpl(remoteDataSource);
});

final couponNotifierProvider = StateNotifierProvider<CouponNotifier, AsyncValue<List<CouponEntity>>>((ref) {
  final repository = ref.watch(couponRepositoryProvider);
  return CouponNotifier(repository);
});
