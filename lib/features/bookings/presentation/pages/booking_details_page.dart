import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/domain/entities/coupon_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/coupon_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingDetailsPage extends ConsumerStatefulWidget {
  final ListingEntity listing;

  const BookingDetailsPage({super.key, required this.listing});

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> {
  DateTime? _selectedMoveInDate;
  int _leaseDurationMonths = 12;
  int _numberOfTenants = 1;
  bool _includeCleaning = false;
  bool _includeMaintenance = false;
  CouponEntity? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(couponNotifierProvider.notifier).fetchUserCoupons(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final couponState = ref.watch(couponNotifierProvider);

    // Calculate Price
    final monthlyRent = widget.listing.price;
    final deposit = monthlyRent * 3; // 3 months deposit
    final cleaningFee = _includeCleaning ? 1000.0 : 0.0;
    final maintenanceFee = _includeMaintenance ? 1500.0 : 0.0;
    
    double subtotal = monthlyRent + deposit + cleaningFee + maintenanceFee;
    double discount = 0.0;

    if (_appliedCoupon != null) {
      if (_appliedCoupon!.type == 'percent') {
        discount = (monthlyRent * (_appliedCoupon!.discountPercent ?? 0)) / 100;
      } else if (_appliedCoupon!.type == 'amount') {
        discount = _appliedCoupon!.discountAmount ?? 0;
      } else if (_appliedCoupon!.type == 'service') {
        if (_appliedCoupon!.serviceType == 'cleaning' && _includeCleaning) {
          discount = cleaningFee;
        }
      }
    }

    final totalPayable = (subtotal - discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark2 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.listing.imageUrls.isNotEmpty ? widget.listing.imageUrls.first : 'https://via.placeholder.com/150',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.listing.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(widget.listing.city, style: TextStyle(color: subTextColor)),
                        const SizedBox(height: 8),
                        Text('₹${NumberFormat('#,##,###').format(widget.listing.price)} / month', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Booking Options
            Text('Booking Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            
            // Move-in Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.calendar_today, color: AppColors.primary),
              ),
              title: Text('Move-in Date', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
              subtitle: Text(_selectedMoveInDate == null ? 'Select Date' : DateFormat('dd MMM, yyyy').format(_selectedMoveInDate!), style: TextStyle(color: subTextColor)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                final date = await showDatePicker(
                  context: context, 
                  initialDate: DateTime.now().add(const Duration(days: 1)), 
                  firstDate: DateTime.now(), 
                  lastDate: DateTime.now().add(const Duration(days: 90))
                );
                if (date != null) setState(() => _selectedMoveInDate = date);
              },
            ),
            const Divider(),

            // Lease Duration
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.schedule, color: AppColors.primary),
              ),
              title: Text('Lease Duration', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
              trailing: DropdownButton<int>(
                value: _leaseDurationMonths,
                underline: const SizedBox(),
                items: [6, 11, 12, 24].map((e) => DropdownMenuItem(value: e, child: Text('$e Months', style: TextStyle(color: textColor)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _leaseDurationMonths = val);
                },
              ),
            ),
            const Divider(),

            // Number of Tenants
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.people_outline, color: AppColors.primary),
              ),
              title: Text('Number of Tenants', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () { if (_numberOfTenants > 1) setState(() => _numberOfTenants--); }, icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_numberOfTenants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  IconButton(onPressed: () { setState(() => _numberOfTenants++); }, icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text('Optional Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Deep Cleaning Before Move-in (+₹1,000)', style: TextStyle(color: textColor)),
              value: _includeCleaning,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _includeCleaning = val ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Property Maintenance Sub (+₹1,500/mo)', style: TextStyle(color: textColor)),
              value: _includeMaintenance,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _includeMaintenance = val ?? false),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupons & Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                if (_appliedCoupon != null)
                  TextButton(
                    onPressed: () => setState(() => _appliedCoupon = null),
                    child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showCouponPicker(context, couponState),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _appliedCoupon != null ? AppColors.primary : Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: _appliedCoupon != null ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(_appliedCoupon != null ? Icons.check_circle : Icons.confirmation_number_outlined, color: _appliedCoupon != null ? AppColors.primary : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _appliedCoupon?.title ?? 'Apply Coupon Code',
                        style: TextStyle(
                          color: _appliedCoupon != null ? AppColors.primary : Colors.grey.shade600,
                          fontWeight: _appliedCoupon != null ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text('Price Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            _buildPriceRow('Monthly Rent', monthlyRent, textColor),
            const SizedBox(height: 8),
            _buildPriceRow('Security Deposit (3x)', deposit, textColor),
            if (_includeCleaning) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Deep Cleaning', cleaningFee, textColor),
            ],
            if (_includeMaintenance) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Maintenance Sub', maintenanceFee, textColor),
            ],
            if (discount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Coupon Discount', -discount, Colors.green),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            _buildPriceRow('Total Payable Now', totalPayable, AppColors.primary, isTotal: true),

            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          boxShadow: AppColors.softShadow,
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              if (_selectedMoveInDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a move-in date')));
                return;
              }
              // Proceed to Payment
              context.push('/payment', extra: {
                'listing': widget.listing,
                'totalPayable': totalPayable,
                'moveInDate': _selectedMoveInDate,
                'appliedCouponId': _appliedCoupon?.id,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  void _showCouponPicker(BuildContext context, AsyncValue<List<CouponEntity>> state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 24),
            Text('Available Coupons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Expanded(
              child: state.when(
                data: (coupons) {
                  final available = coupons.where((c) => !c.isUsed && !c.isExpired).toList();
                  if (available.isEmpty) {
                    return const Center(child: Text('No coupons available'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final c = available[index];
                      // Check if valid for this booking
                      bool isValid = true;
                      if (c.type == 'service' && c.serviceType == 'cleaning' && !_includeCleaning) isValid = false;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassContainer.standard(
                          context: context,
                          child: ListTile(
                            enabled: isValid,
                            title: Text(c.title, style: TextStyle(fontWeight: FontWeight.bold, color: isValid ? null : Colors.grey)),
                            subtitle: Text(isValid ? 'Tap to apply' : 'Can only be applied if cleaning is selected', style: TextStyle(fontSize: 12, color: isValid ? null : Colors.redAccent.withOpacity(0.7))),
                            trailing: isValid ? const Icon(Icons.add_circle_outline, color: AppColors.primary) : null,
                            onTap: () {
                              setState(() => _appliedCoupon = c);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal, color: color)),
        Text('${amount < 0 ? '-' : ''}₹${NumberFormat('#,##,###').format(amount.abs())}', style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600, color: color)),
      ],
    );
  }
}
