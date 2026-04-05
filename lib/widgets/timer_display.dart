import 'package:flutter/material.dart';
import '../models/workout_interval.dart';
import '../theme/interval_colors.dart';
import 'intervals_scroll_list.dart';

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
  final List<WorkoutInterval>? allIntervals;
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
    this.allIntervals,
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
    final s = seconds < 0 ? 0 : seconds;
    final minutes = s ~/ 60;
    final secs = s % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatWeight(double weight) {
    if (weight == weight.truncateToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
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

  Widget _buildBottomTabs(BuildContext context, BoxConstraints constraints) {
    final hasIntervals = allIntervals != null && allIntervals!.isNotEmpty;

    if (!hasIntervals) {
      return SingleChildScrollView(
        child: _buildStatsContainer(context),
      );
    }

    return LayoutBuilder(
      builder: (context, tabConstraints) {
        if (tabConstraints.maxHeight < 80) {
          return const SizedBox.shrink();
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Интервалы'),
                  Tab(text: 'Статистика'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: IntervalsScrollList(
                        intervals: allIntervals!,
                        currentIndex: currentIntervalIndex,
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, viewportConstraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight,
                            ),
                            child: _buildStatsContainer(context),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsContainer(BuildContext context) {
    final intervalType = currentInterval?.type ?? IntervalType.work;
    final intervalColor = _getIntervalColor(context, intervalType);
    final hasStats = (completedRepetitions != null && completedRepetitions!.isNotEmpty) ||
                     (remainingRepetitions != null && remainingRepetitions!.isNotEmpty);

    final List<TableRow> statRows = [];
    if (hasStats) {
      if (completedRepetitions != null) {
        for (var entry in completedRepetitions!.entries) {
          final remaining = remainingRepetitions?[entry.key] ?? 0;
          statRows.add(
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${entry.value} / ${entry.value + remaining}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
      
      if (remainingRepetitions != null) {
        final remainingOnly = remainingRepetitions!.entries.where(
          (entry) => completedRepetitions == null || !completedRepetitions!.containsKey(entry.key)
        );
        for (var entry in remainingOnly) {
          statRows.add(
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '0 / ${entry.value}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Интервал и время
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Интервал:',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: intervalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentIntervalIndex + 1} / ${totalIntervals > 0 ? totalIntervals : 1}',
                  style: TextStyle(
                    fontSize: 14,
                    color: intervalColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (totalElapsedTime != null && totalRemainingTime != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Время:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${_formatTime(totalElapsedTime!)} / ${_formatTime(totalElapsedTime! + totalRemainingTime!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (hasStats && statRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
              },
              children: statRows,
            ),
          ],
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }
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
    final timerFontSize =
        ((screenHeight * 0.95).clamp(90.0, 400.0)) * 1.5;
    final exerciseFontSize = (screenHeight * 0.2).clamp(36.0, 80.0);
    final repsFontSize = (screenHeight * 0.26).clamp(40.0, 100.0);
    final repsNumberFontSize = repsFontSize * 1.4;

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
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.6,
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
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
              ),
            ),
            // Правая часть - информация
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (currentInterval != null &&
                      currentInterval!.type == IntervalType.work &&
                      currentInterval!.name != null) ...[
                    Flexible(
                      fit: FlexFit.loose,
                      child: FittedBox(
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
                    ),
                    if (currentInterval!.repetitions != null) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        fit: FlexFit.loose,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            softWrap: false,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${currentInterval!.repetitions}',
                                  style: TextStyle(
                                    fontSize: repsNumberFontSize,
                                    color: intervalColor.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (currentInterval!.weight != null &&
                                    currentInterval!.weight! > 0)
                                  TextSpan(
                                    text:
                                        '\u00A0×\u00A0${_formatWeight(currentInterval!.weight!)}\u00A0кг',
                                    style: TextStyle(
                                      fontSize: repsNumberFontSize,
                                      color: intervalColor.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else if (currentInterval != null &&
                        currentInterval!.weight != null &&
                        currentInterval!.weight! > 0) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        fit: FlexFit.loose,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${_formatWeight(currentInterval!.weight!)}\u00A0кг',
                            style: TextStyle(
                              fontSize: repsNumberFontSize,
                              color: intervalColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else if (currentInterval != null &&
                      currentInterval!.type != IntervalType.work) ...[
                    Flexible(
                      fit: FlexFit.loose,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currentInterval!.type == IntervalType.rest
                              ? 'ОТДЫХ'
                              : 'ОТДЫХ МЕЖДУ СЕТАМИ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: exerciseFontSize,
                            fontWeight: FontWeight.bold,
                            color: intervalColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildBottomTabs(context, constraints),
                  ),
                ],
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
    final timerFontSize =
        ((screenHeight * 0.55).clamp(100.0, 300.0)) * 1.5;
    final exerciseFontSize = (screenHeight * 0.12).clamp(36.0, 70.0);
    final repsFontSize = (screenHeight * 0.15).clamp(40.0, 90.0);
    final repsNumberFontSize = repsFontSize * 1.4;

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
                    flex: 2,
                    child: Row(
                      children: [
                        // Левая колонка - таймер
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: screenHeight * 0.22,
                              ),
                              child: FittedBox(
                                fit: BoxFit.contain,
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
                            ),
                          ),
                        ),
                        // Правая колонка - название и повторения
                        Expanded(
                          flex: 3,
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
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      softWrap: false,
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
                                          if (currentInterval!.weight != null && currentInterval!.weight! > 0)
                                            TextSpan(
                                              text: '\u00A0×\u00A0${_formatWeight(currentInterval!.weight!)}\u00A0кг',
                                              style: TextStyle(
                                                fontSize: repsNumberFontSize,
                                                color: intervalColor.withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                        ],
                                      ),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Нижняя часть - следующие интервалы и статистика
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Следующие интервалы и статистика
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildBottomTabs(context, constraints),
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
          final timerFontSize =
              ((screenHeight * 0.55).clamp(140.0, 400.0)) * 1.5;
          final exerciseFontSize = (screenHeight * 0.06).clamp(24.0, 48.0);
          final repsFontSize = (screenHeight * 0.09).clamp(32.0, 65.0);
          final repsNumberFontSize = repsFontSize * 1.4;
          
          // Безопасное вычисление высоты, чтобы избежать overflow на очень маленьких экранах
          final minTimerHeight = 150.0 < screenHeight * 0.5 ? 150.0 : screenHeight * 0.5;
          final timerBlockHeight = (screenHeight * 0.26).clamp(minTimerHeight, 280.0);

          return Column(
            children: [
              SizedBox(
                height: timerBlockHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    Expanded(
                      child: Padding(
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
                    ),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
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
                                  text:
                                      '${currentInterval!.repetitions}',
                                  style: TextStyle(
                                    fontSize: repsNumberFontSize,
                                    color: intervalColor.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (currentInterval!.weight != null &&
                                    currentInterval!.weight! > 0)
                                  TextSpan(
                                    text:
                                        '\u00A0×\u00A0${_formatWeight(currentInterval!.weight!)}\u00A0кг',
                                    style: TextStyle(
                                      fontSize: repsNumberFontSize,
                                      color: intervalColor.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else if (currentInterval!.weight != null &&
                            currentInterval!.weight! > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${_formatWeight(currentInterval!.weight!)}\u00A0кг',
                            style: TextStyle(
                              fontSize: repsNumberFontSize,
                              color: intervalColor.withValues(
                                alpha: 0.9,
                              ),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ] else if (currentInterval != null &&
                          currentInterval!.type !=
                              IntervalType.work) ...[
                        // Для отдыха показываем тип интервала крупно
                        Text(
                          currentInterval!.type == IntervalType.rest
                              ? 'ОТДЫХ'
                              : 'ОТДЫХ МЕЖДУ СЕТАМИ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: exerciseFontSize * 0.8,
                            fontWeight: FontWeight.bold,
                            color: intervalColor,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildBottomTabs(context, constraints),
                      ),
                      // Прогресс перенесён в верхний навигатор-бар
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}
