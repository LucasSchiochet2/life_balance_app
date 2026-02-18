import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LogExercisePage extends StatefulWidget {
  final int userId;
  final String token;
  final int exerciseId;
  final String exerciseName;

  const LogExercisePage({super.key, required this.userId, required this.token, required this.exerciseId, required this.exerciseName});

  @override
  State<LogExercisePage> createState() => _LogExercisePageState();
}

class _LogExercisePageState extends State<LogExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  final _observationController = TextEditingController();
  double _intensity = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final body = {
        'date': _dateController.text,
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'reps': int.tryParse(_repsController.text) ?? 0,
        'sets': int.tryParse(_setsController.text) ?? 0,
        'intensity': _intensity,
        'observation': _observationController.text,
      };

      final response = await http.post(
        Uri.parse('https://finance-health-production.up.railway.app/api/exercises/${widget.userId}/${widget.exerciseId}/logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log registrado com sucesso!")));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${response.body}")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log: ${widget.exerciseName}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Data (YYYY-MM-DD)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Carga (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: const InputDecoration(labelText: 'Séries'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(labelText: 'Repetições'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Intensidade: ${_intensity.toStringAsFixed(1)}"),
                  Slider(
                    value: _intensity,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    label: _intensity.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _intensity = value;
                      });
                    },
                  ),
                ],
              ),
              TextFormField(
                controller: _observationController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : const Text("Registrar")),
            ],
          ),
        ),
      ),
    );
  }
}
