import 'package:flutter/material.dart';
import '../models/report_model.dart';
class SummaryCard extends StatelessWidget {
  final MonthlyReport report;

  const SummaryCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Total Gasto (${report.month})", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                "R\$ ${report.totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFD81B60)),
              ),
              const SizedBox(height: 6),
              Text("${report.totalCount} transações", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
