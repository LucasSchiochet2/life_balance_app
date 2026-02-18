import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workout_model.dart';
import 'log_exercise_page.dart';
import 'exercise_progress_page.dart'; // New import

class WorkoutDetailPage extends StatefulWidget {
  final int userId;
  final String token;
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.userId, required this.token, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  // To fetch logs or details if needed. But workout object already has exercises.
  
  void _logExercise(WorkoutExercise exercise) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LogExercisePage(
            userId: widget.userId,
            token: widget.token,
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
          )
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workout.name)),
      body: ListView.builder(
        itemCount: widget.workout.exercises.length,
        itemBuilder: (context, index) {
          final exercise = widget.workout.exercises[index];
          return ListTile(
            title: Text(exercise.exerciseName),
            subtitle: Text("${exercise.sets} séries x ${exercise.reps} reps"),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => ExerciseProgressPage(
                     userId: widget.userId,
                     token: widget.token,
                     exerciseId: exercise.exerciseId,
                     exerciseName: exercise.exerciseName,
                   ),
                 ),
               );
            },
            trailing: IconButton(
              icon: const Icon(Icons.show_chart, color: Color(0xFF02735E)), // Changed icon to indicate progress/logs
              onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => ExerciseProgressPage(
                       userId: widget.userId,
                       token: widget.token,
                       exerciseId: exercise.exerciseId,
                       exerciseName: exercise.exerciseName,
                     ),
                   ),
                 );
              },
            ),
          );
        },
      ),
    );
  }
}
