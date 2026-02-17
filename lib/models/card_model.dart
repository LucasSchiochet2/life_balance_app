class CreditCard {
  final int id;
  final String name;
  final double limit;
  final List<Invoice> invoices;

  CreditCard({
    required this.id,
    required this.name,
    required this.limit,
    required this.invoices,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    var list = json['invoices'] as List? ?? [];
    List<Invoice> invoicesList = list.map((i) => Invoice.fromJson(i)).toList();

    return CreditCard(
      id: json['id'],
      name: json['name'],
      // Handle int, double and String (API sometimes returns "500.00")
      limit: double.tryParse(json['limit'].toString()) ?? 0.0,
      invoices: invoicesList,
    );
  }
}

class Invoice {
  final String month;
  final double totalAmount;
  final int count;

  Invoice({
    required this.month,
    required this.totalAmount,
    required this.count,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      month: json['month'],
      // Handle int, double and String
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      count: json['count'],
    );
  }
}
