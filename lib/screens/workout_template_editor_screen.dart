import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../models/workout_interval.dart';
import '../services/storage_service.dart';
import '../widgets/workout_navigator_bar.dart';

class WorkoutTemplateEditorScreen extends StatefulWidget {
  final WorkoutTemplate? template;

  const WorkoutTemplateEditorScreen({super.key, this.template});

  @override
  State<WorkoutTemplateEditorScreen> createState() =>
      _WorkoutTemplateEditorScreenState();
}

// Виджет для number инпута со стрелками
class _NumberInputWithToggle extends StatefulWidget {
  final String label;
  final int? value;
  final Function(int?) onChanged;
  final IconData addIcon;

  const _NumberInputWithToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.addIcon = Icons.add,
  });

  @override
  State<_NumberInputWithToggle> createState() => _NumberInputWithToggleState();
}

class _NumberInputWithToggleState extends State<_NumberInputWithToggle> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isUserInput = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_NumberInputWithToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем контроллер только если значение изменилось извне (не из-за пользовательского ввода)
    if (oldWidget.value != widget.value && !_isUserInput) {
      final wasFocused = _focusNode.hasFocus;
      if (widget.value == null) {
        _controller.clear();
      } else {
        final newText = widget.value.toString();
        if (_controller.text != newText) {
          _controller.text = newText;
        }
      }
      // Восстанавливаем фокус, если он был до обновления
      if (wasFocused && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      }
    }
    _isUserInput = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем стабильный ключ на основе label, чтобы виджет не пересоздавался при изменении value
    final widgetToReturn = widget.value == null
        ? IconButton(
            key: ValueKey('add_button_${widget.label}'),
            icon: Icon(widget.addIcon, size: 20),
            onPressed: () => widget.onChanged(0),
            tooltip: 'Добавить ${widget.label}',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          )
        : TextField(
            key: ValueKey('input_${widget.label}'),
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.red,
                onPressed: () => widget.onChanged(null),
                tooltip: 'Без ${widget.label}',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            onChanged: (text) {
              _isUserInput = true;
              final newValue = int.tryParse(text);
              if (newValue != null) {
                widget.onChanged(newValue);
              }
            },
          );
    return widgetToReturn;
  }
}

// Виджет для number инпута со стрелками для веса (double)
class _WeightInputWithToggle extends StatefulWidget {
  final String label;
  final double? value;
  final Function(double?) onChanged;

  const _WeightInputWithToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_WeightInputWithToggle> createState() => _WeightInputWithToggleState();
}

class _WeightInputWithToggleState extends State<_WeightInputWithToggle> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isUserInput = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toStringAsFixed(1) ?? '',
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_WeightInputWithToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем контроллер только если значение изменилось извне (не из-за пользовательского ввода)
    if (oldWidget.value != widget.value && !_isUserInput) {
      final wasFocused = _focusNode.hasFocus;
      if (widget.value == null) {
        _controller.clear();
      } else {
        final newText = widget.value!.toStringAsFixed(1);
        if (_controller.text != newText) {
          _controller.text = newText;
        }
      }
      // Восстанавливаем фокус, если он был до обновления
      if (wasFocused && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      }
    }
    _isUserInput = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем стабильный ключ на основе label, чтобы виджет не пересоздавался при изменении value
    final widgetToReturn = widget.value == null
        ? IconButton(
            key: ValueKey('add_button_${widget.label}'),
            icon: const Icon(Icons.fitness_center, size: 20),
            onPressed: () => widget.onChanged(0.0),
            tooltip: 'Добавить ${widget.label}',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          )
        : TextField(
            key: ValueKey('input_${widget.label}'),
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.red,
                onPressed: () => widget.onChanged(null),
                tooltip: 'Без ${widget.label}',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            onChanged: (text) {
              _isUserInput = true;
              final newValue = double.tryParse(text);
              if (newValue != null) {
                widget.onChanged(newValue);
              }
            },
          );
    return widgetToReturn;
  }
}

