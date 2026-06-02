import 'package:flutter/material.dart';
import '../models/report_model.dart';

IconData billCategoryIcon(Bill bill) {
  final iconById = _categoryIconById(bill.categoryId);
  if (iconById != null) return iconById;

  final categoryText = _normalize(
    [bill.category?.name, bill.categoryName].whereType<String>().join(' '),
  );

  if (_containsAny(categoryText, [
    'aliment',
    'food',
    'utensil',
    'restaurant',
  ])) {
    return Icons.restaurant;
  }
  if (_containsAny(categoryText, ['transport', 'bus', 'car', 'uber', 'taxi'])) {
    return Icons.directions_bus;
  }
  if (_containsAny(categoryText, ['lazer', 'game', 'fun', 'cinema', 'sport'])) {
    return Icons.sports_esports;
  }
  if (_containsAny(categoryText, ['saude', 'health', 'medical', 'heart'])) {
    return Icons.medical_services;
  }
  if (_containsAny(categoryText, ['educ', 'school', 'book', 'graduation'])) {
    return Icons.school;
  }
  if (_containsAny(categoryText, ['moradia', 'home', 'house', 'rent'])) {
    return Icons.home;
  }
  if (_containsAny(categoryText, [
    'conta',
    'assinatura',
    'bill',
    'receipt',
    'subscription',
  ])) {
    return Icons.receipt_long;
  }
  if (_containsAny(categoryText, ['outros', 'other', 'misc', 'category'])) {
    return Icons.category;
  }
  if (_containsAny(categoryText, ['financ', 'bank', 'loan', 'money'])) {
    return Icons.account_balance;
  }
  if (_containsAny(categoryText, ['cartao', 'card', 'credit'])) {
    return Icons.credit_card;
  }
  if (_containsAny(categoryText, ['seguro', 'insurance', 'shield'])) {
    return Icons.health_and_safety;
  }
  if (_containsAny(categoryText, ['taxa', 'fee', 'quote'])) {
    return Icons.request_quote;
  }

  return Icons.category;
}

IconData? _categoryIconById(int categoryId) {
  return switch (categoryId) {
    1 => Icons.restaurant,
    2 => Icons.directions_bus,
    3 => Icons.sports_esports,
    4 => Icons.medical_services,
    5 => Icons.school,
    6 => Icons.home,
    7 => Icons.receipt_long,
    8 => Icons.category,
    _ => null,
  };
}

bool _containsAny(String source, List<String> values) {
  return values.any((value) => source.contains(value));
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u00e1\u00e0\u00e3\u00e2\u00e4]'), 'a')
      .replaceAll(RegExp(r'[\u00e9\u00e8\u00ea\u00eb]'), 'e')
      .replaceAll(RegExp(r'[\u00ed\u00ec\u00ee\u00ef]'), 'i')
      .replaceAll(RegExp(r'[\u00f3\u00f2\u00f5\u00f4\u00f6]'), 'o')
      .replaceAll(RegExp(r'[\u00fa\u00f9\u00fb\u00fc]'), 'u')
      .replaceAll(RegExp(r'[\u00e7]'), 'c');
}
