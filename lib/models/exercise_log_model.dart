class ExerciseLog {
  final int id;
  final int userId;
  final int exerciseId;
  final DateTime date;
  final double weight;
  final int reps;
  final int sets;
  final double intensity;
  final String? observation;
  final DateTime createdAt;

  ExerciseLog({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.date,
    required this.weight,
    required this.reps,
    required this.sets,
    this.intensity = 0.0,
    this.observation,
    required this.createdAt,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      exerciseId: json['exercise_id'] is int ? json['exercise_id'] : int.parse(json['exercise_id'].toString()),
      date: DateTime.parse(json['date']),
      weight: json['weight'] is double ? json['weight'] : double.parse(json['weight'].toString()),
      reps: json['reps'] is int ? json['reps'] : int.parse(json['reps'].toString()),
      sets: json['sets'] is int ? json['sets'] : int.parse(json['sets'].toString()),
      intensity: json['intensity'] != null 
          ? (json['intensity'] is double ? json['intensity'] : double.parse(json['intensity'].toString()))
          : 0.0,
      observation: json['observation'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
