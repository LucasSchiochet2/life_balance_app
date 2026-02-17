import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
class MonthSelector extends StatelessWidget {
  final List<MonthlyReport> reports;
  final int selectedIndex;
  final Function(int) onSelected;

  const MonthSelector({
    super.key,
    required this.reports,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: reports.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(entry.value.month),
              selected: entry.key == selectedIndex,
              onSelected: (selected) => selected ? onSelected(entry.key) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}