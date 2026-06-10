import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/diet_model.dart';
import 'add_diet_page.dart';

class DietPage extends StatefulWidget {
  final String token;
  final int userId;

  const DietPage({super.key, required this.token, required this.userId});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  List<DietMeal> _meals = [];
  DietCharts _charts = DietCharts.empty();
  bool _isLoading = true;

  String? _statusFilter;
  String? _mealTypeFilter;
  DateTime? _dateFilter;
  DateTimeRange? _rangeFilter;

  @override
  void initState() {
    super.initState();
    _loadDiet();
  }

  Future<void> _loadDiet() async {
    setState(() => _isLoading = true);

    final meals = await _fetchMeals();
    final charts = await _fetchCharts();

    if (!mounted) return;
    setState(() {
      _meals = meals;
      _charts = charts;
      _isLoading = false;
    });
  }

  Future<List<DietMeal>> _fetchMeals() async {
    try {
      final response = await http.get(_dietUri(), headers: _headers);

      if (response.statusCode == 200) {
        return dietMealsFromResponse(jsonDecode(response.body));
      }

      if (response.statusCode == 401) {
        _showMessage('Sessao expirada. Faca login novamente.');
      } else {
        _showMessage('Erro ao carregar dieta: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Erro de conexao: $e');
    }

    return [];
  }

  Future<DietCharts> _fetchCharts() async {
    try {
      final response = await http.get(
        _dietUri(charts: true),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return DietCharts.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Erro ao carregar graficos de dieta: $e');
    }

    return DietCharts.empty();
  }

  Uri _dietUri({bool charts = false}) {
    final path = charts ? 'charts' : null;
    final base = path == null
        ? 'https://finance-health-production.up.railway.app/api/diet/${widget.userId}'
        : 'https://finance-health-production.up.railway.app/api/diet/${widget.userId}/$path';
    final query = _queryParameters();

    return Uri.parse(
      base,
    ).replace(queryParameters: query.isEmpty ? null : query);
  }

  Map<String, String> _queryParameters() {
    final query = <String, String>{};

    if (_statusFilter != null) {
      query['status'] = _statusFilter!;
    }

    if (_mealTypeFilter != null) {
      query['meal_type'] = _mealTypeFilter!;
    }

    if (_dateFilter != null) {
      query['date'] = _formatApiDate(_dateFilter!);
    } else if (_rangeFilter != null) {
      query['start_date'] = _formatApiDate(_rangeFilter!.start);
      query['end_date'] = _formatApiDate(_rangeFilter!.end);
    }

    return query;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  Future<void> _openMealForm([DietMeal? meal]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDietPage(
          token: widget.token,
          userId: widget.userId,
          mealToEdit: meal,
        ),
      ),
    );

    if (result == true) {
      _loadDiet();
    }
  }

  Future<void> _confirmDelete(DietMeal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir refeicao'),
        content: Text(
          'Deseja excluir o registro de ${_formatDisplayDate(meal.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Color(0xFFC2185B)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteMeal(meal.id);
    }
  }

  Future<void> _deleteMeal(int mealId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://finance-health-production.up.railway.app/api/diet/${widget.userId}/$mealId',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showMessage('Refeicao excluida.');
        _loadDiet();
        return;
      }

      _showMessage('Erro ao excluir: ${response.statusCode}');
    } catch (e) {
      _showMessage('Erro: $e');
    }
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _dateFilter = picked;
      _rangeFilter = null;
    });
    _loadDiet();
  }

  Future<void> _pickRangeFilter() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _rangeFilter ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _rangeFilter = picked;
      _dateFilter = null;
    });
    _loadDiet();
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _mealTypeFilter = null;
      _dateFilter = null;
      _rangeFilter = null;
    });
    _loadDiet();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDisplayDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }

  Color _statusColor(String status) {
    switch (normalizeDietStatus(status)) {
      case 'perfeito':
        return const Color(0xFF2E7D32);
      case 'bom':
        return const Color(0xFF00897B);
      case 'medio':
        return const Color(0xFFF9A825);
      case 'fora':
        return const Color(0xFFC2185B);
    }

    return const Color(0xFF616161);
  }

  IconData _statusIcon(String status) {
    switch (normalizeDietStatus(status)) {
      case 'perfeito':
        return Icons.check_circle;
      case 'bom':
        return Icons.thumb_up_alt;
      case 'medio':
        return Icons.remove_circle;
      case 'fora':
        return Icons.warning;
    }

    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dieta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadDiet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMealForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDiet,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 16),
                  _buildSummary(),
                  const SizedBox(height: 16),
                  _buildStatusBreakdown(),
                  const SizedBox(height: 16),
                  _buildMealTypeBreakdown(),
                  const SizedBox(height: 16),
                  _buildPeriodSummaries(),
                  const SizedBox(height: 16),
                  _buildMealList(),
                  const SizedBox(height: 72),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    final hasFilters =
        _statusFilter != null ||
        _mealTypeFilter != null ||
        _dateFilter != null ||
        _rangeFilter != null;
    final rangeLabel = _rangeFilter == null
        ? 'Periodo'
        : '${_formatApiDate(_rangeFilter!.start)} ate ${_formatApiDate(_rangeFilter!.end)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_statusFilter ?? 'todos'),
              initialValue: _statusFilter ?? 'todos',
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'todos', child: Text('Todos')),
                ...dietStatuses.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(dietStatusLabel(status)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value == 'todos' ? null : value;
                });
                _loadDiet();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_mealTypeFilter ?? 'todas'),
              initialValue: _mealTypeFilter ?? 'todas',
              decoration: const InputDecoration(
                labelText: 'Refeicao',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'todas', child: Text('Todas')),
                ...dietMealTypes.map(
                  (mealType) => DropdownMenuItem(
                    value: mealType,
                    child: Text(dietMealTypeLabel(mealType)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _mealTypeFilter = value == 'todas' ? null : value;
                });
                _loadDiet();
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDateFilter,
                  icon: const Icon(Icons.today),
                  label: Text(
                    _dateFilter == null ? 'Data' : _formatApiDate(_dateFilter!),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickRangeFilter,
                  icon: const Icon(Icons.date_range),
                  label: Text(rangeLabel),
                ),
                if (hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 3 : 2;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 3 ? 2.4 : 1.8,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _SummaryTile(
              icon: Icons.restaurant,
              title: 'Refeicoes',
              value: _charts.totalMeals.toString(),
            ),
            _SummaryTile(
              icon: Icons.calendar_month,
              title: 'Dias',
              value: _charts.totalDays.toString(),
            ),
            _SummaryTile(
              icon: Icons.insights,
              title: 'Media',
              value: _charts.scoreAverage.toStringAsFixed(1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBreakdown() {
    final total = _charts.totalMeals == 0 ? 1 : _charts.totalMeals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo por status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...dietStatuses.map((status) {
              final count = _charts.byStatus[status] ?? 0;
              final color = _statusColor(status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_statusIcon(status), size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(dietStatusLabel(status))),
                        Text(count.toString()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      minHeight: 8,
                      value: count / total,
                      color: color,
                      backgroundColor: color.withAlpha(35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeBreakdown() {
    final total = _charts.totalMeals == 0 ? 1 : _charts.totalMeals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo por refeicao',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...dietMealTypes.map((mealType) {
              final count = _charts.byMealType[mealType] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(dietMealTypeLabel(mealType))),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: count / total,
                        color: const Color(0xFFD81B60),
                        backgroundColor: const Color(0xFFFFE4EE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(count.toString()),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSummaries() {
    if (_charts.byDay.isEmpty && _charts.byMonth.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_charts.byDay.isNotEmpty)
          _PeriodSummaryCard(title: 'Por dia', summaries: _charts.byDay),
        if (_charts.byDay.isNotEmpty && _charts.byMonth.isNotEmpty)
          const SizedBox(height: 12),
        if (_charts.byMonth.isNotEmpty)
          _PeriodSummaryCard(title: 'Por mes', summaries: _charts.byMonth),
      ],
    );
  }

  Widget _buildMealList() {
    if (_meals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nenhuma refeicao encontrada.')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Refeicoes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._meals.map(_buildMealCard),
      ],
    );
  }

  Widget _buildMealCard(DietMeal meal) {
    final color = _statusColor(meal.status);
    final subtitle = meal.observation.isEmpty
        ? dietStatusLabel(meal.status)
        : '${dietStatusLabel(meal.status)} - ${meal.observation}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(35),
          child: Icon(_statusIcon(meal.status), color: color),
        ),
        title: Text(
          '${dietMealTypeLabel(meal.mealType)} - ${_formatDisplayDate(meal.date)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _openMealForm(meal);
            } else if (value == 'delete') {
              _confirmDelete(meal);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('Editar')),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Color(0xFFC2185B)),
                title: Text('Excluir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _PeriodSummaryCard extends StatelessWidget {
  final String title;
  final List<DietPeriodSummary> summaries;

  const _PeriodSummaryCard({required this.title, required this.summaries});

  @override
  Widget build(BuildContext context) {
    final visible = summaries.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...visible.map(
              (summary) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(summary.label),
                subtitle: summary.scoreAverage > 0
                    ? Text('Media: ${summary.scoreAverage.toStringAsFixed(1)}')
                    : null,
                trailing: Text('${summary.totalMeals} refeicoes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
