import 'package:flutter/material.dart';
import '../models/workout_interval.dart';
import '../theme/interval_colors.dart';

class TimerDisplay extends StatelessWidget {
  final int currentTime;
  final WorkoutInterval? currentInterval;
  final int currentIntervalIndex;
  final int totalIntervals;
  final int totalDuration;
  final int elapsedTime;
  final double progress;
  final Map<String, int>? completedRepetitions;
  final Map<String, int>? remainingRepetitions;
  final List<WorkoutInterval>? nextIntervals;
  final int? totalElapsedTime;
  final int? totalRemainingTime;
  final bool isManualInterval;
  final int? manualElapsedTime;
  
  // Параметры для кнопок переключения интервалов
  final bool isPaused;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback? onPreviousInterval;
  final VoidCallback? onNextInterval;
  
  // Все интервалы для графика (квадратный экран)
  // (график интервалов удалён; прогресс отображается в верхнем навигатор-баре)

  const TimerDisplay({
    super.key,
    required this.currentTime,
    required this.currentInterval,
    required this.currentIntervalIndex,
    required this.totalIntervals,
    required this.totalDuration,
    required this.elapsedTime,
    required this.progress,
    this.completedRepetitions,
    this.remainingRepetitions,
    this.nextIntervals,
    this.totalElapsedTime,
    this.totalRemainingTime,
    this.isManualInterval = false,
    this.manualElapsedTime,
    this.isPaused = false,
    this.canGoPrevious = false,
    this.canGoNext = false,
    this.onPreviousInterval,
    this.onNextInterval,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Только секунды для большого дисплея
  String _formatSeconds(int seconds) {
    return seconds.toString();
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



  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final aspectRatio = width / height;
        
        // Определяем тип экрана по соотношению сторон
        final isSquare = aspectRatio >= 0.8 && aspectRatio <= 1.3;
        final isLandscape = aspectRatio > 1.3;
        
        if (isSquare) {
          return _buildSquareLayout(context, constraints);
        } else if (isLandscape) {
          return _buildLandscapeLayout(context, constraints);
        } else {
          return _buildVerticalLayout(context);
        }
      },
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, BoxConstraints constraints) {
    final intervalType = currentInterval?.type ?? IntervalType.work;
    final intervalColor = _getIntervalColor(context, intervalType);
    
    final screenHeight = constraints.maxHeight;
    final timerFontSize = (screenHeight * 0.7).clamp(80.0, 300.0);
    final exerciseFontSize = (screenHeight * 0.2).clamp(36.0, 80.0);
    final repsFontSize = (screenHeight * 0.18).clamp(28.0, 70.0);
    final repsNumberFontSize = repsFontSize * 1.4;
    final repsTextFontSize = repsFontSize * 0.75;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            // Кнопка "Предыдущий" при паузе
            if (isPaused)
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: canGoPrevious ? onPreviousInterval : null,
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 40,
                  color: Colors.blue,
                ),
              )
            else
              const SizedBox(width: 48),
            // Левая часть - таймер (только секунды)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSeconds(currentTime),
                      style: TextStyle(
                        fontSize: timerFontSize,
                        fontWeight: FontWeight.w900,
                        color: intervalColor,
                        shadows: [
                          Shadow(
                            color: intervalColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isManualInterval)
                    Text(
                      'РУЧНОЙ',
                      style: TextStyle(
                        fontSize: 16,
                        color: IntervalColors.of(context).manual,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            // Правая часть - информация
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Название упражнения и повторения
                    if (currentInterval != null &&
                        currentInterval!.type == IntervalType.work &&
                        currentInterval!.name != null) ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currentInterval!.name!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: exerciseFontSize,
                            fontWeight: FontWeight.bold,
                            color: intervalColor,
                          ),
                        ),
                      ),
                      if (currentInterval!.repetitions != null) ...[
                        const SizedBox(height: 2),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${currentInterval!.repetitions}',
                                style: TextStyle(
                                  fontSize: repsNumberFontSize,
                                  color: intervalColor.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: ' пвт.',
                                style: TextStyle(
                                  fontSize: repsTextFontSize,
                                  color: intervalColor.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (currentInterval!.weight != null && currentInterval!.weight! > 0)
                                TextSpan(
                                  text: ' × ${currentInterval!.weight!.toStringAsFixed(1)} кг',
                                  style: TextStyle(
                                    fontSize: repsNumberFontSize,
                                    color: intervalColor.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ] else if (currentInterval!.weight != null && currentInterval!.weight! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${currentInterval!.weight!.toStringAsFixed(1)} кг',
                          style: TextStyle(
                            fontSize: repsNumberFontSize,
                            color: intervalColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ] else if (currentInterval != null && currentInterval!.type != IntervalType.work) ...[
                      Text(
                        currentInterval!.type == IntervalType.rest ? 'ОТДЫХ' : 'ОТДЫХ МЕЖДУ СЕТАМИ',
                        style: TextStyle(
                          fontSize: exerciseFontSize,
                          fontWeight: FontWeight.bold,
                          color: intervalColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Интервал и время
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: intervalColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${currentIntervalIndex + 1} / $totalIntervals',
                            style: TextStyle(
                              fontSize: 16,
                              color: intervalColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (totalElapsedTime != null && totalRemainingTime != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${_formatTime(totalElapsedTime!)} / ${_formatTime(totalElapsedTime! + totalRemainingTime!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Следующие интервалы
                    if (nextIntervals != null && nextIntervals!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Далее: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          ...nextIntervals!.take(2).map((interval) {
                            final color = _getIntervalColor(context, interval.type);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${interval.displayName}${interval.type == IntervalType.work && interval.repetitions != null ? ' ×${interval.repetitions}' : ''}${interval.weight != null && interval.weight! > 0 ? ' ×${interval.weight!.toStringAsFixed(1)}кг' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                    // Статистика по повторениям
                    if (completedRepetitions != null && remainingRepetitions != null &&
                        (completedRepetitions!.isNotEmpty || remainingRepetitions!.isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: [
                          ...completedRepetitions!.entries.map((entry) {
                            final remaining = remainingRepetitions![entry.key] ?? 0;
                            return Text(
                              '${entry.key}: ${entry.value}/${entry.value + remaining}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                    // Прогресс
                    // Прогресс перенесён в верхний навигатор-бар
                  ],
                ),
              ),
            ),
            // Кнопка "Следующий" при паузе
            if (isPaused)
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: canGoNext ? onNextInterval : null,
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 40,
                  color: Colors.blue,
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareLayout(BuildContext context, BoxConstraints constraints) {
    final intervalType = currentInterval?.type ?? IntervalType.work;
    final intervalColor = _getIntervalColor(context, intervalType);
    
    final screenHeight = constraints.maxHeight;
    final timerFontSize = (screenHeight * 0.35).clamp(80.0, 220.0);
    final exerciseFontSize = (screenHeight * 0.12).clamp(36.0, 70.0);
    final repsFontSize = (screenHeight * 0.1).clamp(24.0, 60.0);
    final repsNumberFontSize = repsFontSize * 1.4;
    final repsTextFontSize = repsFontSize * 0.75;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            // Кнопка "Предыдущий" при паузе
            if (isPaused)
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: canGoPrevious ? onPreviousInterval : null,
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 36,
                  color: Colors.blue,
                ),
              )
            else
              const SizedBox(width: 40),
            
            // Основной контент
            Expanded(
              child: Column(
                children: [
                  // Верхняя часть - таймер и информация
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Левая колонка - таймер
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatSeconds(currentTime),
                                  style: TextStyle(
                                    fontSize: timerFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: intervalColor,
                                    shadows: [
                                      Shadow(
                                        color: intervalColor.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isManualInterval)
                                Text(
                                  'РУЧНОЙ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Правая колонка - название и повторения
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (currentInterval != null &&
                                    currentInterval!.type == IntervalType.work &&
                                    currentInterval!.name != null) ...[
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currentInterval!.name!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: exerciseFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: intervalColor,
                                      ),
                                    ),
                                  ),
                                  if (currentInterval!.repetitions != null) ...[
                                    const SizedBox(height: 2),
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${currentInterval!.repetitions}',
                                            style: TextStyle(
                                              fontSize: repsNumberFontSize,
                                              color: intervalColor.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' пвт.',
                                            style: TextStyle(
                                              fontSize: repsTextFontSize,
                                              color: intervalColor.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (currentInterval!.weight != null && currentInterval!.weight! > 0)
                                            TextSpan(
                                              text: ' × ${currentInterval!.weight!.toStringAsFixed(1)} кг',
                                              style: TextStyle(
                                                fontSize: repsNumberFontSize,
                                                color: intervalColor.withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ] else if (currentInterval != null && currentInterval!.type != IntervalType.work) ...[
                                  Text(
                                    currentInterval!.type == IntervalType.rest ? 'ОТДЫХ' : 'ОТДЫХ МЕЖДУ СЕТАМИ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: exerciseFontSize * 0.9,
                                      fontWeight: FontWeight.bold,
                                      color: intervalColor,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                // Интервал и время
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: intervalColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${currentIntervalIndex + 1} / $totalIntervals',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: intervalColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (totalElapsedTime != null && totalRemainingTime != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_formatTime(totalElapsedTime!)} / ${_formatTime(totalElapsedTime! + totalRemainingTime!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Нижняя часть - следующие интервалы и статистика
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        // Следующие интервалы и статистика
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Следующие интервалы
                                  if (nextIntervals != null && nextIntervals!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainer,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Далее:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ...nextIntervals!.take(3).map((interval) {
                                            final color = _getIntervalColor(context, interval.type);
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      '${interval.displayName}${interval.type == IntervalType.work && interval.repetitions != null ? ' ×${interval.repetitions}' : ''}${interval.weight != null && interval.weight! > 0 ? ' ×${interval.weight!.toStringAsFixed(1)}кг' : ''}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (interval.duration != null && interval.duration! > 0)
                                                    Text(
                                                      '${interval.duration}с',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  // Статистика по упражнениям
                                  if (completedRepetitions != null && remainingRepetitions != null &&
                                      (completedRepetitions!.isNotEmpty || remainingRepetitions!.isNotEmpty))
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainer,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Статистика:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ...completedRepetitions!.entries.map((entry) {
                                            final remaining = remainingRepetitions![entry.key] ?? 0;
                                            return Text(
                                              '${entry.key}: ${entry.value}/${entry.value + remaining}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Прогресс перенесён в верхний навигатор-бар
                ],
              ),
            ),
            
            // Кнопка "Следующий" при паузе
            if (isPaused)
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: canGoNext ? onNextInterval : null,
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 36,
                  color: Colors.blue,
                ),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    final intervalType = currentInterval?.type ?? IntervalType.work;
    final intervalColor = _getIntervalColor(context, intervalType);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Адаптивные размеры шрифтов в зависимости от высоты экрана
          final screenHeight = constraints.maxHeight;
          final timerFontSize = (screenHeight * 0.55).clamp(160.0, 450.0);
          final exerciseFontSize = (screenHeight * 0.14).clamp(36.0, 90.0);
          final repsFontSize = (screenHeight * 0.12).clamp(28.0, 75.0);
          final repsNumberFontSize = repsFontSize * 1.4;
          final repsTextFontSize = repsFontSize * 0.75;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Основной дисплей времени - ТОЛЬКО СЕКУНДЫ, очень крупно
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSeconds(currentTime),
                      style: TextStyle(
                        fontSize: timerFontSize,
                        fontWeight: FontWeight.w900,
                        color: intervalColor,
                        shadows: [
                          Shadow(
                            color: intervalColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isManualInterval)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'РУЧНОЙ РЕЖИМ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Название упражнения и количество повторений - КРУПНО
                if (currentInterval != null &&
                    currentInterval!.type == IntervalType.work &&
                    currentInterval!.name != null) ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currentInterval!.name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: exerciseFontSize,
                        fontWeight: FontWeight.bold,
                        color: intervalColor,
                      ),
                    ),
                  ),
                  if (currentInterval!.repetitions != null) ...[
                    const SizedBox(height: 2),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${currentInterval!.repetitions}',
                            style: TextStyle(
                              fontSize: repsNumberFontSize,
                              color: intervalColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: ' пвт.',
                            style: TextStyle(
                              fontSize: repsTextFontSize,
                              color: intervalColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (currentInterval!.weight != null && currentInterval!.weight! > 0)
                            TextSpan(
                              text: ' × ${currentInterval!.weight!.toStringAsFixed(1)} кг',
                              style: TextStyle(
                                fontSize: repsNumberFontSize,
                                color: intervalColor.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else if (currentInterval!.weight != null && currentInterval!.weight! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${currentInterval!.weight!.toStringAsFixed(1)} кг',
                      style: TextStyle(
                        fontSize: repsNumberFontSize,
                        color: intervalColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ] else if (currentInterval != null && currentInterval!.type != IntervalType.work) ...[
                  // Для отдыха показываем тип интервала крупно
                  Text(
                    currentInterval!.type == IntervalType.rest ? 'ОТДЫХ' : 'ОТДЫХ МЕЖДУ СЕТАМИ',
                    style: TextStyle(
                      fontSize: exerciseFontSize * 0.8,
                      fontWeight: FontWeight.bold,
                      color: intervalColor,
                      letterSpacing: 3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Индикатор интервала
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: intervalColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Интервал ${currentIntervalIndex + 1} / $totalIntervals',
                    style: TextStyle(
                      fontSize: 18,
                      color: intervalColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Общее время (прошло/осталось)
                if (totalElapsedTime != null && totalRemainingTime != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(totalElapsedTime!),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' / ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTime(totalElapsedTime! + totalRemainingTime!),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                // Статистика по повторениям (компактная)
                if (completedRepetitions != null && remainingRepetitions != null &&
                    (completedRepetitions!.isNotEmpty || remainingRepetitions!.isNotEmpty)) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        ...completedRepetitions!.entries.map((entry) {
                          final remaining = remainingRepetitions![entry.key] ?? 0;
                          return Text(
                            '${entry.key}: ${entry.value}/${entry.value + remaining}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                        if (remainingRepetitions!.isNotEmpty)
                          ...remainingRepetitions!.entries
                              .where((entry) => !completedRepetitions!.containsKey(entry.key))
                              .map((entry) {
                            return Text(
                              '${entry.key}: 0/${entry.value}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
                // Следующие интервалы (компактная карточка)
                if (nextIntervals != null && nextIntervals!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Далее:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...nextIntervals!.take(2).map((interval) {
                          final color = _getIntervalColor(context, interval.type);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${interval.displayName}${interval.type == IntervalType.work && interval.repetitions != null ? ' ×${interval.repetitions}' : ''}${interval.weight != null && interval.weight! > 0 ? ' ×${interval.weight!.toStringAsFixed(1)}кг' : ''}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (interval.duration != null && interval.duration! > 0)
                                  Text(
                                    '${interval.duration}с',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                // Прогресс перенесён в верхний навигатор-бар
              ],
            ),
          );
        },
      ),
    );
  }

}
