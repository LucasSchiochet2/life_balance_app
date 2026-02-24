class MonthlySpend {
  final int month;
  final int year;
  final double userSalary;
  final double debitExpensesCurrentMonth;
  final double creditCardInvoicePreviousMonth;
  final double totalSpendForMonth;
  final String spendPercentageOfSalary;

  MonthlySpend({
    required this.month,
    required this.year,
    required this.userSalary,
    required this.debitExpensesCurrentMonth,
    required this.creditCardInvoicePreviousMonth,
    required this.totalSpendForMonth,
    required this.spendPercentageOfSalary,
  });

  factory MonthlySpend.fromJson(Map<String, dynamic> json) {
    return MonthlySpend(
      month: json['month'],
      year: json['year'],
      userSalary: _parseToDouble(json['user_salary']),
      debitExpensesCurrentMonth: _parseToDouble(json['debit_expenses_current_month']),
      creditCardInvoicePreviousMonth: _parseToDouble(json['credit_card_invoice_previous_month']),
      totalSpendForMonth: _parseToDouble(json['total_spend_for_month']),
      spendPercentageOfSalary: json['spend_percentage_of_salary'] ?? "0%",
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
