import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../models/workout_interval.dart';

class PreWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate template;

  const PreWorkoutScreen({super.key, required this.template});

  @override
  State<PreWorkoutScreen> createState() => _PreWorkoutScreenState();
}

class _PreWorkoutScreenState extends State<PreWorkoutScreen> {
  late List<WorkoutInterval> _intervals;

  @override
  void initState() {
    super.initState();
    // Создаем копию интервалов для редактирования
    _intervals = widget.template.intervals.map((i) => i.copyWith()).toList();
  }

  void _updateRepetitions(int index, int delta) {
    setState(() {
      final interval = _intervals[index];
      if (interval.type == IntervalType.work && interval.repetitions != null) {
        final newReps = (interval.repetitions! + delta).clamp(1, 1000);
        _intervals[index] = interval.copyWith(repetitions: newReps);
      }
    });
  }

  void _updateWeight(int index, double delta) {
    setState(() {
      final interval = _intervals[index];
      if (interval.type == IntervalType.work) {
        final currentWeight = interval.weight ?? 0.0;
        final newWeight = (currentWeight + delta).clamp(0.0, 500.0);
        _intervals[index] = interval.copyWith(
          weight: newWeight > 0 ? newWeight : null,
        );
      }
    });
  }

  void _startWorkout() {
    // Создаем обновленный шаблон с измененными интервалами
    final updatedTemplate = widget.template.copyWith(intervals: _intervals);
    Navigator.pop(context, updatedTemplate);
  }

  String _formatWeight(double? weight) {
    if (weight == null || weight == 0) return 'Без веса';
    return '${weight.toStringAsFixed(1)} кг';
  }

  @override
  Widget build(BuildContext context) {
    final workIntervals = _intervals
        .where((i) => i.type == IntervalType.work)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Настройка: ${widget.template.name}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: workIntervals.isEmpty
                ? const Center(
                    child: Text('Нет упражнений в этой тренировке'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: workIntervals.length,
                    itemBuilder: (context, index) {
                      final interval = workIntervals[index];
                      final originalIndex = _intervals.indexOf(interval);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Название упражнения
                              Text(
                                interval.name ?? 'Упражнение ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Количество повторений
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Повторения:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => _updateRepetitions(originalIndex, -1),
                                        color: Colors.red,
                                      ),
                                      Text(
                                        '${interval.repetitions ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => _updateRepetitions(originalIndex, 1),
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Вес
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Вес:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => _updateWeight(originalIndex, -2.5),
                                        color: Colors.red,
                                      ),
                                      Text(
                                        _formatWeight(interval.weight),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => _updateWeight(originalIndex, 2.5),
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Кнопки действий
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _startWorkout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Начать тренировку',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
