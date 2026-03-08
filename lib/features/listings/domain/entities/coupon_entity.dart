import 'package:equatable/equatable.dart';

class CouponEntity extends Equatable {
  final String id;
  final String userId;
  final String type; // percent / amount / service
  final String title;
  final double? discountPercent;
  final double? discountAmount;
  final String? serviceType;
  final DateTime expiryDate;
  final bool isUsed;
  final DateTime createdAt;

  const CouponEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.discountPercent,
    this.discountAmount,
    this.serviceType,
    required this.expiryDate,
    required this.isUsed,
    required this.createdAt,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        discountPercent,
        discountAmount,
        serviceType,
        expiryDate,
        isUsed,
        createdAt,
      ];
}
