import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// Mock Provider
final bookingRepositoryProvider = Provider((ref) => BookingRepository());

class BookingRepository {
  // Mock endpoint: POST /bookings
  Future<bool> createBooking({
    required String propertyId,
    required String tenantId,
    required double rentAmount,
    required DateTime bookingDate,
    required String paymentStatus,
  }) async {
    try {
      debugPrint('POST /bookings - Initializing Booking');
      debugPrint('Data: {propertyId: $propertyId, tenantId: $tenantId, amount: $rentAmount, status: $paymentStatus}');
      
      // Simulate network wait
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('POST /bookings - Booking created successfully. Property owner notified.');
      return true;
    } catch (e) {
      debugPrint('POST /bookings - Error: $e');
      return false;
    }
  }

  // Mock endpoint: GET /user/coupons
  Future<List<String>> fetchUserCoupons(String userId) async {
    debugPrint('GET /user/coupons - Fetching for user: $userId');
    await Future.delayed(const Duration(seconds: 1));
    return [
      '15% OFF NEXT BOOKING',
      'Free Home Cleaning',
      '₹500 Service Coupon',
    ];
  }
}
