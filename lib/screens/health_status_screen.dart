// screens/health_status_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import 'dart:math';

class HealthStatusScreen extends StatefulWidget {
  final List<HealthData> healthHistory;
  const HealthStatusScreen({super.key, required this.healthHistory});

  @override
  State<HealthStatusScreen> createState() => _HealthStatusScreenState();
}

class _HealthStatusScreenState extends State<HealthStatusScreen> {
  // true for Heart Rate, false for SpO2
  List<bool> _selectedChart = [true, false];

  @override
  Widget build(BuildContext context) {
    if (widget.healthHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Waiting for health data..."),
          ],
        ),
      );
    }
    final latestData = widget.healthHistory.first;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0), // Padding for scroll end
        child: Column(
          children: [
            // LATEST READINGS CARD
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latest Readings', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHealthMetric('Heart Rate', latestData.heartRate, 'bpm', Icons.favorite, Colors.red),
                        _buildHealthMetric('SpO2', latestData.spo2, '%', Icons.bloodtype, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Last updated: ${latestData.formattedTimestamp}', style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),

            // NEW: HEALTH CHART CARD
            Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Health Trends', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      ToggleButtons(
                        isSelected: _selectedChart,
                        onPressed: (index) {
                          setState(() {
                            _selectedChart = [false, false];
                            _selectedChart[index] = true;
                          });
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 80) / 2, minHeight: 40.0),
                        children: const [Text('Heart Rate'), Text('SpO2')],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: _HealthChart(
                          key: ValueKey(_selectedChart[0]), // Update chart on toggle
                          history: widget.healthHistory,
                          showHeartRate: _selectedChart[0],
                        ),
                      ),
                    ],
                  ),
                )
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Data History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            // DATA HISTORY LIST
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: widget.healthHistory.length > 10 ? 10 : widget.healthHistory.length, // Show recent 10
              itemBuilder: (context, index) {
                final data = widget.healthHistory[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('HR: ${data.heartRate} bpm', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('SpO2: ${data.spo2}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(data.formattedTimestamp, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, int value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text('$value $unit', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}


// NEW: Chart Widget
class _HealthChart extends StatelessWidget {
  final List<HealthData> history;
  final bool showHeartRate;

  const _HealthChart({super.key, required this.history, required this.showHeartRate});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = history.asMap().entries.map((entry) {
      int index = entry.key;
      HealthData data = entry.value;
      double yValue = showHeartRate ? data.heartRate.toDouble() : data.spo2.toDouble();
      // Reverse index to show latest data on the right
      return FlSpot((history.length - 1 - index).toDouble(), yValue);
    }).toList();

    final Color lineColor = showHeartRate ? Colors.red : Colors.blue;
    final List<double> yValues = history.map((data) => showHeartRate ? data.heartRate.toDouble() : data.spo2.toDouble()).toList();
    final double minY = yValues.reduce(min) - 5;
    final double maxY = yValues.reduce(max) + 5;

    return LineChart(
      LineChartData(
        minY: minY.floorToDouble(),
        maxY: maxY.ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.5),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey)),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}