import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/exercise_log_model.dart';
import '../models/workout_model.dart' hide ExerciseLog;

class ExerciseProgressPage extends StatefulWidget {
  final int userId;
  final String token;
  // Change to match what is passed from workout_detail_page
  final int exerciseId;
  final String exerciseName;
  
  const ExerciseProgressPage({
    super.key,
    required this.userId,
    required this.token,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ExerciseProgressPage> createState() => _ExerciseProgressPageState();
}

class _ExerciseProgressPageState extends State<ExerciseProgressPage> {
  List<ExerciseLog> _logs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  final _observationController = TextEditingController();
  double _intensity = 0.0;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    // Correct URL. Assuming backend route is /api/workout/logs/exercise/{exerciseId} or similar
    // The previous code had: /api/exercises/${widget.userId}/${widget.exerciseId}/logs
    try {
      final response = await http.get(
        // Correct endpoint for fetching logs
        Uri.parse('https://finance-health-production.up.railway.app/api/exercises/${widget.userId}/${widget.exerciseId}/logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _logs = data.map((json) => ExerciseLog.fromJson(json)).toList();
          // Sort by date ascending for the chart
          _logs.sort((a, b) => a.date.compareTo(b.date));
        });
      } else {
        // Fallback or error handling
        print('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar logs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final body = {
        'date': _dateController.text, // ensure API accepts date string in this format
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
        _weightController.clear();
        _repsController.clear();
        _setsController.clear();
        _observationController.clear();
        // Keep date aimed at today
        _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log registrado com sucesso!")));
        _fetchLogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Evolução: ${widget.exerciseName}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Add Log Form
                  const Text("Adicionar Novo Registro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Padding(
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
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                                    decoration: const InputDecoration(labelText: 'Reps'),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitLog, 
                              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                              child: _isSubmitting ? const CircularProgressIndicator() : const Text("Registrar"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const Text("Histórico", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // List Section
                   _logs.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Nenhum registro encontrado.")))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            // Reverse list for display (newest first)
                            final log = _logs[_logs.length - 1 - index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 25,
                                  child: Text("${log.weight.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12)),
                                ),
                                title: Text(DateFormat('dd/MM/yyyy').format(log.date)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${log.sets} séries x ${log.reps} reps"),
                                    Text("Intensidade: ${log.intensity.toStringAsFixed(1)}"),
                                    if (log.observation != null && log.observation!.isNotEmpty)
                                      Text("Obs: ${log.observation}", style: const TextStyle(fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  
                  if (_logs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    // Chart Section
                    const Text("Gráfico de Evolução", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < _logs.length) {
                                    final date = _logs[value.toInt()].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat('dd/MM').format(date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 30,
                                interval: 1, 
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _logs.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value.weight);
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFFD81B60),
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
