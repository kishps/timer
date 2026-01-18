import 'package:intl/intl.dart';
import 'interval_stat.dart';

class WorkoutSession {
  final String id;
  final DateTime dateTime;
  final int totalDuration; // в секундах
  final int rounds;
  final int workDuration;
  final int restDuration;
  
  // Новые поля
  final String? workoutTemplateId;
  final String? workoutName;
  final Map<String, int>? exercisesCompleted; // название упражнения -> количество
  final int? totalRepetitions;
  final double? totalWeight; // общий поднятый вес (повторения × вес)
  final Map<String, double>? exercisesWithWeight; // название упражнения -> вес
  final List<IntervalStat>? intervalStats; // Статистика по каждому интервалу

  WorkoutSession({
    required this.id,
    required this.dateTime,
    required this.totalDuration,
    required this.rounds,
    required this.workDuration,
    required this.restDuration,
    this.workoutTemplateId,
    this.workoutName,
    this.exercisesCompleted,
    this.totalRepetitions,
    this.totalWeight,
    this.exercisesWithWeight,
    this.intervalStats,
  });

  String get formattedDate {
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  String get formattedDuration {
    final minutes = totalDuration ~/ 60;
    final seconds = totalDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'totalDuration': totalDuration,
      'rounds': rounds,
      'workDuration': workDuration,
      'restDuration': restDuration,
      'workoutTemplateId': workoutTemplateId,
      'workoutName': workoutName,
      'exercisesCompleted': exercisesCompleted,
      'totalRepetitions': totalRepetitions,
      'totalWeight': totalWeight,
      'exercisesWithWeight': exercisesWithWeight,
      'intervalStats': intervalStats?.map((stat) => stat.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    Map<String, int>? exercisesCompleted;
    if (json['exercisesCompleted'] != null) {
      exercisesCompleted = Map<String, int>.from(
        (json['exercisesCompleted'] as Map).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      );
    }

    Map<String, double>? exercisesWithWeight;
    if (json['exercisesWithWeight'] != null) {
      exercisesWithWeight = Map<String, double>.from(
        (json['exercisesWithWeight'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      );
    }

    List<IntervalStat>? intervalStats;
    if (json['intervalStats'] != null) {
      intervalStats = (json['intervalStats'] as List)
          .map((item) => IntervalStat.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return WorkoutSession(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      totalDuration: json['totalDuration'] as int,
      rounds: json['rounds'] as int,
      workDuration: json['workDuration'] as int,
      restDuration: json['restDuration'] as int,
      workoutTemplateId: json['workoutTemplateId'] as String?,
      workoutName: json['workoutName'] as String?,
      exercisesCompleted: exercisesCompleted,
      totalRepetitions: json['totalRepetitions'] as int?,
      totalWeight: json['totalWeight'] != null ? (json['totalWeight'] as num).toDouble() : null,
      exercisesWithWeight: exercisesWithWeight,
      intervalStats: intervalStats,
    );
  }
}
