import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PriceAnalysisChart extends StatelessWidget {
  final double actualPrice;
  final double predictedPrice;

  const PriceAnalysisChart({
    super.key,
    required this.actualPrice,
    required this.predictedPrice,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFair = (actualPrice - predictedPrice).abs() / predictedPrice < 0.1;
    final bool isGreatDeal = actualPrice <= predictedPrice * 0.9;
    
    final Color chartColor = isGreatDeal 
        ? Colors.green 
        : (isFair ? Colors.orange : Colors.red);
        
    final double maxVal = actualPrice > predictedPrice ? actualPrice * 1.2 : predictedPrice * 1.2;
    final double minVal = actualPrice < predictedPrice ? actualPrice * 0.8 : predictedPrice * 0.8;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade900 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: chartColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Price Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                minY: minVal > 0 ? minVal * 0.5 : 0, // Ensure we don't start at absolute 0 if prices are high
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toInt()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        String text;
                        if (value == 0) {
                          text = 'Actual';
                        } else if (value == 1) {
                          text = 'AI Estimate';
                        } else {
                          text = '';
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // Hide Y-axis numbers for cleaner look
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false), // Remove grid border
                gridData: FlGridData(show: false), // Remove grid lines
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: actualPrice,
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: predictedPrice,
                        color: chartColor,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
