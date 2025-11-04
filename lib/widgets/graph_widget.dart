// lib/widgets/graph_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphWidget extends StatelessWidget {
  final List<FlSpot> spots;

  GraphWidget({required this.spots});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}