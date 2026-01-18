import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../services/storage_service.dart';
import 'workout_template_editor_screen.dart';
import 'home_screen.dart';

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(selectedTemplate: template),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTemplate,
            tooltip: 'Создать тренировку',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
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
                        onPressed: _createTemplate,
                        icon: const Icon(Icons.add),
                        label: const Text('Создать тренировку'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.2),
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
                              color: Colors.green,
                              onPressed: () => _startWorkout(template),
                              tooltip: 'Начать',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              onPressed: () => _editTemplate(template),
                              tooltip: 'Редактировать',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
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
    );
  }
}
