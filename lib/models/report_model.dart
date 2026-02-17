class ReportResponse {
  final List<MonthlyReport> data;

  ReportResponse({required this.data});

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return ReportResponse(
      data: list.map((i) => MonthlyReport.fromJson(i)).toList(),
    );
  }
}

class MonthlyReport {
  final String month;
  final double totalAmount;
  final int totalCount;
  final List<CategorySummary> summaryByCategory;
  final List<Bill> bills;

  MonthlyReport({
    required this.month,
    required this.totalAmount,
    required this.totalCount,
    required this.summaryByCategory,
    required this.bills,
  });


  static double _parseToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      month: json['month'] ?? '',
      totalAmount: _parseToDouble(json['total_amount']),
      totalCount: json['total_count'] ?? 0,
      summaryByCategory: (json['summary_by_category'] as List?)
          ?.map((i) => CategorySummary.fromJson(i))
          .toList() ?? [],
      bills: (json['bills'] as List?)?.map((i) => Bill.fromJson(i)).toList() ?? [],
    );
  }
}

// Kept purely for backward compatibility if other parts of the app use it, 
// though we will likely migrate away from it in ReportPage.
// Or we can just reuse CategorySummary and Bill as they are consistent.

class ReportData {
  final ReportSummary summary;
  final List<Bill> bills;

  ReportData({required this.summary, required this.bills});

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      summary: ReportSummary.fromJson(json['summary']),
      bills: (json['bills'] as List).map((i) => Bill.fromJson(i)).toList(),
    );
  }
}

class ReportSummary {
  final double totalAmount;
  final int totalCount;
  final List<CategorySummary> byCategory;

  ReportSummary({
    required this.totalAmount,
    required this.totalCount,
    required this.byCategory,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalAmount: MonthlyReport._parseToDouble(json['total_amount']),
      totalCount: json['total_count'],
      byCategory: (json['by_category'] as List)
          .map((i) => CategorySummary.fromJson(i))
          .toList(),
    );
  }
}

class CategorySummary {
  final int categoryId;
  final String categoryName;
  final double totalAmount;
  final double percentage;
  final int count;

  CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    required this.count,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      totalAmount: MonthlyReport._parseToDouble(json['total_amount']),
      percentage: MonthlyReport._parseToDouble(json['percentage']),
      count: json['count'],
    );
  }
}

class Bill {
  final int id;
  final String name;
  final String description;
  final double amount;
  final String dueDate;
  final bool isRecurring;
  final bool isInstallment;
  final bool paid;
  final bool notificationEnabled;
  final String paymentMethod;
  final int categoryId;
  final Category? category;

  Bill({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.isRecurring,
    required this.isInstallment,
    required this.paid,
    required this.notificationEnabled,
    required this.paymentMethod,
    required this.categoryId,
    this.category,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Sem Nome',
      description: json['description'] ?? '',
      amount: MonthlyReport._parseToDouble(json['amount']),
      dueDate: json['due_date'] ?? '',
      isRecurring: json['is_recurring'] == 1 || json['is_recurring'] == true,
      isInstallment: json['is_installment'] == 1 || json['is_installment'] == true,
      paid: json['paid'] == 1 || json['paid'] == true,
      notificationEnabled: json['notification_enabled'] == 1 || json['notification_enabled'] == true,
      paymentMethod: json['payment_method'] ?? 'unknown',
      categoryId: json['category_bill_id'] as int? ?? 0,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Categoria',
      icon: json['icon'] ?? 'fa-question',
    );
  }
}
