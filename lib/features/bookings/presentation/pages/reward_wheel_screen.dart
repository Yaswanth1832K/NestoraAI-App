import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/domain/entities/coupon_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/coupon_providers.dart';

class RewardWheelScreen extends ConsumerStatefulWidget {
  const RewardWheelScreen({super.key});

  @override
  ConsumerState<RewardWheelScreen> createState() => _RewardWheelScreenState();
}

class _RewardWheelScreenState extends ConsumerState<RewardWheelScreen> {
  final StreamController<int> controller = StreamController<int>();
  late ConfettiController _confettiController;
  
  bool _isSpinning = false;
  bool _spinFinished = false;
  int _winningIndex = 0;

  final List<String> segments = [
    '10% OFF Next Booking',
    'Free Home Cleaning',
    '₹500 Service Coupon',
    '15% OFF Next Booking',
    'Free AC Service',
    'Better Luck Next Time',
    '20% OFF Next Booking',
    'Free Interior Consultation',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    controller.close();
    _confettiController.dispose();
    super.dispose();
  }

  void _spin() {
    setState(() {
      _isSpinning = true;
    });
    // Random selection
    _winningIndex = Fortune.randomInt(0, segments.length);
    controller.add(_winningIndex);
  }

  void _onSpinComplete() {
    setState(() {
      _isSpinning = false;
      _spinFinished = true;
    });
    if (_winningIndex != 5) { // Index 5 is 'Better Luck Next Time'
      _confettiController.play();
      _saveCoupon();
    }
  }

  Future<void> _saveCoupon() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final segment = segments[_winningIndex];
    late String type;
    double? percent;
    double? amount;
    String? serviceType;

    if (segment.contains('%')) {
      type = 'percent';
      percent = double.tryParse(segment.split('%')[0]);
    } else if (segment.contains('₹')) {
      type = 'amount';
      amount = double.tryParse(segment.replaceAll(RegExp(r'[^0-9]'), ''));
    } else if (segment.contains('Free')) {
      type = 'service';
      if (segment.toLowerCase().contains('cleaning')) serviceType = 'cleaning';
      else if (segment.toLowerCase().contains('ac service')) serviceType = 'ac_service';
      else if (segment.toLowerCase().contains('interior')) serviceType = 'consultation';
    } else {
      type = 'unknown';
    }

    final coupon = CouponEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      type: type,
      title: segment,
      discountPercent: percent,
      discountAmount: amount,
      serviceType: serviceType,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      isUsed: false,
      createdAt: DateTime.now(),
    );

    await ref.read(couponNotifierProvider.notifier).createCoupon(coupon);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Text('Spin to Win!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor))
                      .animate().fadeIn().slideY(begin: -0.2),
                    const SizedBox(height: 8),
                    Text('Win discounts and free services for your new home.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54), textAlign: TextAlign.center)
                      .animate().fadeIn(delay: 200.ms),
                      
                    const SizedBox(height: 40),
                    
                    // Wheel with Responsive Height
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        final wheelSize = (screenHeight * 0.45).clamp(250.0, 400.0);
                        
                        return SizedBox(
                          height: wheelSize,
                          child: FortuneWheel(
                            selected: controller.stream,
                            animateFirst: false,
                            onAnimationEnd: _onSpinComplete,
                            indicators: const <FortuneIndicator>[
                              FortuneIndicator(
                                alignment: Alignment.topCenter,
                                child: TriangleIndicator(color: AppColors.primary),
                              ),
                            ],
                            items: [
                              for (int i = 0; i < segments.length; i++)
                                FortuneItem(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 30),
                                    child: Text(
                                      segments[i], 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)
                                    ),
                                  ),
                                  style: FortuneItemStyle(
                                    color: _getWheelColor(i),
                                    borderColor: isDark ? AppColors.backgroundDark : Colors.white,
                                    borderWidth: 2,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                            ],
                          ),
                        ).animate().scale(curve: Curves.easeOutBack, duration: 800.ms);
                      },
                    ),
  
                    const SizedBox(height: 40),
  
                    // Result or Spin Button
                    if (_spinFinished) ...[
                      _buildResultCard(textColor, isDark)
                    ] else ...[
                      SizedBox(
                        width: 250,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSpinning ? null : _spin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('SPIN NOW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    if (_spinFinished)
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text('Back to Home', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.bold)),
                      )
                    else
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text('Skip', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
                      ).animate().fadeIn(delay: 800.ms),
                      
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Color textColor, bool isDark) {
    final win = _winningIndex != 5;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(win ? Icons.emoji_events : Icons.sentiment_dissatisfied, 
               color: win ? Colors.amber : Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(win ? '🎉 Congratulations!' : 'Better luck next time!', 
               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          if (win) ...[
            const SizedBox(height: 8),
            Text('You won:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 4),
            Text(segments[_winningIndex], 
                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                 textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('Saved to your coupons', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]
        ],
      ),
    ).animate().scaleXY(curve: Curves.elasticOut, duration: 800.ms);
  }

  Color _getWheelColor(int index) {
    if (index == 5) return Colors.grey.shade600; // Better luck next time
    List<Color> colors = [
      AppColors.primary,
      AppColors.accentOrange,
      Colors.green.shade600,
      Colors.blue,
      Colors.purple.shade500,
      Colors.grey,
      AppColors.primary,
      AppColors.accentOrange,
    ];
    return colors[index % colors.length];
  }
}
