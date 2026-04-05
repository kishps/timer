import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class ControlButtons extends StatelessWidget {
  final TimerState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onReset;
  final VoidCallback? onFinish;
  /// Содержимое правых 2/3 ширины (например «Следующий интервал»).
  final Widget? slotTwoThirds;

  const ControlButtons({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    this.onReset,
    this.onFinish,
    this.slotTwoThirds,
  });

  static const double _rowMinHeight = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final showFinish = onFinish != null &&
        (state == TimerState.running || state == TimerState.paused);
    final showReset = onReset != null && !showFinish;
    final hasNextSlot = slotTwoThirds != null;
    final showWorkControls =
        state == TimerState.running || state == TimerState.paused;

    // Ветка A: есть «Следующий интервал» — 1/3 иконки + 2/3 слот
    if (hasNextSlot) {
      return SizedBox(
        height: _rowMinHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: _buildLeftThirdCompactIcons(
                context,
                cs,
                showFinish: showFinish,
                showReset: showReset,
              ),
            ),
            Expanded(
              flex: 2,
              child: slotTwoThirds!,
            ),
          ],
        ),
      );
    }

    // Ветка B: активная тренировка без слота — «Завершить» + Пауза/Продолжить на всю ширину с текстом
    if (showWorkControls) {
      return SizedBox(
        height: _rowMinHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showReset) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                onPressed: state != TimerState.idle ? onReset : null,
                icon: Icon(Icons.refresh, size: 26, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
            ],
            if (showFinish) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onFinish,
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    'Завершить',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  switch (state) {
                    case TimerState.running:
                      onPause();
                      break;
                    case TimerState.paused:
                      onResume();
                      break;
                    default:
                      break;
                  }
                },
                icon: Icon(
                  state == TimerState.running ? Icons.pause : Icons.play_arrow,
                  size: 28,
                ),
                label: Text(
                  state == TimerState.paused ? 'ПРОДОЛЖИТЬ' : 'ПАУЗА',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state == TimerState.running
                      ? cs.tertiary
                      : cs.primary,
                  foregroundColor: state == TimerState.running
                      ? cs.onTertiary
                      : cs.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Ветка C: простой / финиш — СТАРТ на всю ширину (+ сброс при необходимости)
    return SizedBox(
      height: _rowMinHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showReset) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
              onPressed: state != TimerState.idle ? onReset : null,
              icon: Icon(Icons.refresh, size: 26, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _buildFullWidthStartButton(context, theme, cs),
          ),
        ],
      ),
    );
  }

  /// Левая 1/3 при показе «Следующий интервал»: только иконки + подсказки.
  Widget _buildLeftThirdCompactIcons(
    BuildContext context,
    ColorScheme cs, {
    required bool showFinish,
    required bool showReset,
  }) {
    final showPrimaryOnLeft =
        state == TimerState.running || state == TimerState.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showReset)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
            onPressed: state != TimerState.idle ? onReset : null,
            icon: Icon(Icons.refresh, size: 22, color: cs.onSurfaceVariant),
          ),
        if (showFinish) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Завершить',
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.check_circle, size: 22),
                ),
              ),
            ),
          ),
        ],
        if (showPrimaryOnLeft)
          Expanded(
            child: Tooltip(
              message:
                  state == TimerState.paused ? 'Продолжить' : 'Пауза',
              child: ElevatedButton(
                onPressed: () {
                  switch (state) {
                    case TimerState.running:
                      onPause();
                      break;
                    case TimerState.paused:
                      onResume();
                      break;
                    default:
                      break;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: state == TimerState.running
                      ? cs.tertiary
                      : cs.primary,
                  foregroundColor: state == TimerState.running
                      ? cs.onTertiary
                      : cs.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(
                  state == TimerState.running
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullWidthStartButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return ElevatedButton(
      onPressed: onStart,
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_arrow, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'СТАРТ',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
