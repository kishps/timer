class TimerConfig {
  final int workDuration; // в секундах
  final int restDuration; // в секундах
  final int rounds;
  final bool soundEnabled;
  final bool countdownSoundEnabled; // звук отсчета
  final int countdownSeconds; // за сколько секунд до конца начинать отсчет

  TimerConfig({
    required this.workDuration,
    required this.restDuration,
    required this.rounds,
    this.soundEnabled = true,
    this.countdownSoundEnabled = true,
    this.countdownSeconds = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'workDuration': workDuration,
      'restDuration': restDuration,
      'rounds': rounds,
      'soundEnabled': soundEnabled,
      'countdownSoundEnabled': countdownSoundEnabled,
      'countdownSeconds': countdownSeconds,
    };
  }

  factory TimerConfig.fromJson(Map<String, dynamic> json) {
    return TimerConfig(
      workDuration: json['workDuration'] as int,
      restDuration: json['restDuration'] as int,
      rounds: json['rounds'] as int,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      countdownSoundEnabled: json['countdownSoundEnabled'] as bool? ?? true,
      countdownSeconds: json['countdownSeconds'] as int? ?? 5,
    );
  }

  TimerConfig copyWith({
    int? workDuration,
    int? restDuration,
    int? rounds,
    bool? soundEnabled,
    bool? countdownSoundEnabled,
    int? countdownSeconds,
  }) {
    return TimerConfig(
      workDuration: workDuration ?? this.workDuration,
      restDuration: restDuration ?? this.restDuration,
      rounds: rounds ?? this.rounds,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      countdownSoundEnabled: countdownSoundEnabled ?? this.countdownSoundEnabled,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }

  static TimerConfig getDefault() {
    return TimerConfig(
      workDuration: 30, // 30 секунд работы
      restDuration: 10, // 10 секунд отдыха
      rounds: 5, // 5 раундов
      soundEnabled: true,
      countdownSoundEnabled: true,
      countdownSeconds: 5,
    );
  }
}
