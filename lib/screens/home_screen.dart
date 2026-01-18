import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/timer_config.dart';
import '../models/workout_session.dart';
import '../models/workout_template.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
import '../utils/audio_helper.dart';
import '../widgets/timer_display.dart';
import '../widgets/control_buttons.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'workout_templates_screen.dart';
import 'workout_template_editor_screen.dart';
import 'progress_screen.dart';
import 'pre_workout_screen.dart';

class HomeScreen extends StatefulWidget {
  final WorkoutTemplate? selectedTemplate;

  const HomeScreen({super.key, this.selectedTemplate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TimerService _timerService = TimerService();
  final StorageService _storageService = StorageService();
  TimerConfig? _config;
  WorkoutTemplate? _currentTemplate;
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;
  bool _soundEnabled = true; // Используется для инициализации таймера

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.selectedTemplate != null) {
      _currentTemplate = widget.selectedTemplate;
      _loadConfigForTemplate();
    } else {
      _loadConfig();
      _loadTemplates();
    }
    _setupTimerCallbacks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Обновляем UI при возврате приложения из фона
    if (state == AppLifecycleState.resumed) {
      // Если тренировка активна, восстанавливаем wake lock и аудио
      if (_timerService.state == TimerState.running) {
        WakelockPlus.enable();
        AudioHelper.reinitialize();
      }
      setState(() {});
    }
  }

  Future<void> _loadTemplates() async {
    final templates = await _storageService.loadTemplates();
    // Сортировка по lastUsed (по убыванию, null в конце)
    templates.sort((a, b) {
      if (a.lastUsed == null && b.lastUsed == null) return 0;
      if (a.lastUsed == null) return 1;
      if (b.lastUsed == null) return -1;
      return b.lastUsed!.compareTo(a.lastUsed!);
    });
    setState(() {
      _templates = templates;
    });
  }

  Future<void> _loadConfigForTemplate() async {
    final config = await _storageService.loadConfig();
    setState(() {
      _soundEnabled = config.soundEnabled;
      _timerService.initializeWithTemplate(
        _currentTemplate!,
        soundEnabled: config.soundEnabled,
        countdownSoundEnabled: config.countdownSoundEnabled,
        countdownSeconds: config.countdownSeconds,
      );
      _isLoading = false;
    });
  }

  Future<void> _loadConfig() async {
    final config = await _storageService.loadConfig();
    setState(() {
      _config = config;
      _soundEnabled = config.soundEnabled;
      _timerService.initialize(config);
      _isLoading = false;
    });
  }

  void _setupTimerCallbacks() {
    _timerService.onTick = (time) {
      // Обновляем UI при каждом тике (включая ручные интервалы)
      if (mounted) {
        setState(() {});
      }
    };

    _timerService.onIntervalChange = (interval, currentIndex, totalIntervals) {
      HapticFeedback.mediumImpact();
      setState(() {});
    };

    _timerService.onFinished = () {
      _saveWorkoutSession();
      _showFinishedDialog();
      setState(() {});
    };
  }

