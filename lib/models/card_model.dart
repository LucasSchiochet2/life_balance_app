class CreditCard {
  final int id;
  final String name;
  final double limit;
  final DateTime? closingDate;
  final DateTime? expirationDate;
  final List<Invoice> invoices;

  CreditCard({
    required this.id,
    required this.name,
    required this.limit,
    this.closingDate,
    this.expirationDate,
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
      closingDate: json['closing_day'] != null ? DateTime.tryParse(json['closing_day'].toString()) : null,
      expirationDate: json['expiration_date'] != null ? DateTime.tryParse(json['expiration_date'].toString()) : null,
      invoices: invoicesList,
    );
  }
}

class Invoice {
  final String month;
  final double totalAmount;
  final int count;
  final List<CardBill> bills;

  Invoice({
    required this.month,
    required this.totalAmount,
    required this.count,
    required this.bills,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    var billsList = json['bills'] as List? ?? [];
    List<CardBill> bills = billsList.map((i) => CardBill.fromJson(i)).toList();

    return Invoice(
      month: json['month'],
      // Handle int, double and String
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      count: json['count'],
      bills: bills,
    );
  }
}

class CardBill {
  final int id;
  final String name;
  final String description;
  final double amount;
  final String dueDate;
  final bool isRecurring;
  final bool paid;
  final String paymentMethod;
  final int categoryId;
  final int creditCardId;
  final int userId;

  CardBill({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.isRecurring,
    required this.paid,
    required this.paymentMethod,
    required this.categoryId,
    required this.creditCardId,
    required this.userId,
  });

  factory CardBill.fromJson(Map<String, dynamic> json) {
    return CardBill(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      // Handle "50.00" string to double, or int
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      dueDate: json['due_date'],
      // Handle 0/1 to bool
      isRecurring: json['is_recurring'] == 1 || json['is_recurring'] == true,
      paid: json['paid'] == 1 || json['paid'] == true, 
      paymentMethod: json['payment_method'],
      categoryId: json['category_bill_id'],
      creditCardId: json['credit_card_id'],
      userId: json['user_id'],
    );
  }
}