class _WorkoutTemplateEditorScreenState
    extends State<WorkoutTemplateEditorScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _nameController = TextEditingController();
  bool _isQuickMode = true;
  List<WorkoutInterval> _intervals = [];
  int? _restBetweenSets;
  List<String> _allExerciseNames = [];

  // Быстрый режим
  int _quickWorkDuration = 30;
  int _quickRestDuration = 10;
  int _quickRounds = 5;
  int _quickSets = 1;
  int _quickRestBetweenSets = 60;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _intervals = List.from(widget.template!.intervals);
      _restBetweenSets = widget.template!.restBetweenSets;
      _isQuickMode = false; // При редактировании используем кастомный режим
    }
    _loadAllExerciseNames();
  }

  Future<void> _loadAllExerciseNames() async {
    final names = await _storageService.getAllExerciseNamesFromTemplates();
    if (mounted) {
      setState(() {
        _allExerciseNames = names;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateQuickIntervals() {
    _intervals.clear();
    int order = 0;
    
    for (int set = 0; set < _quickSets; set++) {
      // Генерируем раунды для каждого сета
      for (int i = 0; i < _quickRounds; i++) {
        _intervals.add(WorkoutInterval(
          type: IntervalType.work,
          duration: _quickWorkDuration,
          order: order++,
        ));
        if (i < _quickRounds - 1) {
          _intervals.add(WorkoutInterval(
            type: IntervalType.rest,
            duration: _quickRestDuration,
            order: order++,
          ));
        }
      }
      
      // Добавляем отдых между сетами (кроме последнего сета)
      if (set < _quickSets - 1 && _quickRestBetweenSets > 0) {
        _intervals.add(WorkoutInterval(
          type: IntervalType.restBetweenSets,
          duration: _quickRestBetweenSets,
          order: order++,
        ));
      }
    }
    
    _restBetweenSets = _quickRestBetweenSets;
  }

  void _addInterval(WorkoutInterval interval) {
    setState(() {
      _intervals.add(interval);
      _intervals.sort((a, b) => a.order.compareTo(b.order));
    });
  }

  void _removeInterval(int index) {
    setState(() {
      _intervals.removeAt(index);
      // Пересчитываем порядок
      for (int i = 0; i < _intervals.length; i++) {
        _intervals[i] = _intervals[i].copyWith(order: i);
      }
    });
  }

  void _updateInterval(int index, WorkoutInterval interval) {
    setState(() {
      _intervals[index] = interval;
    });
  }

  void _cloneInterval(int index) {
    setState(() {
      final original = _intervals[index];
      final cloned = original.copyWith(order: _intervals.length);
      _intervals.add(cloned);
      _intervals.sort((a, b) => a.order.compareTo(b.order));
      // Пересчитываем порядок
      for (int i = 0; i < _intervals.length; i++) {
        _intervals[i] = _intervals[i].copyWith(order: i);
      }
    });
  }

  void _reorderIntervals(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final interval = _intervals.removeAt(oldIndex);
      _intervals.insert(newIndex, interval);
      // Пересчитываем порядок всех интервалов
      for (int i = 0; i < _intervals.length; i++) {
        _intervals[i] = _intervals[i].copyWith(order: i);
      }
    });
  }

  void _addRestAfterInterval(int index) {
    setState(() {
      final newRestInterval = WorkoutInterval(
        type: IntervalType.rest,
        duration: 20, // Значение по умолчанию
        order: index + 1,
      );
      _intervals.insert(index + 1, newRestInterval);
      // Пересчитываем порядок всех интервалов
      for (int i = 0; i < _intervals.length; i++) {
        _intervals[i] = _intervals[i].copyWith(order: i);
      }
    });
  }

  void _updateIntervalDuration(int index, int? duration) {
    setState(() {
      _intervals[index] = _intervals[index].copyWith(duration: duration);
    });
  }

  void _updateIntervalRepetitions(int index, int? repetitions) {
    setState(() {
      _intervals[index] = _intervals[index].copyWith(repetitions: repetitions);
    });
  }

  void _updateIntervalWeight(int index, double? weight) {
    setState(() {
      _intervals[index] = _intervals[index].copyWith(weight: weight);
    });
  }

  void _updateIntervalName(int index, String? name) {
    setState(() {
      _intervals[index] = _intervals[index].copyWith(name: name?.trim().isEmpty == true ? null : name?.trim());
    });
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название тренировки')),
      );
      return;
    }

    if (_intervals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один интервал')),
      );
      return;
    }

    final template = WorkoutTemplate(
      id: widget.template?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      intervals: _intervals,
      restBetweenSets: _restBetweenSets,
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      lastUsed: widget.template?.lastUsed,
    );

    await _storageService.saveTemplate(template);
    // Обновляем список названий упражнений после сохранения
    _loadAllExerciseNames();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return 'Без времени';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '$secs сек';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Создать тренировку' : 'Редактировать тренировку'),
        actions: [
          TextButton(
            onPressed: _saveTemplate,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const WorkoutNavigatorBar(margin: EdgeInsets.zero),
          const SizedBox(height: 12),
          // Название тренировки
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название тренировки',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          // Переключатель режима
          Card(
            child: SwitchListTile(
              title: const Text('Режим создания'),
              subtitle: Text(_isQuickMode ? 'Быстрый' : 'Кастомный'),
              value: _isQuickMode,
              onChanged: (value) {
                setState(() {
                  _isQuickMode = value;
                  if (value) {
                    _generateQuickIntervals();
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Быстрый режим
          if (_isQuickMode) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Время работы',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_quickWorkDuration),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _quickWorkDuration.toDouble(),
                      min: 5,
                      max: 300,
                      divisions: 59,
                      onChanged: (value) {
                        setState(() {
                          _quickWorkDuration = value.toInt();
                          _generateQuickIntervals();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Время отдыха',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_quickRestDuration),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _quickRestDuration.toDouble(),
                      min: 5,
                      max: 180,
                      divisions: 35,
                      onChanged: (value) {
                        setState(() {
                          _quickRestDuration = value.toInt();
                          _generateQuickIntervals();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Количество раундов',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_quickRounds',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _quickRounds.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (value) {
                        setState(() {
                          _quickRounds = value.toInt();
                          _generateQuickIntervals();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Количество сетов',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_quickSets',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _quickSets.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _quickSets = value.toInt();
                          _generateQuickIntervals();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Отдых между сетами',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_quickRestBetweenSets),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _quickRestBetweenSets.toDouble(),
                      min: 0,
                      max: 300,
                      divisions: 60,
                      onChanged: (value) {
                        setState(() {
                          _quickRestBetweenSets = value.toInt();
                          _restBetweenSets = _quickRestBetweenSets > 0
                              ? _quickRestBetweenSets
                              : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Кастомный режим
            const Text(
              'Интервалы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddIntervalDialog(IntervalType.work),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Работа'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddIntervalDialog(IntervalType.rest),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Отдых'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddIntervalDialog(IntervalType.restBetweenSets),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Между сетами', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_intervals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Нет интервалов. Добавьте первый интервал.'),
                ),
              )
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _reorderIntervals,
                children: _intervals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final interval = entry.value;
                  return Card(
                    key: ValueKey('interval_${interval.order}_$index'),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: interval.type == IntervalType.work
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : interval.type == IntervalType.restBetweenSets
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : Colors.green.withValues(alpha: 0.2),
                                child: Text('${index + 1}'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  interval.type == IntervalType.work && interval.name != null
                                      ? interval.name!
                                      : interval.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.drag_handle,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.green,
                                onPressed: () => _addRestAfterInterval(index),
                                tooltip: 'Добавить отдых после',
                              ),
                              IconButton(
                                icon: const Icon(Icons.content_copy),
                                onPressed: () => _cloneInterval(index),
                                tooltip: 'Клонировать',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _removeInterval(index),
                                tooltip: 'Удалить',
                              ),
                            ],
                          ),
                        if (interval.type == IntervalType.work) ...[
                          const SizedBox(height: 12),
                          Autocomplete<String>(
                            key: ValueKey('name_${index}_${interval.name}'),
                            initialValue: interval.name != null ? TextEditingValue(text: interval.name!) : null,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return _allExerciseNames;
                              }
                              return _allExerciseNames.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (String selection) {
                              _updateIntervalName(index, selection);
                            },
                            fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              textEditingController.text = interval.name ?? '';
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Название упражнения',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (value) {
                                  _updateIntervalName(index, value.isEmpty ? null : value);
                                },
                                onSubmitted: (String value) {
                                  onFieldSubmitted();
                                },
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: _NumberInputWithToggle(
                                key: ValueKey('duration_$index'),
                                label: 'Длительность (сек)',
                                value: interval.duration,
                                onChanged: (value) => _updateIntervalDuration(index, value),
                                addIcon: Icons.access_time,
                              ),
                            ),
                            if (interval.type == IntervalType.work) ...[
                              const SizedBox(width: 2),
                              Expanded(
                                flex: 1,
                                child: _NumberInputWithToggle(
                                  key: ValueKey('repetitions_$index'),
                                  label: 'Повторений',
                                  value: interval.repetitions,
                                  onChanged: (value) => _updateIntervalRepetitions(index, value),
                                  addIcon: Icons.close,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: 1,
                                child: _WeightInputWithToggle(
                                  key: ValueKey('weight_$index'),
                                  label: 'Вес (кг)',
                                  value: interval.weight,
                                  onChanged: (value) => _updateIntervalWeight(index, value),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          // Предпросмотр
          if (_intervals.isNotEmpty)
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Предпросмотр',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Всего интервалов: ${_intervals.length}'),
                    Text(
                      'Общая длительность: ${_formatDuration(_intervals.fold<int>(0, (sum, i) => sum + (i.duration ?? 0)))}',
                    ),
                    Text(
                      'Упражнений: ${_intervals.where((i) => i.type == IntervalType.work).length}',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddIntervalDialog([IntervalType? presetType]) {
    _showIntervalDialog(null, presetType: presetType);
  }


  void _showIntervalDialog(WorkoutInterval? interval, {int? index, IntervalType? presetType}) async {
    final isEdit = interval != null;
    final typeController = ValueNotifier<IntervalType>(
      presetType ?? interval?.type ?? IntervalType.work,
    );
    final durationController = TextEditingController(
      text: interval?.duration?.toString() ?? '',
    );
    final nameController = TextEditingController(
      text: interval?.name ?? '',
    );
    final repetitionsController = TextEditingController(
      text: interval?.repetitions?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: interval?.weight?.toStringAsFixed(1) ?? '',
    );
    
    // Загружаем историю упражнений
    final exerciseNames = await _storageService.getExerciseNames();
    if (!mounted) return;
    String? selectedExerciseName;

    showDialog(
      context: context,
      builder: (context) => ValueListenableBuilder<IntervalType>(
        valueListenable: typeController,
        builder: (context, type, _) => AlertDialog(
          title: Text(isEdit ? 'Редактировать интервал' : 'Добавить интервал'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<IntervalType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Тип интервала',
                    border: OutlineInputBorder(),
                  ),
                  items: IntervalType.values.map((t) {
                    String label;
                    switch (t) {
                      case IntervalType.work:
                        label = 'Работа';
                        break;
                      case IntervalType.rest:
                        label = 'Отдых';
                        break;
                      case IntervalType.restBetweenSets:
                        label = 'Отдых между сетами';
                        break;
                    }
                    return DropdownMenuItem(value: t, child: Text(label));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) typeController.value = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Длительность (секунды)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (type == IntervalType.work) ...[
                  const SizedBox(height: 16),
                  // Выбор из существующих упражнений
                  if (exerciseNames.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: selectedExerciseName,
                      decoration: const InputDecoration(
                        labelText: 'Выбрать из существующих',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('-- Новое упражнение --'),
                        ),
                        ...exerciseNames.map((name) => DropdownMenuItem<String?>(
                              value: name,
                              child: Text(name),
                            )),
                      ],
                      onChanged: (value) async {
                        selectedExerciseName = value;
                        if (value != null) {
                          nameController.text = value;
                          // Загружаем последние данные для этого упражнения
                          final lastData = await _storageService.getLastExerciseData(
                            value,
                            weight: weightController.text.isNotEmpty
                                ? double.tryParse(weightController.text)
                                : null,
                          );
                          if (lastData != null) {
                            repetitionsController.text = lastData.lastRepetitions.toString();
                            if (lastData.lastWeight != null) {
                              weightController.text = lastData.lastWeight!.toStringAsFixed(1);
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Поле ввода названия
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название упражнения',
                      border: OutlineInputBorder(),
                      hintText: 'Или введите новое название',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: repetitionsController,
                    decoration: const InputDecoration(
                      labelText: 'Количество повторений',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес (кг, опционально)',
                      border: OutlineInputBorder(),
                      hintText: 'Оставьте пустым, если без веса',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final duration = durationController.text.isNotEmpty
                    ? int.tryParse(durationController.text)
                    : null;
                final repetitions = type == IntervalType.work
                    ? int.tryParse(repetitionsController.text)
                    : null;
                final name = type == IntervalType.work && nameController.text.isNotEmpty
                    ? nameController.text
                    : null;
                final weight = type == IntervalType.work && weightController.text.isNotEmpty
                    ? double.tryParse(weightController.text)
                    : null;

                final newInterval = WorkoutInterval(
                  type: type,
                  duration: duration,
                  name: name,
                  repetitions: repetitions,
                  weight: weight,
                  order: index ?? _intervals.length,
                );

                if (isEdit && index != null) {
                  _updateInterval(index, newInterval);
                } else {
                  _addInterval(newInterval);
                }

                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
