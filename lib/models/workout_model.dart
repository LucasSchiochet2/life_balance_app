class Exercise {
  final int id;
  final String name;
  final String description;
  final String muscleGroup;
  final String? photoUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    this.photoUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'muscle_group': muscleGroup,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}

class WorkoutExercise {
  final int id; // This might be the pivot ID or the exercise ID depending on context
  final int exerciseId;
  final String exerciseName; 
  final int sets;
  final int reps;
  final int order;
  final Exercise? exercise;

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.order,
    this.exercise,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'];
 
    final exerciseObj = json['exercise']; 

    String name = 'Exercise';
    if (exerciseObj != null && exerciseObj['name'] != null) {
      name = exerciseObj['name'];
    } else if (json['name'] != null) {
      name = json['name'];
    }

    int eId = 0;
    
    if (pivot != null && pivot['exercise_id'] != null) {
      eId = pivot['exercise_id'] is int ? pivot['exercise_id'] : int.tryParse(pivot['exercise_id'].toString()) ?? 0;
    } 
    else if (json['exercise_id'] != null) {
      eId = json['exercise_id'] is int ? json['exercise_id'] : int.tryParse(json['exercise_id'].toString()) ?? 0;
    } 
    else if (exerciseObj != null && exerciseObj['id'] != null) {
      eId = exerciseObj['id'] is int ? exerciseObj['id'] : int.tryParse(exerciseObj['id'].toString()) ?? 0;
    }
    else if (json['id'] != null && (json.containsKey('name') || json.containsKey('muscle_group') || json.containsKey('pivot'))) {
       eId = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
    }

    int sets = 0;
    int reps = 0;
    int order = 0;
    
    if (pivot != null) {
      sets = pivot['sets'] != null ? (pivot['sets'] is int ? pivot['sets'] : int.tryParse(pivot['sets'].toString()) ?? 0) : (json['sets'] ?? 0);
      reps = pivot['reps'] != null ? (pivot['reps'] is int ? pivot['reps'] : int.tryParse(pivot['reps'].toString()) ?? 0) : (json['reps'] ?? 0);
      order = pivot['order'] != null ? (pivot['order'] is int ? pivot['order'] : int.tryParse(pivot['order'].toString()) ?? 0) : (json['order'] ?? 0);
    } else {
      sets = json['sets'] is int ? json['sets'] : int.tryParse(json['sets']?.toString() ?? '0') ?? 0;
      reps = json['reps'] is int ? json['reps'] : int.tryParse(json['reps']?.toString() ?? '0') ?? 0;
      order = json['order'] is int ? json['order'] : int.tryParse(json['order']?.toString() ?? '0') ?? 0;
    }
    int id = 0;
    if (pivot != null && pivot['id'] != null) {
       id = pivot['id'] is int ? pivot['id'] : int.tryParse(pivot['id'].toString()) ?? 0;
    } else {
       id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    }

    return WorkoutExercise(
      id: id,
      exerciseId: eId,
      exerciseName: name,
      sets: sets,
      reps: reps,
      order: order,
      exercise: exerciseObj != null ? Exercise.fromJson(exerciseObj) : null,
    );
  }
}

class Workout {
  final int id;
  final String name;
  final String? description;
  final String? observation;
  final int? defaultSets;
  final int? defaultReps;
  final List<WorkoutExercise> exercises;

  Workout({
    required this.id,
    required this.name,
    this.description,
    this.observation,
    this.defaultSets,
    this.defaultReps,
    required this.exercises,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    var list = json['exercises'] as List? ?? [];
    List<WorkoutExercise> exerciseList = list.map((i) => WorkoutExercise.fromJson(i)).toList();

    return Workout(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      observation: json['observation'],
      defaultSets: json['default_sets'],
      defaultReps: json['default_reps'],
      exercises: exerciseList,
    );
  }
}

class ExerciseLog {
  final int id;
  final String date;
  final double weight;
  final int sets;
  final int reps;
  final String? observation;

  ExerciseLog({
    required this.id,
    required this.date,
    required this.weight,
    required this.sets,
    required this.reps,
    this.observation,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'] as int? ?? 0,
      date: json['date'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      observation: json['observation'],
    );
  }
}