  Future<void> _saveWorkoutSession() async {
    final template = _timerService.template;
    final exercisesCompleted = _timerService.exercisesCompleted;
    final exercisesWithWeight = _timerService.exercisesWithWeight;
    final totalRepetitions = _timerService.totalRepetitions;
    final totalWeight = _timerService.totalWeight;
    final intervalStats = _timerService.intervalStats;

    WorkoutSession session;
    
    if (template != null) {
      // Обновляем историю упражнений
      for (final entry in exercisesCompleted.entries) {
        final exerciseName = entry.key;
        final reps = entry.value;
        final weight = exercisesWithWeight[exerciseName];
        await _storageService.updateExerciseHistory(
          exerciseName,
          reps,
          weight: weight,
        );
      }
      
      // Сохраняем с шаблоном
      session = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
        totalDuration: _timerService.getElapsedTime(),
        rounds: template.intervals.length,
        workDuration: 0, // Не используется для шаблонов
        restDuration: 0, // Не используется для шаблонов
        workoutTemplateId: template.id,
        workoutName: template.name,
        exercisesCompleted: exercisesCompleted.isNotEmpty ? exercisesCompleted : null,
        totalRepetitions: totalRepetitions > 0 ? totalRepetitions : null,
        totalWeight: totalWeight > 0 ? totalWeight : null,
        exercisesWithWeight: exercisesWithWeight.isNotEmpty ? exercisesWithWeight : null,
        intervalStats: intervalStats.isNotEmpty ? intervalStats : null,
      );
    } else if (_config != null) {
      // Сохраняем со старой конфигурацией
      session = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
        totalDuration: _timerService.getElapsedTime(),
        rounds: _config!.rounds,
        workDuration: _config!.workDuration,
        restDuration: _config!.restDuration,
      );
    } else {
      return;
    }

    await _storageService.saveSession(session);
  }

  void _showFinishConfirmationDialog() {
    final template = _timerService.template;
    final totalRepetitions = _timerService.totalRepetitions;
    final totalWeight = _timerService.totalWeight;
    final exercisesCompleted = _timerService.exercisesCompleted;
    final elapsedTime = _timerService.getElapsedTime();
    final completedWorkIntervals = _timerService.getCompletedWorkIntervalsCount();
    final totalWorkIntervals = _timerService.getTotalWorkIntervalsCount();
    
    bool saveToHistory = true;

    String _formatTime(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Завершить тренировку?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статистика тренировки:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Время: ${_formatTime(elapsedTime)}'),
                if (template != null) ...[
                  Text('Интервалов работы: $completedWorkIntervals / $totalWorkIntervals'),
                  Text('Всего интервалов: ${_timerService.totalIntervals}'),
                ] else if (_config != null) ...[
                  Text('Раундов: ${_config!.rounds}'),
                ],
                if (totalRepetitions > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Всего повторений: $totalRepetitions',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
                if (totalWeight > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Общий вес: ${totalWeight.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
                if (exercisesCompleted.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Упражнения:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...exercisesCompleted.entries.map((entry) {
                    final weight = _timerService.exercisesWithWeight[entry.key];
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                      child: Text(
                        '${entry.key}: ${entry.value} повторений'
                        '${weight != null && weight > 0 ? ' × ${weight.toStringAsFixed(1)} кг' : ''}',
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Сохранить в истории'),
                  value: saveToHistory,
                  onChanged: (value) {
                    setDialogState(() {
                      saveToHistory = value ?? true;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (saveToHistory) {
                  _saveWorkoutSession();
                }
                _timerService.reset();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Завершить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishedDialog() {
    final template = _timerService.template;
    final totalRepetitions = _timerService.totalRepetitions;

    String message = 'Тренировка завершена!\n';
    if (template != null) {
      message += 'Выполнено интервалов: ${template.intervals.length}\n';
      if (totalRepetitions > 0) {
        message += 'Всего повторений: $totalRepetitions\n';
      }
    } else if (_config != null) {
      message += 'Выполнено раундов: ${_config!.rounds}\n';
    }
    message += 'Отличная работа!';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тренировка завершена!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _timerService.reset();
              setState(() {});
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startWorkout(WorkoutTemplate template) async {
    await _storageService.updateTemplateLastUsed(template.id);
    final config = await _storageService.loadConfig();
    setState(() {
      _currentTemplate = template;
      _soundEnabled = config.soundEnabled;
      _timerService.initializeWithTemplate(
        template,
        soundEnabled: config.soundEnabled,
        countdownSoundEnabled: config.countdownSoundEnabled,
        countdownSeconds: config.countdownSeconds,
      );
    });
    // Обновляем список тренировок для обновления сортировки
    await _loadTemplates();
  }

  Future<void> _navigateToTemplates() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutTemplatesScreen()),
    );

    if (result == true || result is WorkoutTemplate) {
      if (result is WorkoutTemplate) {
        await _startWorkout(result);
      } else {
        // Обновляем список после возврата из экрана тренировок
        await _loadTemplates();
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes мин ${secs > 0 ? '$secs сек' : ''}';
    }
    return '$secs сек';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'нед.' : 'нед.'} назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    if (result == true) {
      await _loadConfig();
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _navigateToProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final template = _timerService.template;
    final currentInterval = _timerService.currentInterval;

    return Scaffold(
      appBar: AppBar(
        title: Text(template?.name ?? 'Интервальный таймер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: _navigateToProgress,
            tooltip: 'Прогресс',
          ),
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: _navigateToTemplates,
            tooltip: 'Тренировки',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'История',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (template == null && _timerService.state == TimerState.idle)
                Expanded(
                  child: _templates.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет сохраненных тренировок',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Создайте свою первую тренировку',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const WorkoutTemplateEditorScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadTemplates();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Создать тренировку'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _templates.length,
                          itemBuilder: (context, index) {
                            final workoutTemplate = _templates[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                  child: const Icon(Icons.fitness_center),
                                ),
                                title: Text(
                                  workoutTemplate.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Длительность: ${_formatDuration(workoutTemplate.totalDuration)}',
                                    ),
                                    Text(
                                      'Интервалов: ${workoutTemplate.intervals.length} | '
                                      'Упражнений: ${workoutTemplate.totalWorkIntervals}',
                                    ),
                                    if (workoutTemplate.lastUsed != null)
                                      Text(
                                        'Последний запуск: ${_formatDate(workoutTemplate.lastUsed!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: const Icon(Icons.play_arrow, color: Colors.green),
                                isThreeLine: true,
                                onTap: () => _startWorkout(workoutTemplate),
                              ),
                            );
                          },
                        ),
                )
              else
                Expanded(
                  child: TimerDisplay(
                    currentTime: _timerService.currentTime,
                    currentInterval: currentInterval,
                    currentIntervalIndex: _timerService.currentIntervalIndex,
                    totalIntervals: _timerService.totalIntervals,
                    totalDuration: _timerService.getTotalDuration(),
                    elapsedTime: _timerService.getElapsedTime(),
                    progress: _timerService.getProgress(),
                    completedRepetitions: _timerService.exercisesCompleted,
                    remainingRepetitions: _timerService.getRemainingRepetitions(),
                    nextIntervals: _timerService.getNextIntervals(3),
                    totalElapsedTime: _timerService.getElapsedTime(),
                    totalRemainingTime: _timerService.getRemainingTime(),
                    isManualInterval: _timerService.isManualInterval,
                    manualElapsedTime: _timerService.isManualInterval
                        ? _timerService.currentTime
                        : null,
                    // Параметры для кнопок переключения интервалов
                    isPaused: _timerService.state == TimerState.paused,
                    canGoPrevious: _timerService.currentIntervalIndex > 0,
                    canGoNext: _timerService.currentIntervalIndex < _timerService.totalIntervals - 1,
                    onPreviousInterval: () {
                      _timerService.previousInterval();
                      setState(() {});
                    },
                    onNextInterval: () {
                      _timerService.nextInterval();
                      setState(() {});
                    },
                    // Все интервалы для графика на квадратном экране
                    allIntervals: _timerService.template?.intervals,
                  ),
                ),
              // Кнопка "Следующий" для ручных интервалов
              if (_timerService.isManualInterval && 
                  (_timerService.state == TimerState.running || _timerService.state == TimerState.paused))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _timerService.nextInterval();
                        setState(() {});
                      },
                      icon: const Icon(Icons.arrow_forward, size: 28),
                      label: const Text(
                        'СЛЕДУЮЩИЙ ИНТЕРВАЛ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Показываем кнопки управления только если есть выбранная тренировка или тренировка запущена
              if (template != null || _timerService.state != TimerState.idle)
                ControlButtons(
                  state: _timerService.state,
                  onStart: () async {
                    if (template == null && _config == null) {
                      _navigateToTemplates();
                      return;
                    }
                    
                    // Если есть шаблон, показываем экран предпросмотра
                    if (template != null && _timerService.state == TimerState.idle) {
                      final updatedTemplate = await Navigator.push<WorkoutTemplate>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreWorkoutScreen(template: template),
                        ),
                      );
                      
                      if (updatedTemplate != null) {
                        final config = await _storageService.loadConfig();
                        setState(() {
                          _currentTemplate = updatedTemplate;
                          _soundEnabled = config.soundEnabled;
                          _timerService.initializeWithTemplate(
                            updatedTemplate,
                            soundEnabled: config.soundEnabled,
                            countdownSoundEnabled: config.countdownSoundEnabled,
                            countdownSeconds: config.countdownSeconds,
                          );
                        });
                      } else {
                        return; // Пользователь отменил
                      }
                    }
                    
                    _timerService.start();
                    setState(() {});
                  },
                  onPause: () {
                    _timerService.pause();
                    setState(() {});
                  },
                  onResume: () {
                    _timerService.resume();
                    setState(() {});
                  },
                  onFinish: () {
                    _showFinishConfirmationDialog();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerService.dispose();
    super.dispose();
  }
}
