import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workout_model.dart';
import 'create_workout_page.dart';
import 'workout_detail_page.dart'; // To be created

class WorkoutListPage extends StatefulWidget {
  final int userId;
  final String token;

  const WorkoutListPage({super.key, required this.userId, required this.token});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends State<WorkoutListPage> {
  List<Workout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://finance-health-production.up.railway.app/api/workouts/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _workouts = data.map((json) => Workout.fromJson(json)).toList();
        });
      } else {
        // Handle error
      }
    } catch (e) {
      print("Error fetching workouts: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Treinos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateWorkoutPage(userId: widget.userId, token: widget.token)),
          );
          if (result == true) _fetchWorkouts();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _workouts.length,
            itemBuilder: (context, index) {
              final workout = _workouts[index];
              return Card(
                child: ListTile(
                  title: Text(workout.name),
                  subtitle: Text(workout.description ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton(
                         icon: const Icon(Icons.edit, color: Color(0xFF02735E)),
                         onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateWorkoutPage(
                                userId: widget.userId, 
                                token: widget.token,
                                workoutToEdit: workout,
                              )),
                            );
                            if (result == true) {
                               // Assuming the API updates the list or returns the updated object, we refresh.
                               _fetchWorkouts();
                            }
                         }
                       ),
                       IconButton(
                         icon: const Icon(Icons.delete, color: Color(0xFFF27405)),
                         onPressed: () => _confirmDelete(workout),
                       ),
                       const Icon(Icons.arrow_forward),
                    ],
                  ),
                  onTap: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WorkoutDetailPage(userId: widget.userId, token: widget.token, workout: workout)),
                     );
                  },
                ),
              );
            },
          ),
    );
  }

  Future<void> _confirmDelete(Workout workout) async {
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: Text("Deseja realmente excluir o treino '${workout.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Excluir", style: TextStyle(color: Color(0xFFF27405)))),
        ],
      )
    );

    if (confirm == true) {
      await _deleteWorkout(workout.id);
    }
  }

  Future<void> _deleteWorkout(int workoutId) async {
     try {
       final response = await http.delete(
         Uri.parse('https://finance-health-production.up.railway.app/api/workouts/${widget.userId}/$workoutId'),
         headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
       );

       if (response.statusCode == 200 || response.statusCode == 204) {
          _fetchWorkouts();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Treino excluído com sucesso")));
       } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao excluir: ${response.statusCode} - ${response.body}")));
       }
     } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
     }
  }
}
