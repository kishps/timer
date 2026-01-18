import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/workout_session.dart';
import '../models/workout_template.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final StorageService _storageService = StorageService();
  List<WorkoutSession> _sessions = [];
  List<WorkoutTemplate> _templates = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _storageService.loadHistory();
    final templates = await _storageService.loadTemplates();
    final stats = await _storageService.getProgressStats(
      templateId: _selectedTemplateId,
    );

    setState(() {
      _sessions = sessions;
      _templates = templates;
      _stats = stats;
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours ч ${minutes} мин';
    }
    return '$minutes мин';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс'),
        actions: [
          // Фильтр по тренировкам
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedTemplateId = value;
                _isLoading = true;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Все тренировки'),
              ),
              ..._templates.map((t) => PopupMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  )),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Общая статистика
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Общая статистика',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Выполнено тренировок',
                      '${_stats['totalWorkouts'] ?? 0}',
                      Icons.fitness_center,
                    ),
                    _buildStatRow(
                      'Общее время',
                      _formatDuration(_stats['totalDuration'] ?? 0),
                      Icons.timer,
                    ),
                    _buildStatRow(
                      'Средняя длительность',
                      _formatDuration(_stats['averageDuration'] ?? 0),
                      Icons.access_time,
                    ),
                    if ((_stats['totalRepetitions'] ?? 0) > 0)
                      _buildStatRow(
                        'Всего повторений',
                        '${_stats['totalRepetitions'] ?? 0}',
                        Icons.repeat,
                      ),
                    if ((_stats['totalWeight'] as double? ?? 0.0) > 0)
                      _buildStatRow(
                        'Общий поднятый вес',
                        '${((_stats['totalWeight'] as double?) ?? 0.0).toStringAsFixed(1)} кг',
                        Icons.fitness_center,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Статистика по упражнениям
            if ((_stats['exercisesCount'] as Map<String, int>?)?.isNotEmpty ?? false)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Упражнения',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(() {
                        final exercises = ((_stats['exercisesCount'] as Map<String, int>?) ?? {})
                            .entries
                            .toList();
                        exercises.sort((a, b) => b.value.compareTo(a.value));
                        return exercises
                            .take(10)
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      Text(
                                        '${entry.value}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList();
                      })(),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // График тренировок по дням
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Активность по дням',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWeeklyChart(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Последние тренировки
            const Text(
              'Последние тренировки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._sessions.take(5).map((session) => Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: const Icon(Icons.fitness_center),
                    ),
                    title: Text(
                      session.workoutName ?? 'Тренировка',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.formattedDate),
                        Text('Длительность: ${session.formattedDuration}'),
                        if (session.totalRepetitions != null &&
                            session.totalRepetitions! > 0)
                          Text(
                            'Повторений: ${session.totalRepetitions}',
                          ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final now = DateTime.now();
    final weekData = <String, int>{};

    // Инициализируем последние 7 дней
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('dd.MM').format(date);
      weekData[key] = 0;
    }

    // Подсчитываем тренировки по дням
    for (final session in _sessions) {
      final daysDiff = now.difference(session.dateTime).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        final key = DateFormat('dd.MM').format(session.dateTime);
        weekData[key] = (weekData[key] ?? 0) + 1;
      }
    }

    final maxCount = weekData.values.isEmpty
        ? 1
        : weekData.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekData.entries.map((entry) {
          final height = maxCount > 0 ? (entry.value / maxCount) * 120 : 0.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: entry.value > 0
                      ? Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
