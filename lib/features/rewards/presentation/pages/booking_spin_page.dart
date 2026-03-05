import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class BookingSpinPage extends ConsumerStatefulWidget {
  const BookingSpinPage({super.key});

  @override
  ConsumerState<BookingSpinPage> createState() => _BookingSpinPageState();
}

class _BookingSpinPageState extends ConsumerState<BookingSpinPage> {
  final StreamController<int> selected = StreamController<int>();
  bool _hasSpun = false;
  int? _selectedValue;

  final items = <String>[
    '5% off next rent',
    '₹500 off next booking',
    '10% off home services',
    'Free cleaning service',
    'No reward',
  ];

  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  void _spin() {
    if (_hasSpun) return;
    setState(() {
      _hasSpun = true;
    });
    final value = Fortune.randomInt(0, items.length);
    _selectedValue = value;
    selected.add(value);
  }

  void _onAnimationEnd() {
    if (_selectedValue == null) return;
    final reward = items[_selectedValue!];
    
    if (reward != 'No reward') {
      ref.read(rewardsProvider.notifier).addReward(reward);
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              reward == 'No reward' ? Icons.sentiment_dissatisfied : Icons.celebration, 
              color: reward == 'No reward' ? Colors.grey : Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reward == 'No reward' ? 'Better luck next time!' : 'Congratulations!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          reward == 'No reward' 
              ? 'Unfortunately, you won no reward this time.' 
              : 'You won a coupon for: $reward! It has been successfully saved to your rewards section.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context); // Return to previous screen
              }
            },
            child: const Text('Claim & Finish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF385C))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        title: const Text('Booking Successful!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Force them to engage with the wheel
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                'Payment received successfully! Spin the wheel to win a special bonus reward. You get 1 spin per booking!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: FortuneWheel(
                  selected: selected.stream,
                  items: [
                    for (int i = 0; i < items.length; i++)
                      FortuneItem(
                        child: Text(
                          items[i], 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                            color: Colors.white,
                          )
                        ),
                        style: FortuneItemStyle(
                          color: i % 2 == 0 
                              ? const Color(0xFFFF385C) 
                              : const Color(0xFFBD1E59),
                          borderColor: Colors.white,
                          borderWidth: 2,
                        ),
                      ),
                  ],
                  onAnimationEnd: _onAnimationEnd,
                  animateFirst: false,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasSpun ? null : _spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF385C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _hasSpun ? 0 : 4,
                  ),
                  child: Text(
                    _hasSpun ? 'Spinning...' : 'SPIN & WIN', 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ),
            // Secret skip button just in case
            TextButton(
               onPressed: _hasSpun ? null : () {
                 if(Navigator.canPop(context)) {
                    Navigator.pop(context);
                 } else {
                    context.pop();
                 }
               },
               child: const Text("Skip", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
