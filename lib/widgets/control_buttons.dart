import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class ControlButtons extends StatelessWidget {
  final TimerState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onReset;
  final VoidCallback? onFinish;

  const ControlButtons({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    this.onReset,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final showFinish = onFinish != null && (state == TimerState.running || state == TimerState.paused);
    final showReset = onReset != null && !showFinish;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Кнопка завершения тренировки (если предоставлена) или сброса
        // Фиксированная ширина для предотвращения смещения верстки
        if (showFinish || showReset)
          SizedBox(
            width: showFinish ? null : 48.0,
            child: showFinish
                ? ElevatedButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Завершить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: state != TimerState.idle ? onReset : null,
                    icon: const Icon(Icons.refresh),
                    iconSize: 32,
                    color: cs.onSurfaceVariant,
                  ),
          ),
        if (showFinish || showReset)
          const SizedBox(width: 12),
        // Основная кнопка (Старт/Пауза) - фиксированная минимальная ширина для предотвращения смещения
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              switch (state) {
                case TimerState.idle:
                case TimerState.finished:
                  onStart();
                  break;
                case TimerState.running:
                  onPause();
                  break;
                case TimerState.paused:
                  onResume();
                  break;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: state == TimerState.running ? cs.tertiary : cs.primary,
              foregroundColor: state == TimerState.running ? cs.onTertiary : cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state == TimerState.running
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getButtonText(),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    switch (state) {
      case TimerState.idle:
      case TimerState.finished:
        return 'СТАРТ';
      case TimerState.running:
        return 'ПАУЗА';
      case TimerState.paused:
        return 'ПРОДОЛЖИТЬ';
    }
  }
}
