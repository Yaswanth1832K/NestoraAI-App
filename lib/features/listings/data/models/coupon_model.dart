import 'package:house_rental/features/listings/domain/entities/coupon_entity.dart';

class CouponModel extends CouponEntity {
  const CouponModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    super.discountPercent,
    super.discountAmount,
    super.serviceType,
    required super.expiryDate,
    required super.isUsed,
    required super.createdAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      serviceType: json['service_type'] as String?,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      isUsed: json['is_used'] == 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'service_type': serviceType,
      'expiry_date': expiryDate.toIso8601String(),
      'is_used': isUsed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
