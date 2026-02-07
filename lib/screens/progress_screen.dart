import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/workout_session.dart';
import '../models/workout_template.dart';
import '../widgets/workout_navigator_bar.dart';

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
  Map<String, dynamic>? _templateComparison;
  bool _isLoading = true;
  String? _selectedTemplateId;
  String _trendMetric = 'totalWeight'; // totalWeight | totalDuration | totalRepetitions
  String _exerciseDiffSort = 'tonnage'; // tonnage | time | reps

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
    Map<String, dynamic>? comparison;
    if (_selectedTemplateId != null) {
      comparison = await _storageService.getTemplateComparisonStats(
        _selectedTemplateId!,
        lookback: 10,
      );
    }

    setState(() {
      _sessions = sessions;
      _templates = templates;
      _stats = stats;
      _templateComparison = comparison;
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours ч $minutes мин';
    }
    return '$minutes мин';
  }

  String _formatDeltaInt(int delta) {
    if (delta == 0) return '0';
    return delta > 0 ? '+$delta' : '$delta';
  }

  String _formatDeltaDouble(double delta, {int fractionDigits = 1}) {
    if (delta == 0) return '0';
    final s = delta.toStringAsFixed(fractionDigits);
    return delta > 0 ? '+$s' : s;
  }

  String _formatPct(double? pct) {
    if (pct == null) return '—';
    final s = pct.toStringAsFixed(1);
    return pct > 0 ? '+$s%' : '$s%';
  }

  Color _deltaColor(num delta) {
    if (delta == 0) return Theme.of(context).colorScheme.onSurfaceVariant;
    return delta > 0 ? Colors.green : Colors.red;
  }

  Widget _buildDeltaRow({
    required String label,
    required String value,
    required String deltaText,
    required String pctText,
    required IconData icon,
    required num deltaForColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      deltaText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _deltaColor(deltaForColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pctText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
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
                _templateComparison = null;
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
            const WorkoutNavigatorBar(margin: EdgeInsets.zero),
            const SizedBox(height: 12),
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

            // Сравнение по шаблону (last vs prev)
            if (_selectedTemplateId == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Сравнение тренировок',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Выберите шаблон через фильтр, чтобы сравнить последнюю тренировку с предыдущей и увидеть изменения по упражнениям.',
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._buildTemplateComparisonSection(),

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
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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

  List<Widget> _buildTemplateComparisonSection() {
    final comparison = _templateComparison;
    if (comparison == null) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    final last = comparison['lastSession'] as WorkoutSession?;
    final prev = comparison['prevSession'] as WorkoutSession?;

    if (last == null) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Сравнение тренировок',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Пока нет тренировок по выбранному шаблону.'),
              ],
            ),
          ),
        ),
      ];
    }

    final deltas = (comparison['deltas'] as Map<String, dynamic>?) ?? const {};

    Map<String, dynamic> d(String key) =>
        (deltas[key] as Map<String, dynamic>?) ?? const {};

    String valueDuration(Map<String, dynamic> m) {
      final v = m['last'] as int?;
      return v == null ? '—' : _formatDuration(v);
    }

    String valueInt(Map<String, dynamic> m) {
      final v = m['last'] as int?;
      return v == null ? '—' : '$v';
    }

    String valueKg(Map<String, dynamic> m) {
      final v = m['last'] as double?;
      return v == null ? '—' : '${v.toStringAsFixed(1)} кг';
    }

    String valuePerMinKg(Map<String, dynamic> m) {
      final v = m['last'] as double?;
      return v == null ? '—' : '${v.toStringAsFixed(1)} кг/мин';
    }

    String valuePerMinReps(Map<String, dynamic> m) {
      final v = m['last'] as double?;
      return v == null ? '—' : '${v.toStringAsFixed(1)} повт/мин';
    }

    final duration = d('durationSec');
    final reps = d('repetitions');
    final weight = d('totalWeight');
    final weightPerMin = d('weightPerMin');
    final repsPerMin = d('repsPerMin');

    final durationDelta = duration['delta'] as int? ?? 0;
    final repsDelta = reps['delta'] as int? ?? 0;
    final weightDelta = weight['delta'] as double? ?? 0.0;
    final weightPerMinDelta = weightPerMin['delta'] as double? ?? 0.0;
    final repsPerMinDelta = repsPerMin['delta'] as double? ?? 0.0;

    final canCompare = prev != null;

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Последняя тренировка vs предыдущая',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                last.workoutName ?? 'Шаблон',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (!canCompare)
                Text(
                  'Сравнение появится после следующей тренировки по этому шаблону.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                )
              else ...[
                _buildDeltaRow(
                  label: 'Длительность',
                  value: valueDuration(duration),
                  deltaText: '${_formatDeltaInt(durationDelta)} сек',
                  pctText: _formatPct(duration['pct'] as double?),
                  icon: Icons.timer,
                  deltaForColor: durationDelta,
                ),
                _buildDeltaRow(
                  label: 'Повторы',
                  value: valueInt(reps),
                  deltaText: _formatDeltaInt(repsDelta),
                  pctText: _formatPct(reps['pct'] as double?),
                  icon: Icons.repeat,
                  deltaForColor: repsDelta,
                ),
                if (((weight['last'] as double?) ?? 0.0) > 0 || ((weight['prev'] as double?) ?? 0.0) > 0)
                  _buildDeltaRow(
                    label: 'Тоннаж',
                    value: valueKg(weight),
                    deltaText: _formatDeltaDouble(weightDelta, fractionDigits: 1),
                    pctText: _formatPct(weight['pct'] as double?),
                    icon: Icons.fitness_center,
                    deltaForColor: weightDelta,
                  ),
                if (((weightPerMin['last'] as double?) ?? 0.0) > 0 || ((weightPerMin['prev'] as double?) ?? 0.0) > 0)
                  _buildDeltaRow(
                    label: 'Плотность (тоннаж/мин)',
                    value: valuePerMinKg(weightPerMin),
                    deltaText: _formatDeltaDouble(weightPerMinDelta, fractionDigits: 1),
                    pctText: _formatPct(weightPerMin['pct'] as double?),
                    icon: Icons.speed,
                    deltaForColor: weightPerMinDelta,
                  ),
                if (((repsPerMin['last'] as double?) ?? 0.0) > 0 || ((repsPerMin['prev'] as double?) ?? 0.0) > 0)
                  _buildDeltaRow(
                    label: 'Плотность (повторы/мин)',
                    value: valuePerMinReps(repsPerMin),
                    deltaText: _formatDeltaDouble(repsPerMinDelta, fractionDigits: 1),
                    pctText: _formatPct(repsPerMin['pct'] as double?),
                    icon: Icons.bolt,
                    deltaForColor: repsPerMinDelta,
                  ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      _buildTrendCard(comparison),
      const SizedBox(height: 16),
      if (canCompare) _buildExerciseDiffsCard(comparison),
      const SizedBox(height: 16),
      _buildPrsCard(comparison),
    ];
  }

  Widget _buildTrendCard(Map<String, dynamic> comparison) {
    final series = (comparison['trendSeries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final cs = Theme.of(context).colorScheme;

    if (series.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Тренд', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Недостаточно данных для тренда.'),
            ],
          ),
        ),
      );
    }

    double valueFor(Map<String, dynamic> s) {
      switch (_trendMetric) {
        case 'totalDuration':
          return (s['totalDuration'] as int?)?.toDouble() ?? 0.0;
        case 'totalRepetitions':
          return (s['totalRepetitions'] as int?)?.toDouble() ?? 0.0;
        case 'totalWeight':
        default:
          return (s['totalWeight'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final values = series.map(valueFor).toList();
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxV <= 0 ? 1.0 : maxV;

    String titleForMetric() {
      switch (_trendMetric) {
        case 'totalDuration':
          return 'Тренд: длительность';
        case 'totalRepetitions':
          return 'Тренд: повторы';
        case 'totalWeight':
        default:
          return 'Тренд: тоннаж';
      }
    }

    String labelForValue(double v) {
      switch (_trendMetric) {
        case 'totalDuration':
          return _formatDuration(v.round());
        case 'totalRepetitions':
          return v.round().toString();
        case 'totalWeight':
        default:
          return '${v.toStringAsFixed(0)} кг';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titleForMetric(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'totalWeight', label: Text('Тоннаж')),
                ButtonSegment(value: 'totalDuration', label: Text('Время')),
                ButtonSegment(value: 'totalRepetitions', label: Text('Повторы')),
              ],
              selected: {_trendMetric},
              onSelectionChanged: (set) {
                setState(() => _trendMetric = set.first);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(series.length, (i) {
                  final v = values[i];
                  final h = (v / safeMax) * 110.0;
                  final dt = DateTime.tryParse((series[i]['dateTime'] as String?) ?? '');
                  final xLabel = dt == null ? '' : DateFormat('dd.MM').format(dt);
                  final isLast = i == 0; // series отсортирован по убыванию, первая = последняя тренировка

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 22,
                        height: h.isFinite ? h : 0,
                        decoration: BoxDecoration(
                          color: isLast ? cs.primary : cs.primary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(xLabel, style: const TextStyle(fontSize: 10)),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Последнее значение: ${labelForValue(values.isNotEmpty ? values.first : 0)}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDiffsCard(Map<String, dynamic> comparison) {
    final diffs = (comparison['exerciseDiffs'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    double scoreFor(Map<String, dynamic> d) {
      switch (_exerciseDiffSort) {
        case 'time':
          return ((d['deltaTimeSec'] as int?) ?? 0).abs().toDouble();
        case 'reps':
          return ((d['deltaReps'] as int?) ?? 0).abs().toDouble();
        case 'tonnage':
        default:
          return ((d['deltaTonnage'] as double?) ?? 0.0).abs();
      }
    }

    final sorted = diffs.toList()
      ..sort((a, b) => scoreFor(b).compareTo(scoreFor(a)));
    final shown = sorted.take(8).toList();

    if (shown.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Что изменилось по упражнениям', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Нет данных по упражнениям для сравнения (нужны intervalStats).'),
            ],
          ),
        ),
      );
    }

    String fmtTimeDelta(int sec) => sec == 0 ? '0' : _formatDeltaInt(sec);

    String fmtTimeValue(int sec) {
      if (sec <= 0) return '0 сек';
      if (sec < 60) return '$sec сек';
      final m = sec ~/ 60;
      final s = sec % 60;
      return s == 0 ? '$m мин' : '$m мин $s сек';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Что изменилось по упражнениям',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tonnage', label: Text('Тоннаж')),
                ButtonSegment(value: 'time', label: Text('Время')),
                ButtonSegment(value: 'reps', label: Text('Повторы')),
              ],
              selected: {_exerciseDiffSort},
              onSelectionChanged: (set) => setState(() => _exerciseDiffSort = set.first),
            ),
            const SizedBox(height: 12),
            ...shown.map((d) {
              final name = (d['name'] as String?) ?? '';
              final last = (d['last'] as Map<String, dynamic>?) ?? const {};
              final prev = (d['prev'] as Map<String, dynamic>?) ?? const {};

              final lastReps = (last['reps'] as int?) ?? 0;
              final prevReps = (prev['reps'] as int?) ?? 0;
              final lastTime = (last['timeSec'] as int?) ?? 0;
              final prevTime = (prev['timeSec'] as int?) ?? 0;
              final lastTon = (last['tonnage'] as double?) ?? 0.0;
              final prevTon = (prev['tonnage'] as double?) ?? 0.0;
              final lastMaxW = last['maxWeight'] as double?;
              final prevMaxW = prev['maxWeight'] as double?;

              final dReps = (d['deltaReps'] as int?) ?? 0;
              final dTime = (d['deltaTimeSec'] as int?) ?? 0;
              final dTon = (d['deltaTonnage'] as double?) ?? 0.0;
              final dMaxW = d['deltaMaxWeight'] as double?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Повторы: $prevReps → $lastReps   ·   Время: ${fmtTimeValue(prevTime)} → ${fmtTimeValue(lastTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (prevTon > 0 || lastTon > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Тоннаж: ${prevTon.toStringAsFixed(1)} кг → ${lastTon.toStringAsFixed(1)} кг'
                          '${(prevMaxW != null || lastMaxW != null) ? '   ·   Макс вес: ${(prevMaxW ?? 0).toStringAsFixed(1)} → ${(lastMaxW ?? 0).toStringAsFixed(1)} кг' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _miniChip('Повторы', _formatDeltaInt(dReps), _deltaColor(dReps)),
                        _miniChip('Время', '${fmtTimeDelta(dTime)} сек', _deltaColor(dTime)),
                        _miniChip('Тоннаж', _formatDeltaDouble(dTon, fractionDigits: 1), _deltaColor(dTon)),
                        if (dMaxW != null) _miniChip('Макс вес', _formatDeltaDouble(dMaxW, fractionDigits: 1), _deltaColor(dMaxW)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, String value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: cs.onSurfaceVariant)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildPrsCard(Map<String, dynamic> comparison) {
    final prs = (comparison['prs'] as Map<String, dynamic>?) ?? const {};
    final maxWeight = (prs['maxWeight'] as Map?)?.cast<String, double>() ?? const {};
    final maxReps = (prs['maxRepsPerWorkout'] as Map?)?.cast<String, int>() ?? const {};
    final maxTonnage = (prs['maxTonnagePerWorkout'] as Map?)?.cast<String, double>() ?? const {};

    List<MapEntry<String, double>> topWeight = maxWeight.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, int>> topReps = maxReps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, double>> topTon = maxTonnage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    topWeight = topWeight.take(5).toList();
    topReps = topReps.take(5).toList();
    topTon = topTon.take(5).toList();

    final hasAny = topWeight.isNotEmpty || topReps.isNotEmpty || topTon.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Личные рекорды (PR)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (!hasAny)
              const Text('Пока нет PR по упражнениям для этого шаблона.')
            else ...[
              if (topWeight.isNotEmpty) ...[
                const Text('Максимальный вес', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...topWeight.map((e) => _prRow(e.key, '${e.value.toStringAsFixed(1)} кг')),
                const SizedBox(height: 12),
              ],
              if (topTon.isNotEmpty) ...[
                const Text('Макс тоннаж за тренировку', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...topTon.map((e) => _prRow(e.key, '${e.value.toStringAsFixed(1)} кг')),
                const SizedBox(height: 12),
              ],
              if (topReps.isNotEmpty) ...[
                const Text('Макс повторы за тренировку', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...topReps.map((e) => _prRow(e.key, '${e.value}')),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _prRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
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
    final cs = Theme.of(context).colorScheme;
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
                  color: cs.primary,
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
