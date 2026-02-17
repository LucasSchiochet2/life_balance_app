import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
class SummaryCard extends StatelessWidget {
  final MonthlyReport report;

  const SummaryCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Total Gasto (${report.month})", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "R\$ ${report.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text("${report.totalCount} transações", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}