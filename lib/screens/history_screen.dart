import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/workout_session.dart';
import '../models/interval_stat.dart';
import '../models/workout_interval.dart';
import '../services/storage_service.dart';
import '../utils/web_file_helper.dart';
import '../utils/io_file_helper.dart';
import '../widgets/empty_state.dart';
import '../widgets/workout_navigator_bar.dart';

import 'dart:typed_data';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;
  final Set<String> _expandedSessions = {}; // ID развернутых сессий

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
          if (_sessions.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _importWorkouts,
              tooltip: 'Импорт тренировок',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportWorkouts,
              tooltip: 'Экспорт тренировок',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: 'Очистить всю историю',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const WorkoutNavigatorBar(),
                Expanded(
                  child: _sessions.isEmpty
                      ? const EmptyState(
                          icon: Icons.history,
                          title: 'История пуста',
                          description: 'Завершите тренировку, чтобы она появилась здесь.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            final isExpanded = _expandedSessions.contains(session.id);
                            final cs = Theme.of(context).colorScheme;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primary.withValues(alpha: 0.15),
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
                                            color: cs.onSurfaceVariant,
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
                                      color: cs.error,
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
                                              _buildIntervalStatsTable(session),
                                            ],
                                          ),
                                        ),
                                      ]
                                    : [],
                              ),
                            );
                          },
                        ),
                ),
              ],
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

  Widget _buildIntervalStatsTable(WorkoutSession session) {
    final sortedStats = List<IntervalStat>.from(session.intervalStats ?? [])
      ..sort((a, b) => a.intervalIndex.compareTo(b.intervalIndex));

    if (sortedStats.isEmpty) {
      return const Text('Нет данных об интервалах');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 60,
        columns: const [
          DataColumn(label: Text('№', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Тип / Упражнение', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Повторения', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Вес (кг)', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Запланировано', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Выполнено', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Действия', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: sortedStats.map((stat) {
          String typeText;
          Color typeColor;
          
          switch (stat.type) {
            case IntervalType.work:
              typeText = 'Работа';
              typeColor = Colors.red;
              break;
            case IntervalType.rest:
              typeText = 'Отдых';
              typeColor = Colors.green;
              break;
            case IntervalType.restBetweenSets:
              typeText = 'Отдых между сетами';
              typeColor = Colors.blue;
              break;
          }

          String plannedText = stat.plannedDuration > 0 
              ? _formatSeconds(stat.plannedDuration)
              : stat.type == IntervalType.work ? 'Ручной' : '—';

          // Объединяем тип и упражнение в одну ячейку
          String combinedTypeExercise;
          if (stat.type == IntervalType.work && stat.name != null && stat.name!.isNotEmpty) {
            combinedTypeExercise = '$typeText: ${stat.name}';
          } else {
            combinedTypeExercise = typeText;
          }

          return DataRow(
            cells: [
              DataCell(Text('${stat.intervalIndex + 1}')),
              DataCell(
                Text(
                  combinedTypeExercise,
                  style: TextStyle(color: typeColor, fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(stat.repetitions?.toString() ?? '—')),
              DataCell(Text(
                stat.weight != null && stat.weight! > 0 
                    ? stat.weight!.toStringAsFixed(1) 
                    : '—',
              )),
              DataCell(Text(plannedText)),
              DataCell(
                Text(
                  _formatSeconds(stat.actualDuration),
                  style: TextStyle(
                    color: stat.actualDuration > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.blue,
                  onPressed: () => _showEditIntervalDialog(session, stat),
                  tooltip: 'Редактировать',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showEditIntervalDialog(WorkoutSession session, IntervalStat stat) async {
    final statIndex = session.intervalStats?.indexWhere((s) => s.intervalIndex == stat.intervalIndex) ?? -1;
    if (statIndex == -1) return;

    final nameController = TextEditingController(text: stat.name ?? '');
    final repetitionsController = TextEditingController(text: stat.repetitions?.toString() ?? '');
    final weightController = TextEditingController(text: stat.weight?.toStringAsFixed(1) ?? '');
    final durationController = TextEditingController(text: (stat.actualDuration ~/ 60).toString());
    final durationSecondsController = TextEditingController(text: (stat.actualDuration % 60).toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать интервал ${stat.intervalIndex + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stat.type == IntervalType.work)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название упражнения',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (stat.type == IntervalType.work) const SizedBox(height: 16),
              if (stat.type == IntervalType.work)
                TextField(
                  controller: repetitionsController,
                  decoration: const InputDecoration(
                    labelText: 'Повторения',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              if (stat.type == IntervalType.work) const SizedBox(height: 16),
              if (stat.type == IntervalType.work)
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Вес (кг)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Минуты',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: durationSecondsController,
                      decoration: const InputDecoration(
                        labelText: 'Секунды',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim().isEmpty ? null : nameController.text.trim();
              final repetitions = repetitionsController.text.trim().isEmpty 
                  ? null 
                  : int.tryParse(repetitionsController.text.trim());
              final weight = weightController.text.trim().isEmpty 
                  ? null 
                  : double.tryParse(weightController.text.trim().replaceAll(',', '.'));
              final minutes = int.tryParse(durationController.text.trim()) ?? 0;
              final seconds = int.tryParse(durationSecondsController.text.trim()) ?? 0;
              final actualDuration = minutes * 60 + seconds;

              final updatedStat = stat.copyWith(
                name: name,
                repetitions: repetitions,
                weight: weight,
                actualDuration: actualDuration,
              );

              final updatedStats = List<IntervalStat>.from(session.intervalStats ?? []);
              updatedStats[statIndex] = updatedStat;

              final updatedSession = session.copyWith(intervalStats: updatedStats);
              await _storageService.updateSession(updatedSession);
              await _loadHistory();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Интервал обновлен')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportWorkouts() async {
    try {
      final sessions = await _storageService.loadHistory();
      final exportData = {
        'workouts': sessions.map((s) => s.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = 'workouts_export_${DateTime.now().millisecondsSinceEpoch}.json';

      final bytes = utf8.encode(jsonString);
      final bytesList = Uint8List.fromList(bytes);

      if (kIsWeb) {
        // Для веб используем специальную функцию
        downloadFileWeb(fileName, bytesList);
      } else {
        if (isMobilePlatform()) {
          // Для Android и iOS нужно передавать байты
          await FilePicker.platform.saveFile(
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['json'],
            bytes: bytesList,
          );
        } else {
          // Для десктоп платформ (Windows, Linux, macOS) используем путь
          final path = await FilePicker.platform.saveFile(
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['json'],
          );

          if (path != null) {
            await writeStringToFile(path, jsonString);
          } else {
            return; // Пользователь отменил сохранение
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тренировки экспортированы')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    }
  }

  Future<void> _importWorkouts() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      String jsonString;
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) return;
        jsonString = utf8.decode(bytes);
      } else {
        final path = result.files.single.path;
        if (path == null) return;
        jsonString = await readStringFromFile(path);
      }

      final decoded = jsonDecode(jsonString);
      
      List<dynamic> workoutsJson;
      if (decoded is Map<String, dynamic>) {
        // Новый формат с метаданными
        if (decoded.containsKey('workouts')) {
          workoutsJson = decoded['workouts'] as List<dynamic>;
        } else {
          throw Exception('Неверный формат файла: отсутствует поле "workouts"');
        }
      } else if (decoded is List) {
        // Поддержка старого формата - просто массив
        workoutsJson = decoded;
      } else {
        throw Exception('Неверный формат файла');
      }

      final importedSessions = workoutsJson
          .map((json) => WorkoutSession.fromJson(json as Map<String, dynamic>))
          .toList();

      final existingSessions = await _storageService.loadHistory();
      final existingIds = existingSessions.map((s) => s.id).toSet();

      int updatedCount = 0;
      int addedCount = 0;

      for (final importedSession in importedSessions) {
        if (existingIds.contains(importedSession.id)) {
          await _storageService.updateSession(importedSession);
          updatedCount++;
        } else {
          await _storageService.saveSession(importedSession);
          addedCount++;
        }
      }

      await _loadHistory();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Импорт завершен'),
            content: Text(
              'Обновлено тренировок: $updatedCount\n'
              'Добавлено новых тренировок: $addedCount',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
  }
}
