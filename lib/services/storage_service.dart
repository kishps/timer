import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_config.dart';
import '../models/workout_session.dart';
import '../models/workout_template.dart';
import '../models/exercise_history.dart';
import '../models/workout_interval.dart';

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
