import 'package:flutter/material.dart';
import '../services/timer_service.dart';
import '../models/workout_interval.dart';
import '../theme/interval_colors.dart';
import 'timer_service_scope.dart';

class WorkoutNavigatorBar extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const WorkoutNavigatorBar({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 8),
  });

  @override
  Widget build(BuildContext context) {
    final ts = TimerServiceScope.of(context);
    return AnimatedBuilder(
      animation: ts,
      builder: (context, _) {
        final state = ts.state;
        if (state != TimerState.running && state != TimerState.paused) {
          return const SizedBox.shrink();
        }

        final cs = Theme.of(context).colorScheme;
        final colors = IntervalColors.of(context);

        final remainingSecs = ts.getEstimatedRemainingTime();
        final remainingMinutes = (remainingSecs / 60).ceil();
        final eta = DateTime.now().add(Duration(seconds: remainingSecs));
        final etaStr = MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(eta),
          alwaysUse24HourFormat: true,
        );

        final remainingRepsMap = ts.getRemainingRepetitions();
        final remainingReps = remainingRepsMap.values.fold<int>(0, (sum, v) => sum + v);

        final intervals = ts.intervals;
        final totalEstimated = ts.getElapsedTime() + remainingSecs;
        final progress = totalEstimated <= 0 ? 0.0 : (ts.getElapsedTime() / totalEstimated).clamp(0.0, 1.0);

        Color intervalColor(IntervalType type) {
          switch (type) {
            case IntervalType.work:
              return colors.work;
            case IntervalType.rest:
              return colors.rest;
            case IntervalType.restBetweenSets:
              return colors.restBetweenSets;
          }
        }

        int estimateSeconds(WorkoutInterval i) {
          return ts.estimateIntervalDurationSeconds(i);
        }

        // Сегментированная полоса: пропорционально длительностям,
        // но ограничиваем flex, чтобы не было огромных чисел.
        final segs = intervals.isEmpty
            ? const <Widget>[]
            : intervals.map((i) {
                final seconds = estimateSeconds(i);
                final flex = (seconds / 5).round().clamp(1, 200);
                return Expanded(
                  flex: flex,
                  child: Container(color: intervalColor(i.type)),
                );
              }).toList();

        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _TopMetric(
                    value: remainingReps.toString(),
                    label: 'повт.',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopMetric(
                      value: etaStr,
                      label: 'окончание',
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _TopMetric(
                    value: '$remainingMinutes',
                    label: 'мин',
                    align: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 14,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final x = w * progress;
                      return Stack(
                        children: [
                          Row(children: segs),
                          Positioned(
                            left: (x - 1).clamp(0, w - 2),
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: cs.surface,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopMetric extends StatelessWidget {
  final String value;
  final String label;
  final TextAlign align;

  const _TopMetric({
    required this.value,
    required this.label,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : align == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          textAlign: align,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          textAlign: align,
          style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

