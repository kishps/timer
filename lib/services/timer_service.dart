import 'dart:async';
import '../models/timer_config.dart';
import '../models/workout_template.dart';
import '../models/workout_interval.dart';
import '../models/interval_stat.dart';
import '../utils/audio_helper.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum TimerState {
  idle,
  running,
  paused,
  finished,
}

class TimerService {
  Timer? _timer;
  TimerState _state = TimerState.idle;
  int _currentTime = 0;
  int _currentIntervalIndex = 0;
  WorkoutInterval? _currentInterval;
  TimerConfig? _config;
  WorkoutTemplate? _template;
  List<WorkoutInterval> _intervals = [];
  bool _soundEnabled = true;
  bool _countdownSoundEnabled = true;
  int _countdownSeconds = 5;
  DateTime? _manualIntervalStartTime; // Время начала интервала без таймера
  DateTime? _currentIntervalStartTime; // Время начала текущего интервала

  // Статистика
  Map<String, int> _exercisesCompleted = {};
  Map<String, double> _exercisesWithWeight = {};
  int _totalRepetitions = 0;
  double _totalWeight = 0.0;
  List<IntervalStat> _intervalStats = []; // Статистика по каждому интервалу

  // Callbacks
  Function(int currentTime)? onTick;
  Function(WorkoutInterval? interval, int currentIndex, int totalIntervals)? onIntervalChange;
  Function()? onFinished;

  TimerState get state => _state;
  int get currentTime => _currentTime;
  WorkoutInterval? get currentInterval => _currentInterval;
  int get currentIntervalIndex => _currentIntervalIndex;
  int get totalIntervals => _intervals.length;
  WorkoutTemplate? get template => _template;
  TimerConfig? get config => _config;
  Map<String, int> get exercisesCompleted => Map.unmodifiable(_exercisesCompleted);
  Map<String, double> get exercisesWithWeight => Map.unmodifiable(_exercisesWithWeight);
  int get totalRepetitions => _totalRepetitions;
  double get totalWeight => _totalWeight;
  List<IntervalStat> get intervalStats => List.unmodifiable(_intervalStats);

  // Инициализация с шаблоном
  void initializeWithTemplate(
    WorkoutTemplate template, {
    bool soundEnabled = true,
    bool countdownSoundEnabled = true,
    int countdownSeconds = 5,
  }) {
    _template = template;
    _config = null;
    _soundEnabled = soundEnabled;
    _countdownSoundEnabled = countdownSoundEnabled;
    _countdownSeconds = countdownSeconds;
    _intervals = List.from(template.intervals)..sort((a, b) => a.order.compareTo(b.order));
    reset();
  }

  // Инициализация с конфигом (для обратной совместимости)
  void initialize(TimerConfig config) {
    _config = config;
    _template = null;
    _soundEnabled = config.soundEnabled;
    _countdownSoundEnabled = config.countdownSoundEnabled;
    _countdownSeconds = config.countdownSeconds;
    
    // Создаем интервалы из конфига
    _intervals = [];
    for (int i = 0; i < config.rounds; i++) {
      _intervals.add(WorkoutInterval(
        type: IntervalType.work,
        duration: config.workDuration,
        order: i * 2,
      ));
      if (i < config.rounds - 1) {
        _intervals.add(WorkoutInterval(
          type: IntervalType.rest,
          duration: config.restDuration,
          order: i * 2 + 1,
        ));
      }
    }
    reset();
  }

