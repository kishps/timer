import 'package:flutter/material.dart';
import '../models/workout_interval.dart';
import '../theme/interval_colors.dart';

class IntervalsScrollList extends StatefulWidget {
  final List<WorkoutInterval> intervals;
  final int currentIndex;

  const IntervalsScrollList({
    super.key,
    required this.intervals,
    required this.currentIndex,
  });

  @override
  State<IntervalsScrollList> createState() => _IntervalsScrollListState();
}

class _IntervalsScrollListState extends State<IntervalsScrollList> {
  final ScrollController _scrollController = ScrollController();
  final double _itemExtent = 48.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  @override
  void didUpdateWidget(IntervalsScrollList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToCurrent();
    }
  }

  void _scrollToCurrent() {
    if (!mounted || !_scrollController.hasClients || widget.intervals.isEmpty) return;

    final index = widget.currentIndex.clamp(0, widget.intervals.length - 1);
    final position = index * _itemExtent;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetPosition = position.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getIntervalColor(BuildContext context, IntervalType type) {
    final colors = IntervalColors.of(context);
    switch (type) {
      case IntervalType.work:
        return colors.work;
      case IntervalType.rest:
        return colors.rest;
      case IntervalType.restBetweenSets:
        return colors.restBetweenSets;
    }
  }

  String _getIntervalTitle(WorkoutInterval interval) {
    String title = interval.displayName;
    if (interval.type == IntervalType.work) {
      if (interval.repetitions != null) {
        title += ' ×${interval.repetitions}';
      }
      if (interval.weight != null && interval.weight! > 0) {
        title += ' ×${interval.weight!.toStringAsFixed(1)}кг';
      }
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.builder(
          controller: _scrollController,
          // Убираем shrinkWrap, чтобы список (и его фон) растягивался на всю доступную высоту таба
          itemExtent: _itemExtent,
          itemCount: widget.intervals.length,
          itemBuilder: (context, index) {
            final interval = widget.intervals[index];
            final isCurrent = index == widget.currentIndex;
            final isPast = index < widget.currentIndex;
            final color = _getIntervalColor(context, interval.type);

            return Container(
              decoration: BoxDecoration(
                color: isCurrent ? color.withValues(alpha: 0.15) : Colors.transparent,
                border: isCurrent
                    ? Border(left: BorderSide(color: color, width: 4))
                    : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Opacity(
                opacity: isPast ? 0.4 : 1.0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getIntervalTitle(interval),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (interval.duration != null && interval.duration! > 0)
                      Text(
                        '${interval.duration}с',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Icon(
                        Icons.pan_tool_alt,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
