import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/session.dart';

class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key, required this.sessions});
  final List<SessionEntity> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final sorted = [...sessions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].rating.score.toDouble()));
    }
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 3.5,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                  show: true, color: color.withOpacity(.12)),
            ),
          ],
        ),
      ),
    );
  }
}
