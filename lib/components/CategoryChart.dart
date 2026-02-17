import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';

class CategoryChart extends StatelessWidget {
  final List<CategorySummary> categories;
  final int? touchedIndex;
  final List<Color> availableColors; // Nome exato esperado
  final Function(int categoryId, int index) onCategoryTap;

  const CategoryChart({
    super.key,
    required this.categories,
    required this.touchedIndex,
    required this.availableColors,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const Center(child: Text("Sem dados"));

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (response != null && response.touchedSection != null) {
                    final index = response.touchedSection!.touchedSectionIndex;
                    if (index >= 0 && index < categories.length) {
                      onCategoryTap(categories[index].categoryId, index);
                    }
                  }
                },
              ),
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: List.generate(categories.length, (i) {
                final isTouched = i == touchedIndex;
                final cat = categories[i];
                return PieChartSectionData(
                  color: availableColors[i % availableColors.length],
                  value: cat.percentage,
                  title: '${cat.percentage.toStringAsFixed(0)}%',
                  radius: isTouched ? 60.0 : 50.0,
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    fontSize: 14
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...categories.asMap().entries.map((entry) {
          int i = entry.key;
          var cat = entry.value;
          return ListTile(
            dense: true,
            leading: Icon(Icons.circle, color: availableColors[i % availableColors.length], size: 16),
            title: Text(
              cat.categoryName, 
              style: TextStyle(fontWeight: i == touchedIndex ? FontWeight.bold : FontWeight.normal)
            ),
            trailing: Text("R\$ ${cat.totalAmount.toStringAsFixed(2)}"),
          );
        }).toList(),
      ],
    );
  }
}