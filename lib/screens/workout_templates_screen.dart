import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/workout_template.dart';
import '../services/storage_service.dart';
import 'workout_template_editor_screen.dart';
import 'home_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/timer_service_scope.dart';
import '../widgets/workout_navigator_bar.dart';
import '../utils/web_file_helper.dart';
import '../utils/io_file_helper.dart';

class WorkoutTemplatesScreen extends StatefulWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  State<WorkoutTemplatesScreen> createState() => _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState extends State<WorkoutTemplatesScreen> {
  final StorageService _storageService = StorageService();
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await _storageService.loadTemplates();
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
  }

  Future<void> _deleteTemplate(WorkoutTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: Text('Тренировка "${template.name}" будет удалена.'),
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
      await _storageService.deleteTemplate(template.id);
      await _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тренировка удалена')),
        );
      }
    }
  }

  Future<void> _editTemplate(WorkoutTemplate template) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTemplateEditorScreen(template: template),
      ),
    );

    if (result == true) {
      await _loadTemplates();
    }
  }

  Future<void> _createTemplate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutTemplateEditorScreen(),
      ),
    );

    if (result == true) {
      await _loadTemplates();
    }
  }

  Future<void> _startWorkout(WorkoutTemplate template) async {
    await _storageService.updateTemplateLastUsed(template.id);
    if (mounted) {
      final timerService = TimerServiceScope.of(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(selectedTemplate: template, timerService: timerService),
        ),
      );
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

  Future<void> _exportTemplates() async {
    try {
      final templates = await _storageService.loadTemplates();
      final exportData = {
        'templates': templates.map((t) => t.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = 'templates_export_${DateTime.now().millisecondsSinceEpoch}.json';

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

  Future<void> _importTemplates() async {
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
      
      List<dynamic> templatesJson;
      if (decoded is Map<String, dynamic>) {
        // Новый формат с метаданными
        if (decoded.containsKey('templates')) {
          templatesJson = decoded['templates'] as List<dynamic>;
        } else {
          throw Exception('Неверный формат файла: отсутствует поле "templates"');
        }
      } else if (decoded is List) {
        // Поддержка старого формата - просто массив
        templatesJson = decoded;
      } else {
        throw Exception('Неверный формат файла');
      }

      final importedTemplates = <WorkoutTemplate>[];
      for (final json in templatesJson) {
        try {
          final template = WorkoutTemplate.fromJson(json as Map<String, dynamic>);
          importedTemplates.add(template);
        } catch (e) {
          // Пропускаем некорректные шаблоны, но продолжаем импорт остальных
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка при импорте шаблона: $e')),
            );
          }
        }
      }

      if (importedTemplates.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось импортировать ни одного шаблона')),
          );
        }
        return;
      }

      final existingTemplates = await _storageService.loadTemplates();
      final existingIds = existingTemplates.map((t) => t.id).toSet();

      int updatedCount = 0;
      int addedCount = 0;

      for (final importedTemplate in importedTemplates) {
        if (existingIds.contains(importedTemplate.id)) {
          await _storageService.saveTemplate(importedTemplate);
          updatedCount++;
        } else {
          await _storageService.saveTemplate(importedTemplate);
          addedCount++;
        }
      }

      await _loadTemplates();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _importTemplates,
            tooltip: 'Импортировать тренировки',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTemplates,
            tooltip: 'Экспортировать тренировки',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTemplate,
            tooltip: 'Создать тренировку',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const WorkoutNavigatorBar(),
                Expanded(
                  child: _templates.isEmpty
                      ? EmptyState(
                          icon: Icons.fitness_center,
                          title: 'Нет тренировок',
                          description: 'Создайте шаблон, чтобы запускать тренировки быстро.',
                          action: ElevatedButton.icon(
                            onPressed: _createTemplate,
                            icon: const Icon(Icons.add),
                            label: const Text('Создать тренировку'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _templates.length,
                          itemBuilder: (context, index) {
                            final template = _templates[index];
                            final cs = Theme.of(context).colorScheme;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                                  child: const Icon(Icons.fitness_center),
                                ),
                                title: Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Длительность: ${_formatDuration(template.totalDuration)}'),
                                    Text(
                                      'Интервалов: ${template.intervals.length} | '
                                      'Упражнений: ${template.totalWorkIntervals}',
                                    ),
                                    if (template.totalRepetitions > 0)
                                      Text('Повторений: ${template.totalRepetitions}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      color: cs.primary,
                                      onPressed: () => _startWorkout(template),
                                      tooltip: 'Начать',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: cs.secondary,
                                      onPressed: () => _editTemplate(template),
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: cs.error,
                                      onPressed: () => _deleteTemplate(template),
                                      tooltip: 'Удалить',
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () => _startWorkout(template),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
