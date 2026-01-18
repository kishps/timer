class ExerciseHistory {
  final String name;
  final int lastRepetitions;
  final double? lastWeight;
  final DateTime lastUsed;

  ExerciseHistory({
    required this.name,
    required this.lastRepetitions,
    this.lastWeight,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastRepetitions': lastRepetitions,
      'lastWeight': lastWeight,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) {
    return ExerciseHistory(
      name: json['name'] as String,
      lastRepetitions: json['lastRepetitions'] as int,
      lastWeight: json['lastWeight'] != null ? (json['lastWeight'] as num).toDouble() : null,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  ExerciseHistory copyWith({
    String? name,
    int? lastRepetitions,
    double? lastWeight,
    DateTime? lastUsed,
  }) {
    return ExerciseHistory(
      name: name ?? this.name,
      lastRepetitions: lastRepetitions ?? this.lastRepetitions,
      lastWeight: lastWeight ?? this.lastWeight,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
