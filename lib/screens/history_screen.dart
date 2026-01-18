import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../models/interval_stat.dart';
import '../models/workout_interval.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;
  Set<String> _expandedSessions = {}; // ID развернутых сессий

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final sessions = await _storageService.loadHistory();
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: Text('Тренировка от ${session.formattedDate} будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteSession(session.id);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тренировка удалена')),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    if (_sessions.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить всю историю?'),
        content: const Text(
          'Все сохраненные тренировки будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearHistory();
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('История очищена')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        actions: [
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: 'Очистить всю историю',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'История пуста',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Завершите тренировку, чтобы она появилась здесь',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final isExpanded = _expandedSessions.contains(session.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          child: const Icon(Icons.fitness_center),
                        ),
                        title: Text(
                          session.workoutName ?? session.formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(session.formattedDate),
                            Text('Длительность: ${session.formattedDuration}'),
                            if (session.workoutName != null)
                              Text('Интервалов: ${session.rounds}'),
                            if (session.workoutName == null)
                              Text(
                                'Раундов: ${session.rounds} | '
                                'Работа: ${_formatSeconds(session.workDuration)} | '
                                'Отдых: ${_formatSeconds(session.restDuration)}',
                              ),
                            if (session.totalRepetitions != null &&
                                session.totalRepetitions! > 0)
                              Text(
                                'Всего повторений: ${session.totalRepetitions}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            if (session.totalWeight != null &&
                                session.totalWeight! > 0)
                              Text(
                                'Общий вес: ${session.totalWeight!.toStringAsFixed(1)} кг',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            if (session.exercisesCompleted != null &&
                                session.exercisesCompleted!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...session.exercisesCompleted!.entries.map((entry) {
                                final exerciseName = entry.key;
                                final reps = entry.value;
                                final weight = session.exercisesWithWeight?[exerciseName];
                                
                                String exerciseText = '  • $exerciseName: $reps';
                                if (weight != null && weight > 0) {
                                  exerciseText += ' × ${weight.toStringAsFixed(1)} кг';
                                }
                                
                                return Text(
                                  exerciseText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (session.intervalStats != null && 
                                session.intervalStats!.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedSessions.remove(session.id);
                                    } else {
                                      _expandedSessions.add(session.id);
                                    }
                                  });
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () => _deleteSession(session),
                            ),
                          ],
                        ),
                        children: session.intervalStats != null && 
                            session.intervalStats!.isNotEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Детальная статистика по интервалам:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...(session.intervalStats!..sort((a, b) => a.intervalIndex.compareTo(b.intervalIndex)))
                                          .map((stat) {
                                        return _buildIntervalStatCard(stat);
                                      }),
                                    ],
                                  ),
                                ),
                              ]
                            : [],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '$secs сек';
  }

  Widget _buildIntervalStatCard(IntervalStat stat) {
    String typeText;
    Color typeColor;
    IconData typeIcon;
    
    switch (stat.type) {
      case IntervalType.work:
        typeText = 'Работа';
        typeColor = Colors.red;
        typeIcon = Icons.fitness_center;
        break;
      case IntervalType.rest:
        typeText = 'Отдых';
        typeColor = Colors.green;
        typeIcon = Icons.pause_circle;
        break;
      case IntervalType.restBetweenSets:
        typeText = 'Отдых между сетами';
        typeColor = Colors.blue;
        typeIcon = Icons.timer;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Интервал ${stat.intervalIndex + 1}: $typeText',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (stat.name != null) ...[
              Text('Упражнение: ${stat.name}'),
              const SizedBox(height: 4),
            ],
            if (stat.repetitions != null) ...[
              Text('Повторений: ${stat.repetitions}'),
              const SizedBox(height: 4),
            ],
            if (stat.weight != null && stat.weight! > 0) ...[
              Text('Вес: ${stat.weight!.toStringAsFixed(1)} кг'),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stat.type == IntervalType.work 
                      ? 'Запланировано: ${_formatSeconds(stat.plannedDuration)}'
                      : stat.plannedDuration > 0
                          ? 'Запланировано: ${_formatSeconds(stat.plannedDuration)}'
                          : 'Без ограничения времени',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  stat.type == IntervalType.work
                      ? 'Выполнено: ${_formatSeconds(stat.actualDuration)}'
                      : 'Время отдыха: ${_formatSeconds(stat.actualDuration)}',
                  style: TextStyle(
                    color: stat.actualDuration > 0 ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (stat.plannedDuration == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Ручной режим',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
