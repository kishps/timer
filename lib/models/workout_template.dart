import 'workout_interval.dart';

class WorkoutTemplate {
  final String id;
  final String name;
  final List<WorkoutInterval> intervals;
  final int? restBetweenSets; // отдых между сетами в секундах
  final DateTime createdAt;
  final DateTime? lastUsed;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.intervals,
    this.restBetweenSets,
    required this.createdAt,
    this.lastUsed,
  });

  int get totalDuration {
    return intervals.fold(0, (sum, interval) => sum + (interval.duration ?? 0));
  }

  int get totalWorkIntervals {
    return intervals.where((i) => i.type == IntervalType.work).length;
  }

  int get totalRepetitions {
    return intervals
        .where((i) => i.type == IntervalType.work && i.repetitions != null)
        .fold(0, (sum, i) => sum + (i.repetitions ?? 0));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'intervals': intervals.map((i) => i.toJson()).toList(),
      'restBetweenSets': restBetweenSets,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      intervals: (json['intervals'] as List<dynamic>)
          .map((i) => WorkoutInterval.fromJson(i as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      restBetweenSets: json['restBetweenSets'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    List<WorkoutInterval>? intervals,
    int? restBetweenSets,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      intervals: intervals ?? this.intervals,
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
