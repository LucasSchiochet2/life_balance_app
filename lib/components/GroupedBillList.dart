import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
class GroupedBillList extends StatelessWidget {
  final List<Map<String, dynamic>>? groupedBills; 
  final List<Bill>? monthlyBills; // Mudei de flatBills para monthlyBills para bater com a ReportPage
  final bool isLoading;
  final Function(Bill)? onBillTap;

  const GroupedBillList({
    super.key, 
    this.groupedBills, 
    this.monthlyBills, 
    this.isLoading = false, // Inicializado como falso por padrão
    this.onBillTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupedBills != null) {
      return Column(
        children: groupedBills!.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(group['month'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF02735E))),
              ),
              ...group['bills'].map<Widget>((bill) => _BillTile(
                  bill: bill,
                  onTap: () => onBillTap?.call(bill),
                )).toList(),
            ],
          );
        }).toList(),
      );
    }

    if (monthlyBills != null && monthlyBills!.isNotEmpty) {
      return Column(
        children: monthlyBills!.map((bill) => _BillTile(
            bill: bill,
            onTap: () => onBillTap?.call(bill),
          )).toList(),
      );
    }

    return const Center(child: Text("Nenhuma conta encontrada"));
  }
}

// Widget auxiliar privado (mesmo arquivo)
class _BillTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onTap;

  const _BillTile({required this.bill, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          bill.paid ? Icons.check_circle : Icons.pending, 
          color: bill.paid ? const Color(0xFF03A678) : const Color(0xFFF27405)
        ),
        title: Text(bill.name),
        subtitle: Text(bill.dueDate.split(' ')[0]),
        trailing: Text(
          "R\$ ${bill.amount.toStringAsFixed(2)}", 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}