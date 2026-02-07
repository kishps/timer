import 'workout_interval.dart';

class IntervalStat {
  final int intervalIndex; // Индекс интервала в последовательности
  final IntervalType type; // Тип интервала
  final String? name; // Название упражнения (для работы)
  final int plannedDuration; // Запланированная длительность (0 для ручных)
  final int actualDuration; // Реальное время выполнения в секундах
  final int? repetitions; // Количество повторений
  final double? weight; // Вес (если указан)

  IntervalStat({
    required this.intervalIndex,
    required this.type,
    this.name,
    required this.plannedDuration,
    required this.actualDuration,
    this.repetitions,
    this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'intervalIndex': intervalIndex,
      'type': type.name,
      'name': name,
      'plannedDuration': plannedDuration,
      'actualDuration': actualDuration,
      'repetitions': repetitions,
      'weight': weight,
    };
  }

  factory IntervalStat.fromJson(Map<String, dynamic> json) {
    return IntervalStat(
      intervalIndex: json['intervalIndex'] as int,
      type: IntervalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IntervalType.work,
      ),
      name: json['name'] as String?,
      plannedDuration: json['plannedDuration'] as int,
      actualDuration: json['actualDuration'] as int,
      repetitions: json['repetitions'] as int?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
    );
  }

  IntervalStat copyWith({
    int? intervalIndex,
    IntervalType? type,
    Object? name = _undefined,
    int? plannedDuration,
    int? actualDuration,
    Object? repetitions = _undefined,
    Object? weight = _undefined,
  }) {
    return IntervalStat(
      intervalIndex: intervalIndex ?? this.intervalIndex,
      type: type ?? this.type,
      name: name == _undefined ? this.name : name as String?,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      repetitions: repetitions == _undefined ? this.repetitions : repetitions as int?,
      weight: weight == _undefined ? this.weight : weight as double?,
    );
  }

  static const Object _undefined = Object();
}
