import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InvestmentGoalPage extends StatefulWidget {
  final String token;
  final int userId;

  const InvestmentGoalPage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<InvestmentGoalPage> createState() => _InvestmentGoalPageState();
}

class _InvestmentGoalPageState extends State<InvestmentGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();

  bool _isFetching = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchGoal();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _fetchGoal() async {
    setState(() => _isFetching = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://finance-health-production.up.railway.app/api/investments/${widget.userId}/goal',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final goal = _extractGoal(jsonDecode(response.body));
        if (goal > 0) {
          _goalController.text = goal.toStringAsFixed(2);
        }
      } else if (response.statusCode != 404) {
        _showMessage('Erro ao buscar meta: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Erro: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final goal = _parseAmount(_goalController.text);
    final body = jsonEncode({
      'goal': goal,
      'amount': goal,
      'goal_amount': goal,
    });

    try {
      final response = await http.put(
        Uri.parse(
          'https://finance-health-production.up.railway.app/api/investments/${widget.userId}/goal',
        ),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meta atualizada.')));
        Navigator.pop(context, true);
        return;
      }

      _showMessage('Erro ao salvar meta: ${response.body}');
    } catch (e) {
      _showMessage('Erro: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  double _extractGoal(dynamic decoded) {
    final source = decoded is Map && decoded['data'] != null
        ? decoded['data']
        : decoded;

    if (source is num) return source.toDouble();

    if (source is Map) {
      for (final key in const [
        'goal',
        'amount',
        'goal_amount',
        'target',
        'target_amount',
        'meta',
      ]) {
        final parsed = _parseAmount(source[key]?.toString() ?? '');
        if (parsed > 0) return parsed;
      }
    }

    return 0;
  }

  double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar meta')),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _goalController,
                      decoration: const InputDecoration(
                        labelText: 'Meta geral de investimento (R\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final goal = _parseAmount(value ?? '');
                        if (goal <= 0) {
                          return 'Informe uma meta maior que zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveGoal,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.flag),
                        label: const Text('Salvar meta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
