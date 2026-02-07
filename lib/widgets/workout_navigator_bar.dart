import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/timer_service.dart';
import '../models/workout_interval.dart';
import '../theme/interval_colors.dart';
import 'timer_service_scope.dart';

/// SVG иконка маркера текущей позиции на таймлайне (стрелка/play).
const String _kTimelineMarkerSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M21.2428 12.4371C21.4016 12.3489 21.5 12.1816 21.5 12C21.5 11.8184 21.4016 11.6511 21.2428 11.5629L18.9605 10.295C14.464 7.79689 9.72391 5.76488 4.81421 4.2306L4.14914 4.02276C3.99732 3.97532 3.83198 4.00294 3.70383 4.09716C3.57568 4.19138 3.5 4.34094 3.5 4.5V10.25C3.5 10.5159 3.70816 10.7353 3.97372 10.7493L4.98336 10.8025C7.44497 10.932 9.89156 11.2659 12.2979 11.8006L12.5362 11.8536C12.5892 11.8654 12.6122 11.887 12.625 11.9042C12.6411 11.926 12.6536 11.9594 12.6536 12C12.6536 12.0406 12.6411 12.0741 12.625 12.0958C12.6122 12.113 12.5892 12.1347 12.5362 12.1464L12.2979 12.1994C9.89157 12.7341 7.44496 13.068 4.98334 13.1976L3.97372 13.2507C3.70816 13.2647 3.5 13.4841 3.5 13.75V19.5C3.5 19.6591 3.57568 19.8086 3.70383 19.9029C3.83198 19.9971 3.99732 20.0247 4.14914 19.9772L4.81422 19.7694C9.72391 18.2351 14.464 16.2031 18.9605 13.705L21.2428 12.4371Z" fill="black"/>
</svg>
''';

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

        // Прогресс в шкале полосы (оценочные секунды по сегментам), чтобы маркер совпадал с границами при смене интервала
        final totalBarSec = intervals.isEmpty
            ? 0
            : intervals.fold<int>(0, (s, i) => s + estimateSeconds(i));
        final idx = intervals.isEmpty
            ? 0
            : ts.currentIntervalIndex.clamp(0, intervals.length - 1);
        double progressWithinCurrent = 0.0;
        if (intervals.isNotEmpty && idx < intervals.length) {
          final currentInterval = intervals[idx];
          final durationOfCurrent = currentInterval.duration != null &&
                  currentInterval.duration! > 0
              ? currentInterval.duration!.toDouble()
              : estimateSeconds(currentInterval).toDouble();
          final elapsedInCurrent = currentInterval.duration != null &&
                  currentInterval.duration! > 0
              ? (currentInterval.duration! - ts.currentTime).toDouble()
              : ts.getManualIntervalElapsedTime().toDouble();
          progressWithinCurrent = durationOfCurrent <= 0
              ? 0.0
              : (elapsedInCurrent / durationOfCurrent).clamp(0.0, 1.0);
        }
        final completedBarSec = intervals.isEmpty || idx <= 0
            ? 0
            : List.generate(idx, (i) => estimateSeconds(intervals[i]))
                .fold<int>(0, (a, b) => a + b);
        final currentSegmentSec =
            intervals.isEmpty || idx >= intervals.length ? 0 : estimateSeconds(intervals[idx]);
        final elapsedBarSec =
            completedBarSec + currentSegmentSec * progressWithinCurrent;
        final progress = totalBarSec <= 0
            ? 0.0
            : (elapsedBarSec / totalBarSec).clamp(0.0, 1.0);

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
                  height: 24,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      const iconSize = 24.0;
                      final x = w * progress;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Row(children: segs),
                            ),
                          ),
                          Positioned(
                            left: (x - iconSize / 2).clamp(0.0, w - iconSize),
                            top: 5,
                            child: SvgPicture.string(
                              _kTimelineMarkerSvg,
                              width: iconSize,
                              height: iconSize,
                              colorFilter: ColorFilter.mode(
                                cs.onSurface,
                                BlendMode.srcIn,
                              ),
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

