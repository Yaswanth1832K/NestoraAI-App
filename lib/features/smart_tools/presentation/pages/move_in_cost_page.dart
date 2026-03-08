import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class MoveInCostCalculatorPage extends StatefulWidget {
  final double? initialRent;
  final double? initialDeposit;

  const MoveInCostCalculatorPage({
    super.key,
    this.initialRent,
    this.initialDeposit,
  });

  @override
  State<MoveInCostCalculatorPage> createState() => _MoveInCostCalculatorPageState();
}

class _MoveInCostCalculatorPageState extends State<MoveInCostCalculatorPage> {
  late double _rent;
  late double _deposit;
  double _maintenance = 2000;
  double _brokerFee = 0;
  double _movingCost = 5000;
  double _utilitySetup = 1500;

  @override
  void initState() {
    super.initState();
    _rent = widget.initialRent ?? 20000;
    _deposit = widget.initialDeposit ?? (_rent * 2);
    _brokerFee = _rent * 0.5; // Default assumption
  }

  double get _totalCost => _rent + _deposit + _maintenance + _brokerFee + _movingCost + _utilitySetup;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Move-in Calculator', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Scanner Grid (Consistent with other tools)
          Positioned.fill(
            child: CustomPaint(painter: _ScannerPainter()),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIsuggestion(isDark),
                  const SizedBox(height: 24),
                  
                  // Summary Card with Pie Chart
                  _buildSummaryCard(isDark, currencyFormat),
                  
                  const SizedBox(height: 32),
                  const Text('BREAKDOWN_DETAILS', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  
                  _CostInputCard(
                    label: 'Monthly Rent',
                    value: _rent,
                    icon: Icons.home_rounded,
                    color: AppColors.primary,
                    onChanged: (v) => setState(() => _rent = v),
                  ),
                  _CostInputCard(
                    label: 'Security Deposit',
                    value: _deposit,
                    icon: Icons.security_rounded,
                    color: AppColors.accentBlue,
                    onChanged: (v) => setState(() => _deposit = v),
                  ),
                  _CostInputCard(
                    label: 'Broker Fee',
                    value: _brokerFee,
                    icon: Icons.person_search_rounded,
                    color: AppColors.accentOrange,
                    onChanged: (v) => setState(() => _brokerFee = v),
                  ),
                  _CostInputCard(
                    label: 'Maintenance',
                    value: _maintenance,
                    icon: Icons.build_circle_rounded,
                    color: Colors.purpleAccent,
                    onChanged: (v) => setState(() => _maintenance = v),
                  ),
                  _CostInputCard(
                    label: 'Moving Cost',
                    value: _movingCost,
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.accentTeal,
                    onChanged: (v) => setState(() => _movingCost = v),
                  ),
                  _CostInputCard(
                    label: 'Utility Setup',
                    value: _utilitySetup,
                    icon: Icons.bolt_rounded,
                    color: Colors.amber,
                    onChanged: (v) => setState(() => _utilitySetup = v),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIsuggestion(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI_ESTIMATE_FOR_AREA', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  'Typical move-in cost in this neighborhood is ₹${NumberFormat('#,##,###').format(75000)}. Your current estimate is ${((_totalCost / 75000) * 100).toInt()}% of average.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, NumberFormat format) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              const Text('TOTAL ESTIMATED COST', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _totalCost),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Text(
                    format.format(value),
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -1),
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(value: _rent, color: AppColors.primary, radius: 50, showTitle: false),
                      PieChartSectionData(value: _deposit, color: AppColors.accentBlue, radius: 50, showTitle: false),
                      PieChartSectionData(value: _brokerFee, color: AppColors.accentOrange, radius: 50, showTitle: false),
                      PieChartSectionData(value: _maintenance, color: Colors.purpleAccent, radius: 50, showTitle: false),
                      PieChartSectionData(value: _movingCost, color: AppColors.accentTeal, radius: 50, showTitle: false),
                      PieChartSectionData(value: _utilitySetup, color: Colors.amber, radius: 50, showTitle: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostInputCard extends StatefulWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final Function(double) onChanged;

  const _CostInputCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_CostInputCard> createState() => _CostInputCardState();
}

class _CostInputCardState extends State<_CostInputCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toInt().toString());
  }

  @override
  void didUpdateWidget(_CostInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_controller.text.endsWith(widget.value.toInt().toString())) {
      _controller.text = widget.value.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    if (val != null) widget.onChanged(val);
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white24, size: 20),
                onPressed: () => widget.onChanged(widget.value - 500),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                onPressed: () => widget.onChanged(widget.value + 500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 80.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