  void start() {
    if (_state == TimerState.running) return;
    if (_intervals.isEmpty) return;

    if (_state == TimerState.idle || _state == TimerState.finished) {
      _currentIntervalIndex = 0;
      _currentInterval = _intervals[0];
      _currentTime = _currentInterval!.duration ?? 0;
      _currentIntervalStartTime = DateTime.now();
      // Для ручных интервалов также устанавливаем время начала
      if (_currentInterval!.duration == null || _currentInterval!.duration == 0) {
        _manualIntervalStartTime = DateTime.now();
      } else {
        _manualIntervalStartTime = null;
      }
      _exercisesCompleted.clear();
      _exercisesWithWeight.clear();
      _totalRepetitions = 0;
      _totalWeight = 0.0;
      _intervalStats.clear();
      // Включаем wake lock для предотвращения засыпания экрана
      WakelockPlus.enable();
      // Воспроизводим звук начала тренировки
      if (_soundEnabled) {
        AudioHelper.playStartSound();
      }
      _playSoundIfEnabled();
      onIntervalChange?.call(_currentInterval, _currentIntervalIndex, _intervals.length);
    } else if (_state == TimerState.paused) {
      // Включаем wake lock при возобновлении
      WakelockPlus.enable();
      // При возобновлении обновляем время начала, если интервал был изменен
      if (_currentIntervalStartTime == null) {
        _currentIntervalStartTime = DateTime.now();
      }
      // Для ручных интервалов также обновляем время начала
      if (_currentInterval != null && (_currentInterval!.duration == null || _currentInterval!.duration == 0)) {
        if (_manualIntervalStartTime == null) {
          _manualIntervalStartTime = DateTime.now();
        }
      }
    }

    _state = TimerState.running;
    
    // Если текущий интервал без времени, убеждаемся что время начала установлено
    if (_currentInterval != null && (_currentInterval!.duration == null || _currentInterval!.duration == 0)) {
      if (_manualIntervalStartTime == null) {
        _manualIntervalStartTime = DateTime.now();
      }
    } else {
      _manualIntervalStartTime = null;
    }
    
    _startTimer();
  }

  void pause() {
    if (_state != TimerState.running) return;
    _timer?.cancel();
    _state = TimerState.paused;
    
    // Выключаем wake lock при паузе
    WakelockPlus.disable();
    
    // Для ручных интервалов сохраняем прошедшее время в currentTime
    if (isManualInterval && _manualIntervalStartTime != null) {
      _currentTime = getManualIntervalElapsedTime();
    }
    
    // Сохраняем статистику текущего интервала при паузе
    _saveCurrentIntervalStat();
  }

  void resume() {
    if (_state != TimerState.paused) return;
    _state = TimerState.running;
    
    // Если текущий интервал без времени, корректируем время начала с учетом паузы
    if (_currentInterval != null && (_currentInterval!.duration == null || _currentInterval!.duration == 0)) {
      if (_manualIntervalStartTime == null) {
        _manualIntervalStartTime = DateTime.now();
      } else {
        // Корректируем время начала, вычитая уже прошедшее время
        final elapsed = _currentTime; // Сохраненное время при паузе
        _manualIntervalStartTime = DateTime.now().subtract(Duration(seconds: elapsed));
      }
    } else {
      _manualIntervalStartTime = null;
    }
    
    // Восстанавливаем время начала интервала
    if (_currentIntervalStartTime == null) {
      _currentIntervalStartTime = DateTime.now();
    }
    
    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    _state = TimerState.idle;
    _currentTime = 0;
    _currentIntervalIndex = 0;
    _currentInterval = null;
    _manualIntervalStartTime = null;
    _currentIntervalStartTime = null;
    _exercisesCompleted.clear();
    _exercisesWithWeight.clear();
    _totalRepetitions = 0;
    _totalWeight = 0.0;
    _intervalStats.clear();
    // Выключаем wake lock при сбросе
    WakelockPlus.disable();
    onTick?.call(0);
  }

