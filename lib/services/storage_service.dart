import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_config.dart';
import '../models/workout_session.dart';
import '../models/workout_template.dart';
import '../models/exercise_history.dart';
import '../models/workout_interval.dart';
import '../models/interval_stat.dart';

class StorageService {
  static const String _configKey = 'timer_config';
  static const String _historyKey = 'workout_history';
  static const String _templatesKey = 'workout_templates';
  static const String _exerciseHistoryKey = 'exercise_history';

  // Сохранение конфигурации
  Future<void> saveConfig(TimerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(config.toJson());
    await prefs.setString(_configKey, json);
  }

  // Загрузка конфигурации
  Future<TimerConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);
    
    if (jsonString == null) {
      return TimerConfig.getDefault();
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TimerConfig.fromJson(json);
    } catch (e) {
      return TimerConfig.getDefault();
    }
  }

  // Сохранение сессии тренировки
  Future<void> saveSession(WorkoutSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.insert(0, session); // Добавляем в начало списка
    
    final jsonList = history.map((s) => s.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // Загрузка истории тренировок
  Future<List<WorkoutSession>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => WorkoutSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Обновление сессии
  Future<void> updateSession(WorkoutSession session) async {
    final history = await loadHistory();
    final index = history.indexWhere((s) => s.id == session.id);
    
    if (index != -1) {
      history[index] = session;
    } else {
      // Если сессия не найдена, добавляем её
      history.insert(0, session);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((s) => s.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // Удаление сессии
  Future<void> deleteSession(String sessionId) async {
    final history = await loadHistory();
    history.removeWhere((session) => session.id == sessionId);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((s) => s.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // Очистка всей истории
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // Сохранение шаблона тренировки
  Future<void> saveTemplate(WorkoutTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await loadTemplates();
    
    // Удаляем старый шаблон с таким же id, если есть
    templates.removeWhere((t) => t.id == template.id);
    templates.add(template);
    
    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_templatesKey, jsonEncode(jsonList));
  }

  // Загрузка всех шаблонов
  Future<List<WorkoutTemplate>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_templatesKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => WorkoutTemplate.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Загрузка шаблона по ID
  Future<WorkoutTemplate?> loadTemplate(String templateId) async {
    final templates = await loadTemplates();
    try {
      return templates.firstWhere((t) => t.id == templateId);
    } catch (e) {
      return null;
    }
  }

  // Удаление шаблона
  Future<void> deleteTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == templateId);
    
    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_templatesKey, jsonEncode(jsonList));
  }

  // Обновление даты последнего использования шаблона
  Future<void> updateTemplateLastUsed(String templateId) async {
    final template = await loadTemplate(templateId);
    if (template != null) {
      final updated = template.copyWith(lastUsed: DateTime.now());
      await saveTemplate(updated);
    }
  }

  // Получение статистики прогресса
  Future<Map<String, dynamic>> getProgressStats({
    DateTime? startDate,
    DateTime? endDate,
    String? templateId,
  }) async {
    final history = await loadHistory();
    var filteredHistory = history;

    if (startDate != null) {
      filteredHistory = filteredHistory
          .where((s) => s.dateTime.isAfter(startDate) || s.dateTime.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      filteredHistory = filteredHistory
          .where((s) => s.dateTime.isBefore(endDate) || s.dateTime.isAtSameMomentAs(endDate))
          .toList();
    }

    if (templateId != null) {
      filteredHistory = filteredHistory
          .where((s) => s.workoutTemplateId == templateId)
          .toList();
    }

    final totalWorkouts = filteredHistory.length;
    final totalDuration = filteredHistory.fold<int>(
      0,
      (sum, session) => sum + session.totalDuration,
    );
    final totalRepetitions = filteredHistory.fold<int>(
      0,
      (sum, session) => sum + (session.totalRepetitions ?? 0),
    );

    // Подсчет упражнений
    final Map<String, int> exercisesCount = {};
    for (final session in filteredHistory) {
      if (session.exercisesCompleted != null) {
        session.exercisesCompleted!.forEach((name, count) {
          exercisesCount[name] = (exercisesCount[name] ?? 0) + count;
        });
      }
    }

    final totalWeight = filteredHistory.fold<double>(
      0.0,
      (sum, session) => sum + (session.totalWeight ?? 0.0),
    );

    return {
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'totalRepetitions': totalRepetitions,
      'totalWeight': totalWeight,
      'exercisesCount': exercisesCount,
      'averageDuration': totalWorkouts > 0 ? totalDuration ~/ totalWorkouts : 0,
    };
  }

  /// Детальная статистика сравнения последних тренировок по шаблону.
  ///
  /// Возвращает:
  /// - lastSession, prevSession: WorkoutSession?
  /// - deltas: изменения по duration/reps/weight и плотности (на минуту)
  /// - exerciseDiffs: изменения по упражнениям (повторы/время/вес)
  /// - trendSeries: последние N сессий (дата + метрики)
  /// - prs: рекорды по упражнениям (макс вес, макс повторов за тренировку, макс тоннаж за тренировку)
  Future<Map<String, dynamic>> getTemplateComparisonStats(
    String templateId, {
    int lookback = 10,
  }) async {
    final history = await loadHistory();
    final sessions = history
        .where((s) => s.workoutTemplateId == templateId)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final WorkoutSession? lastSession = sessions.isNotEmpty ? sessions[0] : null;
    final WorkoutSession? prevSession = sessions.length >= 2 ? sessions[1] : null;

    double? pct(num? cur, num? prev) {
      if (prev == null || prev == 0) return null;
      if (cur == null) return null;
      return ((cur - prev) / prev) * 100.0;
    }

    int? deltaInt(int? cur, int? prev) => (cur == null || prev == null) ? null : cur - prev;
    double? deltaDouble(double? cur, double? prev) => (cur == null || prev == null) ? null : cur - prev;

    double? perMinDouble(double? value, int? seconds) {
      if (value == null) return null;
      if (seconds == null || seconds <= 0) return null;
      return value / (seconds / 60.0);
    }

    double? perMinInt(int? value, int? seconds) {
      if (value == null) return null;
      if (seconds == null || seconds <= 0) return null;
      return value / (seconds / 60.0);
    }

    Map<String, dynamic> makeExerciseAgg(WorkoutSession? s) {
      final stats = s?.intervalStats;
      if (stats == null || stats.isEmpty) return {};

      final Map<String, Map<String, dynamic>> byName = {};

      for (final IntervalStat st in stats) {
        if (st.type != IntervalType.work) continue;
        final name = (st.name ?? '').trim();
        if (name.isEmpty) continue;

        final entry = byName.putIfAbsent(name, () {
          return {
            'reps': 0,
            'timeSec': 0,
            'tonnage': 0.0,
            'maxWeight': null,
            'weightReps': 0,
            'weightSum': 0.0, // сумма веса * reps для avg
          };
        });

        final reps = st.repetitions ?? 0;
        final timeSec = st.actualDuration;
        entry['reps'] = (entry['reps'] as int) + reps;
        entry['timeSec'] = (entry['timeSec'] as int) + (timeSec > 0 ? timeSec : 0);

        final w = st.weight;
        if (w != null && w > 0 && reps > 0) {
          entry['tonnage'] = (entry['tonnage'] as double) + (w * reps);
          final currentMax = entry['maxWeight'] as double?;
          if (currentMax == null || w > currentMax) {
            entry['maxWeight'] = w;
          }
          entry['weightReps'] = (entry['weightReps'] as int) + reps;
          entry['weightSum'] = (entry['weightSum'] as double) + (w * reps);
        }
      }

      // нормализация: добавить avgWeight, убрать служебные поля где удобно
      final normalized = <String, Map<String, dynamic>>{};
      byName.forEach((name, m) {
        final weightReps = m['weightReps'] as int;
        final weightSum = m['weightSum'] as double;
        final avgWeight = weightReps > 0 ? (weightSum / weightReps) : null;
        normalized[name] = {
          'reps': m['reps'] as int,
          'timeSec': m['timeSec'] as int,
          'tonnage': (m['tonnage'] as double),
          'maxWeight': m['maxWeight'] as double?,
          'avgWeight': avgWeight,
        };
      });
      return normalized;
    }

    final lastAgg = makeExerciseAgg(lastSession);
    final prevAgg = makeExerciseAgg(prevSession);

    final exerciseNames = <String>{
      ...lastAgg.keys.cast<String>(),
      ...prevAgg.keys.cast<String>(),
    }.toList()
      ..sort();

    final exerciseDiffs = <Map<String, dynamic>>[];
    for (final name in exerciseNames) {
      final a = (lastAgg[name] as Map<String, dynamic>?) ?? const {};
      final b = (prevAgg[name] as Map<String, dynamic>?) ?? const {};

      final aReps = a['reps'] as int? ?? 0;
      final bReps = b['reps'] as int? ?? 0;
      final aTime = a['timeSec'] as int? ?? 0;
      final bTime = b['timeSec'] as int? ?? 0;
      final aTonnage = (a['tonnage'] as double?) ?? 0.0;
      final bTonnage = (b['tonnage'] as double?) ?? 0.0;
      final aMaxW = a['maxWeight'] as double?;
      final bMaxW = b['maxWeight'] as double?;

      final dReps = aReps - bReps;
      final dTime = aTime - bTime;
      final dTonnage = aTonnage - bTonnage;
      final dMaxW = (aMaxW == null || bMaxW == null) ? null : (aMaxW - bMaxW);

      // для сортировки: что сильнее изменилось (тоннаж/время/повторы)
      final score = dTonnage.abs() * 1.0 + dTime.abs() * 0.25 + dReps.abs() * 0.5;

      exerciseDiffs.add({
        'name': name,
        'last': a,
        'prev': b,
        'deltaReps': dReps,
        'deltaTimeSec': dTime,
        'deltaTonnage': dTonnage,
        'deltaMaxWeight': dMaxW,
        'score': score,
      });
    }
    exerciseDiffs.sort((x, y) => (y['score'] as double).compareTo(x['score'] as double));

    final trendSeries = sessions
        .take(lookback.clamp(1, 50))
        .map((s) => <String, dynamic>{
              'dateTime': s.dateTime.toIso8601String(),
              'totalDuration': s.totalDuration,
              'totalRepetitions': s.totalRepetitions ?? 0,
              'totalWeight': s.totalWeight ?? 0.0,
              'workoutName': s.workoutName,
              'id': s.id,
            })
        .toList();

    // PRs по упражнениям в рамках шаблона
    final Map<String, double> prMaxWeight = {};
    final Map<String, int> prMaxRepsPerWorkout = {};
    final Map<String, double> prMaxTonnagePerWorkout = {};

    for (final session in sessions) {
      final agg = makeExerciseAgg(session);
      agg.forEach((name, m) {
        final reps = m['reps'] as int? ?? 0;
        final tonnage = m['tonnage'] as double? ?? 0.0;
        final maxW = m['maxWeight'] as double?;

        final curReps = prMaxRepsPerWorkout[name] ?? 0;
        if (reps > curReps) prMaxRepsPerWorkout[name] = reps;

        final curTon = prMaxTonnagePerWorkout[name] ?? 0.0;
        if (tonnage > curTon) prMaxTonnagePerWorkout[name] = tonnage;

        if (maxW != null && maxW > 0) {
          final curW = prMaxWeight[name] ?? 0.0;
          if (maxW > curW) prMaxWeight[name] = maxW;
        }
      });
    }

    final lastDuration = lastSession?.totalDuration;
    final prevDuration = prevSession?.totalDuration;

    final lastReps = lastSession?.totalRepetitions;
    final prevReps = prevSession?.totalRepetitions;

    final lastWeight = lastSession?.totalWeight;
    final prevWeight = prevSession?.totalWeight;

    final lastWeightPerMin = perMinDouble(lastWeight, lastDuration);
    final prevWeightPerMin = perMinDouble(prevWeight, prevDuration);
    final lastRepsPerMin = perMinInt(lastReps, lastDuration);
    final prevRepsPerMin = perMinInt(prevReps, prevDuration);

    return {
      'templateId': templateId,
      'lastSession': lastSession,
      'prevSession': prevSession,
      'deltas': {
        'durationSec': {
          'last': lastDuration,
          'prev': prevDuration,
          'delta': deltaInt(lastDuration, prevDuration),
          'pct': pct(lastDuration, prevDuration),
        },
        'repetitions': {
          'last': lastReps,
          'prev': prevReps,
          'delta': deltaInt(lastReps, prevReps),
          'pct': pct(lastReps, prevReps),
        },
        'totalWeight': {
          'last': lastWeight,
          'prev': prevWeight,
          'delta': deltaDouble(lastWeight, prevWeight),
          'pct': pct(lastWeight, prevWeight),
        },
        'weightPerMin': {
          'last': lastWeightPerMin,
          'prev': prevWeightPerMin,
          'delta': deltaDouble(lastWeightPerMin, prevWeightPerMin),
          'pct': pct(lastWeightPerMin, prevWeightPerMin),
        },
        'repsPerMin': {
          'last': lastRepsPerMin,
          'prev': prevRepsPerMin,
          'delta': deltaDouble(lastRepsPerMin, prevRepsPerMin),
          'pct': pct(lastRepsPerMin, prevRepsPerMin),
        },
      },
      'exerciseDiffs': exerciseDiffs,
      'trendSeries': trendSeries,
      'prs': {
        'maxWeight': prMaxWeight,
        'maxRepsPerWorkout': prMaxRepsPerWorkout,
        'maxTonnagePerWorkout': prMaxTonnagePerWorkout,
      },
    };
  }

  // Получение истории упражнений
  Future<List<ExerciseHistory>> getExerciseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_exerciseHistoryKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ExerciseHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Получение списка названий всех упражнений
  Future<List<String>> getExerciseNames() async {
    final history = await getExerciseHistory();
    final names = history.map((e) => e.name).toSet().toList();
    names.sort();
    return names;
  }

  // Получение списка уникальных названий упражнений из всех шаблонов тренировок
  Future<List<String>> getAllExerciseNamesFromTemplates() async {
    final templates = await loadTemplates();
    final names = <String>{};
    
    for (final template in templates) {
      for (final interval in template.intervals) {
        if (interval.type == IntervalType.work && interval.name != null && interval.name!.isNotEmpty) {
          names.add(interval.name!);
        }
      }
    }
    
    final namesList = names.toList();
    namesList.sort();
    return namesList;
  }

  // Получение последних данных для упражнения
  Future<ExerciseHistory?> getLastExerciseData(String exerciseName, {double? weight}) async {
    final history = await getExerciseHistory();
    
    // Ищем последнее использование с таким же названием и весом
    ExerciseHistory? bestMatch;
    DateTime? bestDate;
    
    for (final entry in history) {
      if (entry.name == exerciseName) {
        // Если указан вес, ищем точное совпадение
        if (weight != null) {
          if (entry.lastWeight == weight) {
            if (bestDate == null || entry.lastUsed.isAfter(bestDate)) {
              bestMatch = entry;
              bestDate = entry.lastUsed;
            }
          }
        } else {
          // Если вес не указан, берем любое совпадение
          if (bestDate == null || entry.lastUsed.isAfter(bestDate)) {
            bestMatch = entry;
            bestDate = entry.lastUsed;
          }
        }
      }
    }
    
    return bestMatch;
  }

  // Обновление истории упражнений
  Future<void> updateExerciseHistory(String exerciseName, int repetitions, {double? weight}) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getExerciseHistory();
    
    // Удаляем старые записи с таким же названием и весом
    history.removeWhere((e) => 
      e.name == exerciseName && 
      ((weight == null && e.lastWeight == null) || e.lastWeight == weight)
    );
    
    // Добавляем новую запись
    history.add(ExerciseHistory(
      name: exerciseName,
      lastRepetitions: repetitions,
      lastWeight: weight,
      lastUsed: DateTime.now(),
    ));
    
    // Сортируем по дате использования
    history.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(_exerciseHistoryKey, jsonEncode(jsonList));
  }
}
