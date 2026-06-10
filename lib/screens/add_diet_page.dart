import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/diet_model.dart';

class AddDietPage extends StatefulWidget {
  final String token;
  final int userId;
  final DietMeal? mealToEdit;

  const AddDietPage({
    super.key,
    required this.token,
    required this.userId,
    this.mealToEdit,
  });

  @override
  State<AddDietPage> createState() => _AddDietPageState();
}

class _AddDietPageState extends State<AddDietPage> {
  final _formKey = GlobalKey<FormState>();
  final _observationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedMealType = 'almoco';
  String _selectedStatus = 'bom';
  bool _isLoading = false;

  bool get _isEditing => widget.mealToEdit != null;

  @override
  void initState() {
    super.initState();

    final meal = widget.mealToEdit;
    if (meal != null) {
      _selectedDate = DateTime.tryParse(meal.date) ?? DateTime.now();
      _selectedMealType = normalizeDietMealType(meal.mealType);
      _selectedStatus = normalizeDietStatus(meal.status);
      _observationController.text = meal.observation;
    }
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() => _selectedDate = picked);
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = jsonEncode({
      'date': _formatDate(_selectedDate),
      'meal_type': _selectedMealType,
      'status': _selectedStatus,
      'observation': _observationController.text.trim(),
    });

    final uri = _isEditing
        ? Uri.parse(
            'https://finance-health-production.up.railway.app/api/diet/${widget.userId}/${widget.mealToEdit!.id}',
          )
        : Uri.parse(
            'https://finance-health-production.up.railway.app/api/diet/${widget.userId}',
          );

    try {
      final response = _isEditing
          ? await http.put(uri, headers: _headers, body: body)
          : await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      _showMessage('Erro ao salvar: ${response.body}');
    } catch (e) {
      _showMessage('Erro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDisplayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar refeicao' : 'Nova refeicao'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Data'),
                subtitle: Text(_formatDisplayDate(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Refeicao',
                  border: OutlineInputBorder(),
                ),
                items: dietMealTypes
                    .map(
                      (mealType) => DropdownMenuItem(
                        value: mealType,
                        child: Text(dietMealTypeLabel(mealType)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedMealType = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: dietStatuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(dietStatusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observationController,
                decoration: const InputDecoration(
                  labelText: 'Observacao',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveMeal,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditing ? 'Atualizar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
