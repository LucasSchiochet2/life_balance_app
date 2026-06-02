import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workout_model.dart'; // Assume created
import 'create_exercise_page.dart';

class CreateWorkoutPage extends StatefulWidget {
  final int userId;
  final String token;
  final Workout? workoutToEdit;

  const CreateWorkoutPage({
    super.key, 
    required this.userId, 
    required this.token,
    this.workoutToEdit,
  });

  @override
  State<CreateWorkoutPage> createState() => _CreateWorkoutPageState();
}

class _CreateWorkoutPageState extends State<CreateWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _observationController = TextEditingController();
  final _defaultSetsController = TextEditingController(text: "3");
  final _defaultRepsController = TextEditingController(text: "12");

  List<Exercise> _availableExercises = [];
  List<Map<String, dynamic>> _selectedExercises = []; // Stores {id, sets, reps, order} used for JSON
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
    if (widget.workoutToEdit != null) {
      _loadWorkoutData();
    }
  }

  void _loadWorkoutData() {
    final w = widget.workoutToEdit!;
    _nameController.text = w.name;
    _descriptionController.text = w.description ?? '';
    _observationController.text = w.observation ?? '';
    _defaultSetsController.text = w.defaultSets?.toString() ?? '3';
    _defaultRepsController.text = w.defaultReps?.toString() ?? '12';

    _selectedExercises = w.exercises.map((e) => {
      'id': e.exerciseId, // This is the exercise ID
      'name': e.exerciseName,
      'sets': e.sets,
      'reps': e.reps,
      'order': e.order,
    }).toList();
    // Sort by order just in case
    _selectedExercises.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  }

  Future<List<Exercise>> _fetchExercises([String? query]) async {
    try {
      String url = 'https://finance-health-production.up.railway.app/api/exercises/${widget.userId}';
      if (query != null && query.isNotEmpty) {
        url += '?search=$query';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final exercises = data.map((json) => Exercise.fromJson(json)).toList();
        setState(() {
          _availableExercises = exercises;
        });
        return exercises;
      }
    } catch (e) {
      print('Erro ao buscar exercícios: $e');
    }
    return [];
  }

  Future<void> _confirmDeleteExercise(Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Exercício"),
        content: Text("Deseja realmente excluir '${exercise.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Excluir", style: TextStyle(color: Color(0xFFC2185B)))),
        ],
      )
    );

    if (confirm == true) {
       _deleteExercise(exercise.id);
    }
  }

  Future<void> _deleteExercise(int exerciseId) async {
    try {
       final response = await http.delete(
         Uri.parse('https://finance-health-production.up.railway.app/api/exercises/${widget.userId}/$exerciseId'),
         headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
       );

       if (response.statusCode == 200 || response.statusCode == 204) {
          _fetchExercises();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exercício excluído")));
       } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao excluir: ${response.statusCode}")));
       }
    } catch (e) {
       if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _selectedExercises.add({
        'id': exercise.id,
        'name': exercise.name, // Just for display
        'sets': int.tryParse(_defaultSetsController.text) ?? 3,
        'reps': int.tryParse(_defaultRepsController.text) ?? 12,
        'order': _selectedExercises.length + 1,
      });
    });
  }

  void _removeExercise(int index) {
      setState(() {
        _selectedExercises.removeAt(index);
        // Reorder
        for(int i=0; i<_selectedExercises.length; i++) {
             _selectedExercises[i]['order'] = i + 1;
        }
      });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adicione pelo menos um exercício")));
      return;
    }

    setState(() => _isLoading = true);

    final isEditing = widget.workoutToEdit != null;
    final url = isEditing
      ? Uri.parse('https://finance-health-production.up.railway.app/api/workouts/${widget.userId}/${widget.workoutToEdit!.id}')
      : Uri.parse('https://finance-health-production.up.railway.app/api/workouts/${widget.userId}');

    try {
      final body = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'observation': _observationController.text,
        'default_sets': int.tryParse(_defaultSetsController.text),
        'default_reps': int.tryParse(_defaultRepsController.text),
        'exercises': _selectedExercises.map((e) => {
          'id': e['id'], // Exercise ID
          'sets': e['sets'],
          'reps': e['reps'],
          'order': e['order']
        }).toList(),
      };

      http.Response response;
      if (isEditing) {
         // Try POST with method spoofing if PUT is blocked/405
         // Some server configurations block PUT/PATCH directly
         final bodyWithMethod = Map<String, dynamic>.from(body);
         bodyWithMethod['_method'] = 'PUT';

         response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
              'Accept': 'application/json',
            },
            body: jsonEncode(bodyWithMethod),
         );
         
         // If POST with _method also fails or isn't supported, we might try original PUT logic again
         // But let's assume this fixes the 405 issue common in some hosting environments
         if (response.statusCode == 405) {
            // Fallback to standard PUT if POST spoofing didn't work (unlikely to fix 405, but to be safe)
             response = await http.put(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${widget.token}',
                },
                body: jsonEncode(body),
             );
         }
      } else {
         response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode(body),
         );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${response.statusCode} - ${response.body}")));
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showAddExerciseDialog() {
    showDialog(
      context: context, 
      builder: (ctx) {
        List<Exercise> dialogExercises = List.from(_availableExercises);
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Adicionar Exercício"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar Exercício',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) async {
                        setStateDialog(() => isLoading = true);
                        try {
                           final uri = Uri.parse('https://finance-health-production.up.railway.app/api/exercises/${widget.userId}')
                               .replace(queryParameters: value.isNotEmpty ? {'search': value} : null);
                           
                           final response = await http.get(
                              uri,
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer ${widget.token}',
                              },
                           );

                           if (response.statusCode == 200) {
                              final List<dynamic> data = jsonDecode(response.body);
                              final exercises = data.map((json) => Exercise.fromJson(json)).toList();
                              setStateDialog(() {
                                dialogExercises = exercises;
                                isLoading = false;
                              });
                           } else {
                              setStateDialog(() => isLoading = false);
                           }
                        } catch (e) {
                           print('Erro search: $e');
                           setStateDialog(() => isLoading = false);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: dialogExercises.length,
                        itemBuilder: (context, index) {
                          final ex = dialogExercises[index];
                          return ListTile(
                            title: Text(ex.name),
                            subtitle: Text(ex.muscleGroup),
                            onTap: () {
                              _addExercise(ex);
                              Navigator.pop(ctx);
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Color(0xFFD81B60)),
                                    onPressed: () async {
                                       Navigator.pop(ctx);
                                       final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => CreateExercisePage(
                                            userId: widget.userId, 
                                            token: widget.token,
                                            exerciseToEdit: ex,
                                          )),
                                       );
                                       if (result == true) {
                                         // Re-fetch exercises
                                         _fetchExercises();
                                       } 
                                    }
                                ),
                                IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Color(0xFFC2185B)),
                                    onPressed: () {
                                       Navigator.pop(ctx);
                                       _confirmDeleteExercise(ex);
                                    }
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Criar Novo Exercício"),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateExercisePage(token: widget.token, userId: widget.userId)),
                    );
                    if (result == true) {
                      _fetchExercises();
                    }
                  },
                ),
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workoutToEdit != null ? 'Editar Treino' : 'Novo Treino')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Treino (ex: Treino A)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextFormField(
                controller: _observationController,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _defaultSetsController, decoration: const InputDecoration(labelText: 'Séries Padrão'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _defaultRepsController, decoration: const InputDecoration(labelText: 'Reps Padrão'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Exercícios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _showAddExerciseDialog, icon: const Icon(Icons.add_circle, color: Color(0xFFD81B60))),
                ],
              ),
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _selectedExercises.removeAt(oldIndex);
                      _selectedExercises.insert(newIndex, item);
                      // Update order
                      for(int i=0; i<_selectedExercises.length; i++) {
                         _selectedExercises[i]['order'] = i + 1;
                      }
                    });
                  },
                  children: [
                    for (int index = 0; index < _selectedExercises.length; index++)
                      ListTile(
                        key: ValueKey("${_selectedExercises[index]['id']}_$index"),
                        title: Text("${_selectedExercises[index]['name']}"),
                        subtitle: Text("${_selectedExercises[index]['sets']} séries x ${_selectedExercises[index]['reps']} reps"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFC2185B)),
                          onPressed: () => _removeExercise(index),
                        ),
                      )
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text("Salvar Treino"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
