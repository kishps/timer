import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/interval_colors.dart';
import 'services/timer_service.dart';
import 'widgets/timer_service_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TimerApp());
}

class TimerApp extends StatefulWidget {
  const TimerApp({super.key});

  @override
  State<TimerApp> createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  late final TimerService _timerService;

  @override
  void initState() {
    super.initState();
    _timerService = TimerService();
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
    );

    final cs = base.colorScheme;

    // Athletic акценты интервалов (используем по месту через helper).
    const workColor = Color(0xFFE53935);
    const restColor = Color(0xFF43A047);
    const betweenSetsColor = Color(0xFF1E88E5);

    // Тёмный «athletic» = более тёмные поверхности + чуть «холоднее» нейтрали.
    final surface = brightness == Brightness.dark
        ? const Color(0xFF0B0F14)
        : cs.surface;
    final surfaceContainer = brightness == Brightness.dark
        ? const Color(0xFF111823)
        : cs.surfaceContainer;
    final surfaceContainerHigh = brightness == Brightness.dark
        ? const Color(0xFF162031)
        : cs.surfaceContainerHigh;

    final tunedScheme = cs.copyWith(
      surface: surface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      // Для тёмной темы чуть подсветим primary, чтобы лучше читалось на фоне.
      primary: brightness == Brightness.dark ? const Color(0xFF8AB4FF) : cs.primary,
      secondary: brightness == Brightness.dark ? const Color(0xFF7BE0B4) : cs.secondary,
    );

    final textTheme = base.textTheme.copyWith(
      // Чуть более «плотная» типографика под спортивный стиль.
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    return base.copyWith(
      colorScheme: tunedScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: tunedScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: tunedScheme.surface,
        foregroundColor: tunedScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: tunedScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: tunedScheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tunedScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: tunedScheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tunedScheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tunedScheme.surfaceContainerHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tunedScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tunedScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tunedScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tunedScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tunedScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: tunedScheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tunedScheme.primary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tunedScheme.outlineVariant.withValues(
          alpha: brightness == Brightness.dark ? 0.6 : 1,
        ),
        thickness: 1,
        space: 1,
      ),
      extensions: <ThemeExtension<dynamic>>[
        const IntervalColors(
          work: workColor,
          rest: restColor,
          restBetweenSets: betweenSetsColor,
          manual: Color(0xFFFF9800),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TimerServiceScope(
      notifier: _timerService,
      child: MaterialApp(
        title: 'Интервальный таймер',
        theme: _buildTheme(brightness: Brightness.light, seedColor: const Color(0xFF8AB4FF)),
        darkTheme: _buildTheme(brightness: Brightness.dark, seedColor: const Color(0xFF8AB4FF)),
        themeMode: ThemeMode.dark,
        home: HomeScreen(timerService: _timerService),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