  void _startTimer() {
    _timer?.cancel();
    
    // Если интервал без времени (duration = null или 0), запускаем таймер для отслеживания прошедшего времени
    if (_currentInterval != null && (_currentInterval!.duration == null || _currentInterval!.duration == 0)) {
      // Убеждаемся, что время начала установлено
      if (_manualIntervalStartTime == null) {
        _manualIntervalStartTime = DateTime.now();
      }
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Обновляем прошедшее время для ручного интервала
        if (_manualIntervalStartTime != null) {
          final elapsed = DateTime.now().difference(_manualIntervalStartTime!).inSeconds;
          // Обновляем currentTime для совместимости
          _currentTime = elapsed;
          onTick?.call(elapsed);
        }
      });
      // Сразу вызываем onTick для начального отображения
      if (_manualIntervalStartTime != null) {
        final elapsed = DateTime.now().difference(_manualIntervalStartTime!).inSeconds;
        _currentTime = elapsed;
        onTick?.call(elapsed);
      }
      return;
    }
    
    // Обычный таймер для интервалов с временем
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime > 0) {
        _currentTime--;
        
        // Воспроизводим звук отсчета, если включен
        if (_countdownSoundEnabled && _currentTime <= _countdownSeconds && _currentTime > 0) {
          AudioHelper.playCountdown();
        }
        
        onTick?.call(_currentTime);
      } else {
        _handleIntervalComplete();
      }
    });
  }

  void _handleIntervalComplete() {
    // Для интервалов без времени не переключаемся автоматически
    if (_currentInterval != null && (_currentInterval!.duration == null || _currentInterval!.duration == 0)) {
      return;
    }
    
    // Сохраняем статистику упражнений для работы
    if (_currentInterval != null && _currentInterval!.type == IntervalType.work) {
      if (_currentInterval!.name != null && _currentInterval!.repetitions != null) {
        final name = _currentInterval!.name!;
        final reps = _currentInterval!.repetitions!;
        final weight = _currentInterval!.weight;
        
        _exercisesCompleted[name] = (_exercisesCompleted[name] ?? 0) + reps;
        _totalRepetitions += reps;
        
        // Сохраняем вес, если указан
        if (weight != null && weight > 0) {
          _exercisesWithWeight[name] = weight;
          _totalWeight += weight * reps;
        }
      }
    }

    // Переход к следующему интервалу
    _currentIntervalIndex++;
    
    if (_currentIntervalIndex >= _intervals.length) {
      // Тренировка завершена - сохраняем статистику последнего интервала перед завершением
      _saveCurrentIntervalStat();
      _finishWorkout();
    } else {
      // Сохраняем статистику для завершенного интервала перед переходом к следующему
      _saveCurrentIntervalStat();
      _currentInterval = _intervals[_currentIntervalIndex];
      _currentTime = _currentInterval!.duration ?? 0;
      _currentIntervalStartTime = DateTime.now();
      // Для ручных интервалов также устанавливаем время начала ДО запуска таймера
      if (_currentInterval!.duration == null || _currentInterval!.duration == 0) {
        _manualIntervalStartTime = DateTime.now();
        _currentTime = 0; // Для ручных интервалов начинаем с 0
      } else {
        _manualIntervalStartTime = null;
      }
      _playSoundIfEnabled();
      onIntervalChange?.call(_currentInterval, _currentIntervalIndex, _intervals.length);
      
      // Если интервал без времени и таймер запущен, запускаем таймер сразу
      if (_state == TimerState.running && (_currentInterval!.duration == null || _currentInterval!.duration == 0)) {
        _startTimer(); // Это обновит _currentTime и вызовет onTick
      } else {
        onTick?.call(_currentTime);
      }
    }
  }
  
  // Сохранение статистики текущего интервала
  void _saveCurrentIntervalStat() {
    if (_currentInterval == null) return;
    
    // Для ручных интервалов проверяем _manualIntervalStartTime, для обычных - _currentIntervalStartTime
    if (_currentInterval!.duration == null || _currentInterval!.duration == 0) {
      // Ручной интервал
      if (_manualIntervalStartTime == null) return;
    } else {
      // Обычный интервал
      if (_currentIntervalStartTime == null) return;
    }
    
    // Для ручных интервалов используем currentTime (который уже содержит прошедшее время)
    // Для обычных интервалов вычисляем разницу между запланированным и оставшимся временем
    final actualDuration = (_currentInterval!.duration == null || _currentInterval!.duration == 0)
        ? _currentTime  // Для ручных интервалов currentTime уже содержит прошедшее время
        : ((_currentInterval!.duration ?? 0) - _currentTime);
    
    // Проверяем, не сохранили ли мы уже статистику для этого интервала
    final existingIndex = _intervalStats.indexWhere(
      (stat) => stat.intervalIndex == _currentIntervalIndex,
    );
    
    final stat = IntervalStat(
      intervalIndex: _currentIntervalIndex,
      type: _currentInterval!.type,
      name: _currentInterval!.name,
      plannedDuration: _currentInterval!.duration ?? 0,
      actualDuration: actualDuration > 0 ? actualDuration : 0,
      repetitions: _currentInterval!.repetitions,
      weight: _currentInterval!.weight,
    );
    
    if (existingIndex >= 0) {
      _intervalStats[existingIndex] = stat;
    } else {
      _intervalStats.add(stat);
    }
  }
  
  // Получение прошедшего времени для ручного интервала
  int getManualIntervalElapsedTime() {
    if (_manualIntervalStartTime == null) return 0;
    return DateTime.now().difference(_manualIntervalStartTime!).inSeconds;
  }
  
  // Проверка, является ли текущий интервал ручным (без времени)
  bool get isManualInterval => _currentInterval != null && (_currentInterval!.duration == null || _currentInterval!.duration == 0);

  void _finishWorkout() {
    _timer?.cancel();
    
    // Выключаем wake lock при завершении тренировки
    WakelockPlus.disable();
    
    // Статистика последнего интервала уже сохранена в _handleIntervalComplete() или nextInterval()
    // Не сохраняем здесь, чтобы избежать дублирования
    
    // Воспроизводим звук завершения тренировки
    if (_soundEnabled) {
      AudioHelper.playEndSound();
    }
    
    _state = TimerState.finished;
    _currentTime = 0;
    _currentInterval = null;
    _currentIntervalStartTime = null;
    onTick?.call(0);
    onFinished?.call();
  }

  void _playSoundIfEnabled() {
    if (!_soundEnabled) return;
    
    // Воспроизводим разные звуки в зависимости от типа интервала
    if (_currentInterval != null) {
      switch (_currentInterval!.type) {
        case IntervalType.work:
          AudioHelper.playIntervalWork();
          break;
        case IntervalType.rest:
        case IntervalType.restBetweenSets:
          AudioHelper.playIntervalRest();
          break;
      }
    } else {
      // Если интервал не определен, используем обычный beep
      AudioHelper.playBeep();
    }
  }

  int getTotalDuration() {
    return _intervals.fold(0, (sum, interval) => sum + (interval.duration ?? 0));
  }

  int getElapsedTime() {
    int elapsed = 0;
    for (int i = 0; i < _currentIntervalIndex && i < _intervals.length; i++) {
      elapsed += _intervals[i].duration ?? 0;
    }
    // Если тренировка не завершена, добавляем время текущего интервала
    if (_currentIntervalIndex < _intervals.length) {
      final currentInterval = _intervals[_currentIntervalIndex];
      if (currentInterval.duration == null || currentInterval.duration == 0) {
        // Для ручного интервала добавляем прошедшее время
        elapsed += getManualIntervalElapsedTime();
      } else {
        elapsed += currentInterval.duration! - _currentTime;
      }
    }
    return elapsed;
  }

  int getRemainingTime() {
    // Для интервалов без времени считаем только время оставшихся интервалов с временем
    int remaining = 0;
    for (int i = _currentIntervalIndex + 1; i < _intervals.length; i++) {
      remaining += _intervals[i].duration ?? 0;
    }
    // Добавляем оставшееся время текущего интервала (если он не ручной)
    if (_currentIntervalIndex < _intervals.length && _currentInterval != null) {
      if (_currentInterval!.duration != null && _currentInterval!.duration! > 0) {
        remaining += _currentTime;
      }
    }
    return remaining;
  }

  // Получение количества завершенных интервалов работы
  int getCompletedWorkIntervalsCount() {
    int count = 0;
    // Считаем все завершенные интервалы работы (до текущего индекса)
    for (int i = 0; i < _currentIntervalIndex && i < _intervals.length; i++) {
      if (_intervals[i].type == IntervalType.work) {
        count++;
      }
    }
    return count;
  }

  // Получение общего количества интервалов работы
  int getTotalWorkIntervalsCount() {
    int count = 0;
    for (final interval in _intervals) {
      if (interval.type == IntervalType.work) {
        count++;
      }
    }
    return count;
  }

  double getProgress() {
    final totalWorkIntervals = getTotalWorkIntervalsCount();
    if (totalWorkIntervals == 0) return 0.0;
    final completedWorkIntervals = getCompletedWorkIntervalsCount();
    return completedWorkIntervals / totalWorkIntervals;
  }
  
  // Получение оставшихся повторений для каждого упражнения
  Map<String, int> getRemainingRepetitions() {
    final remaining = <String, int>{};
    
    // Проходим по всем оставшимся интервалам
    for (int i = _currentIntervalIndex; i < _intervals.length; i++) {
      final interval = _intervals[i];
      if (interval.type == IntervalType.work && 
          interval.name != null && 
          interval.repetitions != null) {
        final name = interval.name!;
        final reps = interval.repetitions!;
        remaining[name] = (remaining[name] ?? 0) + reps;
      }
    }
    
    return remaining;
  }
  
  // Получение следующих интервалов
  List<WorkoutInterval> getNextIntervals(int count) {
    final nextIntervals = <WorkoutInterval>[];
    final startIndex = _currentIntervalIndex + 1;
    
    for (int i = startIndex; i < _intervals.length && nextIntervals.length < count; i++) {
      nextIntervals.add(_intervals[i]);
    }
    
    return nextIntervals;
  }

  // Переход к следующему интервалу (ручной)
  void nextInterval() {
    if (_intervals.isEmpty) return;
    
    // Если это последний интервал, завершаем тренировку (статистика сохранится в _finishWorkout)
    if (_currentIntervalIndex >= _intervals.length - 1) {
      _finishWorkout();
      return;
    }
    
    // Сохраняем статистику для текущего интервала перед переходом (только если не последний)
    _saveCurrentIntervalStat();
    
    // Сохраняем статистику упражнений для работы
    if (_currentInterval != null && _currentInterval!.type == IntervalType.work) {
      if (_currentInterval!.name != null && _currentInterval!.repetitions != null) {
        final name = _currentInterval!.name!;
        final reps = _currentInterval!.repetitions!;
        final weight = _currentInterval!.weight;
        
        _exercisesCompleted[name] = (_exercisesCompleted[name] ?? 0) + reps;
        _totalRepetitions += reps;
        
        if (weight != null && weight > 0) {
          _exercisesWithWeight[name] = weight;
          _totalWeight += weight * reps;
        }
      }
    }
    
    _currentIntervalIndex++;
    _currentInterval = _intervals[_currentIntervalIndex];
    _currentTime = _currentInterval!.duration ?? 0;
    _currentIntervalStartTime = DateTime.now();
    // Для ручных интервалов также устанавливаем время начала ДО запуска таймера
    if (_currentInterval!.duration == null || _currentInterval!.duration == 0) {
      _manualIntervalStartTime = DateTime.now();
      _currentTime = 0; // Для ручных интервалов начинаем с 0
    } else {
      _manualIntervalStartTime = null;
    }
    
    _playSoundIfEnabled();
    onIntervalChange?.call(_currentInterval, _currentIntervalIndex, _intervals.length);
    
    // Если тренировка запущена, запускаем таймер для всех типов интервалов
    if (_state == TimerState.running) {
      _startTimer(); // Это обновит _currentTime и вызовет onTick
    } else {
      onTick?.call(_currentTime);
    }
  }
  
  // Переход к предыдущему интервалу
  void previousInterval() {
    if (_intervals.isEmpty) return;
    if (_currentIntervalIndex <= 0) return;
    
    // Убираем статистику текущего интервала (если он был выполнен)
    // Это упрощенная логика - в реальности может потребоваться более сложная обработка
    
    _currentIntervalIndex--;
    _currentInterval = _intervals[_currentIntervalIndex];
    _currentTime = _currentInterval!.duration ?? 0;
    _currentIntervalStartTime = DateTime.now();
    // Для ручных интервалов также устанавливаем время начала ДО запуска таймера
    if (_currentInterval!.duration == null || _currentInterval!.duration == 0) {
      _manualIntervalStartTime = DateTime.now();
      _currentTime = 0; // Для ручных интервалов начинаем с 0
    } else {
      _manualIntervalStartTime = null;
    }
    
    _playSoundIfEnabled();
    onIntervalChange?.call(_currentInterval, _currentIntervalIndex, _intervals.length);
    
    // Если тренировка запущена, запускаем таймер для всех типов интервалов
    if (_state == TimerState.running) {
      _startTimer(); // Это обновит _currentTime и вызовет onTick
    } else {
      onTick?.call(_currentTime);
    }
  }

  void dispose() {
    _timer?.cancel();
    // Выключаем wake lock при уничтожении сервиса
    WakelockPlus.disable();
  }
}
