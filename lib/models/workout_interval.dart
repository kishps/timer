enum IntervalType {
  work,
  rest,
  restBetweenSets,
}

class WorkoutInterval {
  final IntervalType type;
  final int? duration; // в секундах (опционально)
  final String? name; // название упражнения (для работы)
  final int? repetitions; // количество повторений (для работы)
  final double? weight; // вес в кг (опционально)
  final int order; // порядок в последовательности

  WorkoutInterval({
    required this.type,
    this.duration,
    this.name,
    this.repetitions,
    this.weight,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'duration': duration,
      'name': name,
      'repetitions': repetitions,
      'weight': weight,
      'order': order,
    };
  }

  factory WorkoutInterval.fromJson(Map<String, dynamic> json) {
    return WorkoutInterval(
      type: IntervalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IntervalType.work,
      ),
      duration: json['duration'] as int?,
      name: json['name'] as String?,
      repetitions: json['repetitions'] as int?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      order: json['order'] as int,
    );
  }

  WorkoutInterval copyWith({
    IntervalType? type,
    Object? duration = _undefined,
    Object? name = _undefined,
    Object? repetitions = _undefined,
    Object? weight = _undefined,
    int? order,
  }) {
    return WorkoutInterval(
      type: type ?? this.type,
      duration: duration == _undefined ? this.duration : duration as int?,
      name: name == _undefined ? this.name : name as String?,
      repetitions: repetitions == _undefined ? this.repetitions : repetitions as int?,
      weight: weight == _undefined ? this.weight : weight as double?,
      order: order ?? this.order,
    );
  }
  
  static const Object _undefined = Object();

  String get displayName {
    if (type == IntervalType.work && name != null) {
      return name!;
    }
    switch (type) {
      case IntervalType.work:
        return 'Работа';
      case IntervalType.rest:
        return 'Отдых';
      case IntervalType.restBetweenSets:
        return 'Отдых между сетами';
    }
  }
}
