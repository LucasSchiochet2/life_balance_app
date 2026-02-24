import 'package:flutter/material.dart';
import '../models/monthly_spend_model.dart';

class SalaryProgressBar extends StatelessWidget {
  final MonthlySpend monthlySpend;

  const SalaryProgressBar({
    super.key,
    required this.monthlySpend,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the percentage string "45%" -> 0.45
    double percentage = 0.0;
    try {
      String pctString = monthlySpend.spendPercentageOfSalary.replaceAll('%', '').trim();
      percentage = double.parse(pctString) / 100.0;
    } catch (e) {
      percentage = 0.0;
    }

    // Clamp percentage between 0 and 1 for the progress bar (or allow overflow visually if needed, but LinearProgressIndicator clamps)
    double progressValue = percentage.clamp(0.0, 1.0);

    Color progressColor;
    if (percentage < 0.5) {
      progressColor = Colors.green;
    } else if (percentage < 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Comprometimento da Renda",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 20,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Salário: R\$ ${monthlySpend.userSalary.toStringAsFixed(2)} / Gasto Total: R\$ ${monthlySpend.totalSpendForMonth.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  monthlySpend.spendPercentageOfSalary,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const Text(
              "Esse indicador considera seus gastos considerando a fatura do cartão de crédito do mês anterior, além dos gastos atuais no débito.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Text(
              "Não considera gastos com cartão de crédito do mês atual.",
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
