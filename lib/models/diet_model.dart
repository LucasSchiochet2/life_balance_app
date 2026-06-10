class DietMeal {
  final int id;
  final String date;
  final String status;
  final String mealType;
  final String observation;

  DietMeal({
    required this.id,
    required this.date,
    required this.status,
    required this.mealType,
    required this.observation,
  });

  factory DietMeal.fromJson(Map<String, dynamic> json) {
    return DietMeal(
      id: _parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      status: normalizeDietStatus(json['status']?.toString()),
      mealType: normalizeDietMealType(json['meal_type']?.toString()),
      observation: json['observation']?.toString() ?? '',
    );
  }
}

class DietCharts {
  final int totalMeals;
  final int totalDays;
  final double scoreAverage;
  final Map<String, int> byStatus;
  final Map<String, int> byMealType;
  final List<DietPeriodSummary> byDay;
  final List<DietPeriodSummary> byMonth;
  final String? mealTypeFilter;

  DietCharts({
    required this.totalMeals,
    required this.totalDays,
    required this.scoreAverage,
    required this.byStatus,
    required this.byMealType,
    required this.byDay,
    required this.byMonth,
    this.mealTypeFilter,
  });

  factory DietCharts.fromJson(Map<String, dynamic> json) {
    final source = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final filters = source['filters'] is Map
        ? Map<String, dynamic>.from(source['filters'] as Map)
        : const <String, dynamic>{};

    return DietCharts(
      totalMeals: _parseInt(source['total_meals']),
      totalDays: _parseInt(source['total_days']),
      scoreAverage: _parseDouble(source['score_average']),
      byStatus: _parseStatusMap(source['by_status']),
      byMealType: _parseMealTypeMap(source['by_meal_type']),
      byDay: _parsePeriodList(source['by_day']),
      byMonth: _parsePeriodList(source['by_month']),
      mealTypeFilter: _parseOptionalMealType(filters['meal_type']),
    );
  }

  static DietCharts empty() {
    return DietCharts(
      totalMeals: 0,
      totalDays: 0,
      scoreAverage: 0,
      byStatus: defaultDietStatusCounts(),
      byMealType: defaultDietMealTypeCounts(),
      byDay: const [],
      byMonth: const [],
    );
  }
}

class DietPeriodSummary {
  final String label;
  final int totalMeals;
  final int totalDays;
  final double scoreAverage;
  final Map<String, int> byStatus;

  DietPeriodSummary({
    required this.label,
    required this.totalMeals,
    required this.totalDays,
    required this.scoreAverage,
    required this.byStatus,
  });

  factory DietPeriodSummary.fromJson(Map<String, dynamic> json) {
    return DietPeriodSummary(
      label:
          (json['date'] ??
                  json['day'] ??
                  json['month'] ??
                  json['period'] ??
                  json['label'] ??
                  '')
              .toString(),
      totalMeals: _parseInt(
        json['total_meals'] ?? json['count'] ?? json['total'],
      ),
      totalDays: _parseInt(json['total_days'] ?? json['days']),
      scoreAverage: _parseDouble(json['score_average'] ?? json['score']),
      byStatus: _parseStatusMap(json['by_status'] ?? json['statuses']),
    );
  }

  factory DietPeriodSummary.fromEntry(String label, dynamic value) {
    if (value is Map<String, dynamic>) {
      return DietPeriodSummary.fromJson({'label': label, ...value});
    }

    return DietPeriodSummary(
      label: label,
      totalMeals: _parseInt(value),
      totalDays: 0,
      scoreAverage: 0,
      byStatus: defaultDietStatusCounts(),
    );
  }
}

const List<String> dietStatuses = ['perfeito', 'bom', 'medio', 'fora'];

const List<String> dietMealTypes = [
  'cafe_da_manha',
  'almoco',
  'lanche_da_tarde',
  'janta',
  'ceia',
  'extra',
];

String normalizeDietStatus(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return dietStatuses.contains(normalized) ? normalized : 'medio';
}

String normalizeDietMealType(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return dietMealTypes.contains(normalized) ? normalized : 'extra';
}

String? _parseOptionalMealType(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  return dietMealTypes.contains(normalized) ? normalized : null;
}

String dietStatusLabel(String status) {
  switch (normalizeDietStatus(status)) {
    case 'perfeito':
      return 'Perfeito';
    case 'bom':
      return 'Bom';
    case 'medio':
      return 'Medio';
    case 'fora':
      return 'Fora';
  }

  return 'Medio';
}

String dietMealTypeLabel(String mealType) {
  switch (normalizeDietMealType(mealType)) {
    case 'cafe_da_manha':
      return 'Cafe da manha';
    case 'almoco':
      return 'Almoco';
    case 'lanche_da_tarde':
      return 'Lanche da tarde';
    case 'janta':
      return 'Janta';
    case 'ceia':
      return 'Ceia';
    case 'extra':
      return 'Extra';
  }

  return 'Extra';
}

Map<String, int> defaultDietStatusCounts() {
  return {for (final status in dietStatuses) status: 0};
}

Map<String, int> defaultDietMealTypeCounts() {
  return {for (final mealType in dietMealTypes) mealType: 0};
}

List<DietMeal> dietMealsFromResponse(dynamic decoded) {
  final source = decoded is Map<String, dynamic> && decoded['data'] is List
      ? decoded['data'] as List
      : decoded;

  if (source is! List) return [];

  return source
      .whereType<Map>()
      .map((item) => DietMeal.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

Map<String, int> _parseMealTypeMap(dynamic value) {
  final counts = defaultDietMealTypeCounts();

  if (value is Map) {
    for (final entry in value.entries) {
      final mealType = normalizeDietMealType(entry.key.toString());
      counts[mealType] = _extractCount(entry.value);
    }
  } else if (value is List) {
    for (final item in value) {
      if (item is! Map) continue;
      final mealType = normalizeDietMealType(
        (item['meal_type'] ?? item['type'] ?? item['name'] ?? item['label'])
            ?.toString(),
      );
      counts[mealType] = _extractCount(item);
    }
  }

  return counts;
}

Map<String, int> _parseStatusMap(dynamic value) {
  final counts = defaultDietStatusCounts();

  if (value is Map) {
    for (final entry in value.entries) {
      final status = normalizeDietStatus(entry.key.toString());
      counts[status] = _extractCount(entry.value);
    }
  } else if (value is List) {
    for (final item in value) {
      if (item is! Map) continue;
      final status = normalizeDietStatus(
        (item['status'] ?? item['name'] ?? item['label'])?.toString(),
      );
      counts[status] = _extractCount(item);
    }
  }

  return counts;
}

List<DietPeriodSummary> _parsePeriodList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (item) => DietPeriodSummary.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  if (value is Map) {
    return value.entries
        .map(
          (entry) =>
              DietPeriodSummary.fromEntry(entry.key.toString(), entry.value),
        )
        .toList();
  }

  return [];
}

int _extractCount(dynamic value) {
  if (value is Map) {
    return _parseInt(
      value['total_meals'] ??
          value['count'] ??
          value['total'] ??
          value['value'],
    );
  }

  return _parseInt(value);
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
