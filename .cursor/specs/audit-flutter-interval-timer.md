# Audit: Интервальный таймер тренировок (Flutter)

## 1. Summary

- Клиентское Flutter-приложение «Интервальный таймер»: последовательность интервалов работы, отдыха и отдыха между сетами с таймером, звуковыми сигналами и блокировкой засыпания экрана во время активной тренировки.
- Основной пользовательский сценарий — **шаблоны тренировок** (`WorkoutTemplate`): редактирование цепочки интервалов, предпросмотр перед стартом, прохождение с автоматическим переходом по длительности или **ручным** переходом для интервалов без времени.
- Данные **только локально**: `SharedPreferences` (JSON): настройки таймера, история сессий, шаблоны, история упражнений; опционально пользовательские звуковые файлы (частично в prefs / платформенное хранилище через `AudioHelper`).
- Экран **Прогресс** агрегирует историю и строит сравнение последних сессий по выбранному шаблону (дельты, тренды, условные «рекорды» по упражнениям в рамках шаблона).
- Внешних API и учётных записей нет; пользователь — конечный спортсмен на устройстве.

## 2. Entry Points

| Триггер | Описание |
|--------|-----------|
| `void main()` в `lib/main.dart` | Инициализация биндинга, разрешённые ориентации портрет/альбом, `runApp(TimerApp)`. |
| `TimerApp` | Создаёт `TimerService`, оборачивает дерево в `TimerServiceScope`, `MaterialApp` с `home: HomeScreen(timerService: ...)`. |
| `HomeScreen` | Главный экран: список шаблонов (idle + нет активного шаблона) или `TimerDisplay`; переходы `Navigator.push` к настройкам, истории, шаблонам, прогрессу; `PreWorkoutScreen` перед стартом при выбранном шаблоне. |
| `WorkoutTemplatesScreen` | Список шаблонов, создание/редактирование, импорт/экспорт JSON; «Запуск» через `Navigator.pushReplacement` на `HomeScreen(selectedTemplate: …)`. |
| `WorkoutTemplateEditorScreen` | Создание/изменение шаблона и интервалов, сохранение через `StorageService.saveTemplate`. |
| `PreWorkoutScreen` | Перед стартом: правка повторов/веса по рабочим интервалам; возврат `updatedTemplate` в `HomeScreen`. |
| `SettingsScreen` | Редактирование `TimerConfig`, пользовательские звуки; `Navigator.pop(context, true)` после сохранения. |
| `HistoryScreen` | Просмотр/удаление сессий, импорт/экспорт истории JSON. |
| `ProgressScreen` | Фильтр по шаблону, агрегаты `getProgressStats` / `getTemplateComparisonStats`. |

Именованных маршрутов (`onGenerateRoute`) нет — только `MaterialPageRoute`.

## 3. Core Flow

### 3.1 Загрузка приложения и конфигурация

1. `main` → `TimerApp.initState` создаёт `TimerService`.
2. `HomeScreen.initState` → `_loadConfig()` или `_loadConfigForTemplate()` если передан `selectedTemplate`.
3. `_loadConfig` / `_loadConfigForTemplate` вызывают `StorageService.loadConfig()`, `AudioHelper.applyDuckExternalAudioSetting`, `TimerService.warmupManualIntervalEstimates(storage)` (оценки длительности ручных интервалов из истории), затем `initialize(config)` или `initializeWithTemplate(template, …)`.
4. Колбэки таймера вешаются в `_setupTimerCallbacks`: `onTick`, `onIntervalChange` (haptic), `onFinished` → `_saveWorkoutSession` + диалог.

### 3.2 Выбор шаблона и старт тренировки с домашнего экрана

1. Пользователь выбирает карточку шаблона → `_startWorkout` обновляет `lastUsed`, подмешивает настройки звука, `initializeWithTemplate`.
2. «Старт» в `ControlButtons.onStart`: при `template != null` и `idle` открывается `PreWorkoutScreen`; при возврате с `updatedTemplate` шаблон сохраняется, сервис переинициализируется, вызывается `start()`.
3. `TimerService.start`: сброс статистики при первом запуске из idle/finished, `WakelockPlus.enable`, звуки `AudioHelper.playStartSound` / `playInterval*`, установка индекса интервала и `_startTimer`.

### 3.3 Тик таймера и смена интервалов

1. `_startTimer`: для интервала с `duration == null` или `0` — периодический таймер обновляет прошедшее время от `_manualIntervalStartTime`; иначе секундный обратный отсчёт.
2. При обратном отсчёте и `_countdownSoundEnabled`: в последние `countdownSeconds` секунд вызывается `AudioHelper.playCountdown`.
3. По достижении нуля `_handleIntervalComplete`: учёт повторов/веса для завершённого work-интервала, `_saveCurrentIntervalStat`, переход к следующему или `_finishWorkout`.
4. Ручной переход: `nextInterval` / `previousInterval` (кнопки UI / большая кнопка «следующий интервал» для ручного интервала в работе).

### 3.4 Пауза и возобновление

1. `pause`: отмена таймера, `TimerState.paused`, `WakelockPlus.disable`, для ручного интервала `_currentTime` сохраняется как прошедшее время; `_saveCurrentIntervalStat`.
2. `resume`: восстановление `manualIntervalStartTime` с учётом уже накопленных секунд, `WakelockPlus` снова при следующем `start`-цикле не вызывается в resume — но `resume` вызывает `_startTimer`; wake lock включается в `start` при первом запуске и в ветке paused при `start` — в `resume` разблокировка не снимается явно; при `resume` состояние `running` и снова периодический таймер. (Wake lock: `pause` отключает, при `resume` код не вызывает `WakelockPlus.enable` напрямую — поведение стоит трактовать по фактическому коду чтения `pause`/`resume`/`start`: после `resume` wakelock может оставаться выключенным до следующего полного `start` из idle.)

Уточнение по коду: в `resume` нет вызова `WakelockPlus.enable`; он есть в `start` для веток idle/finished и paused при входе в running — но ветка `paused` в `start` делает enable только внутри `start()`, не в `resume()`. Фактически после `pause` → `resume` экран может не удерживаться wake lock до следующего условия, где вызывается enable. Это отражено как наблюдаемое поведение реализации.

### 3.5 Завершение тренировки

1. Автоматически: последний интервал обработан → `_finishWorkout` → звук окончания, `TimerState.finished`, колбэк `onFinished`.
2. `onFinished` в `HomeScreen`: `_saveWorkoutSession`, диалог «Тренировка завершена», `invalidateManualIntervalEstimates` после сохранения сессии (в `_saveWorkoutSession`).
3. `_saveWorkoutSession`: `totalDuration` как сумма `intervalStats.actualDuration` либо fallback `getElapsedTime()`; для шаблона — обновление `exercise_history` по каждому упражнению из `exercisesCompleted`, сбор `WorkoutSession` с `intervalStats`, `saveSession`.
4. Ручное завершение: диалог с чекбоксом «Сохранить в истории», при подтверждении опционально `_saveWorkoutSession`, затем `reset`.

### 3.6 Настройки и звук

1. `SettingsScreen` загружает `TimerConfig`, правки в состоянии; «Сохранить» → `saveConfig`, `AudioHelper.applyDuckExternalAudioSetting`, snackbar, `pop(true)`.
2. Пользовательские звуки: `FilePicker` (audio), на web — data URL в base64; `AudioHelper.saveCustomSound` / `removeCustomSound`.

### 3.7 История и шаблоны: импорт/экспорт

1. **История** (`HistoryScreen`): экспорт объекта `{ workouts, exportDate, version }`; импорт — поле `workouts` или сырой список; слияние по `id` через `updateSession` или `saveSession`.
2. **Шаблоны** (`WorkoutTemplatesScreen`): экспорт `{ templates, exportDate, version }`; импорт — ключ `templates` или список; некорректные элементы пропускаются с snackbar; затем `saveTemplate` для каждого (подсчёт updated/added по наличию id в множестве).

### 3.8 Прогресс

1. `ProgressScreen._loadData` загружает сессии и шаблоны, `getProgressStats` (опционально `templateId`), при выбранном шаблоне — `getTemplateComparisonStats(templateId, lookback: 10)`.
2. UI строится на этих структурах (дельты сессий, diff по упражнениям, трендовые ряды, PR-карты из кода агрегации).

## 4. File Map

### 4.1 Точка входа и тема

| File | Purpose | Notes |
|------|---------|-------|
| `lib/main.dart` | `main`, `TimerApp`, тема M3, `IntervalColors` extension, `ThemeMode.dark` по умолчанию | Портрет и альбом разрешены. |

### 4.2 Экраны

| File | Purpose | Notes |
|------|---------|-------|
| `lib/screens/home_screen.dart` | Главный экран, колбэки таймера, сохранение сессии, навигация | `WidgetsBindingObserver` для resume + wakelock/audio. |
| `lib/screens/settings_screen.dart` | Настройки звука, отсчёта, duck (Android), кастомные звуки | |
| `lib/screens/history_screen.dart` | История сессий, экспорт/импорт JSON | |
| `lib/screens/workout_templates_screen.dart` | Список шаблонов, CRUD навигация, экспорт/импорт, старт → Home | |
| `lib/screens/workout_template_editor_screen.dart` | Редактор шаблонов и интервалов | Крупный файл с локальными виджетами ввода. |
| `lib/screens/pre_workout_screen.dart` | Предстартовая правка повторов/веса | |
| `lib/screens/progress_screen.dart` | Статистика и сравнение по шаблону | Много UI-логики. |

### 4.3 Сервисы

| File | Purpose | Notes |
|------|---------|-------|
| `lib/services/timer_service.dart` | Движок таймера и статистики сессии | `ChangeNotifier`, ~770 строк. |
| `lib/services/storage_service.dart` | Чтение/запись JSON в SharedPreferences, агрегаты прогресса | |

### 4.4 Модели

| File | Purpose | Notes |
|------|---------|-------|
| `lib/models/timer_config.dart` | Классический табата-подобный конфиг + поля звука | |
| `lib/models/workout_template.dart` | Шаблон тренировки | |
| `lib/models/workout_interval.dart` | Интервал, `IntervalType` | `duration` null/0 — ручной режим по соглашению с `TimerService`. |
| `lib/models/workout_session.dart` | Запись истории | Поля для шаблона и legacy rounds/work/rest. |
| `lib/models/interval_stat.dart` | Статистика по одному интервалу в сессии | `plannedDuration == 0` маркирует ручной в оценках. |
| `lib/models/exercise_history.dart` | Последние повторы/вес по имени | |

### 4.5 Виджеты

| File | Purpose | Notes |
|------|---------|-------|
| `lib/widgets/timer_service_scope.dart` | `InheritedNotifier<TimerService>` | Статический `of(context)`. |
| `lib/widgets/timer_display.dart` | Отображение времени и прогресса | |
| `lib/widgets/control_buttons.dart` | Старт/пауза/продолжить/финиш, слот для «следующий интервал» | |
| `lib/widgets/workout_navigator_bar.dart` | Навигационный блок (используется на нескольких экранах) | |
| `lib/widgets/intervals_scroll_list.dart` | Список интервалов | |
| `lib/widgets/app_scaffold.dart` | Общий каркас | |
| `lib/widgets/primary_action_bar.dart` | Панель действий | |
| `lib/widgets/section_card.dart` | Карточка секции | |
| `lib/widgets/empty_state.dart` | Пустое состояние | |

### 4.6 Утилиты и условные импорты

| File | Purpose | Notes |
|------|---------|-------|
| `lib/utils/audio_helper.dart` | Воспроизведение, кастомные треки, Android audio focus | Условные части web/stub. |
| `lib/utils/audio_helper_web.dart` | Web-реализация | |
| `lib/utils/audio_helper_stub.dart` | Не-web заглушка для экспорта символов | |
| `lib/utils/web_file_helper.dart` | Условный экспорт web/io | |
| `lib/utils/web_file_helper_web.dart` | Скачивание на web | |
| `lib/utils/web_file_helper_stub.dart` | | |
| `lib/utils/io_file_helper.dart` | Условный импорт io | |
| `lib/utils/io_file_helper_io.dart` | Файлы на io | |
| `lib/utils/io_file_helper_stub.dart` | | |

### 4.7 Тема

| File | Purpose | Notes |
|------|---------|-------|
| `lib/theme/interval_colors.dart` | `ThemeExtension` цветов интервалов | |

### 4.8 Тесты

| File | Purpose | Notes |
|------|---------|-------|
| `test/widget_test.dart` | Проверка монтирования `TimerApp` | |

### 4.9 Прочее репозитория (не код приложения)

- `pubspec.yaml`, `assets/sounds/`, дизайн-артефакты (`designs/`, `figma_scripts/`) в аудите логики приложения не разбираются пошагово; зависимости перечислены в разделе 7.

**Количество задокументированных dart-файлов:** 35 под `lib/` + 1 `test/widget_test.dart` = **36** файлов по текущей структуре репозитория.

## 5. Data Model

Хранилище: **SharedPreferences**, строковые ключи:

- `timer_config` — JSON `TimerConfig`.
- `workout_history` — JSON-массив `WorkoutSession` (новые сессии через `saveSession` вставляются в начало списка).
- `workout_templates` — JSON-массив `WorkoutTemplate` (сохранение через удаление прежнего с тем же `id` и добавление).
- `exercise_history` — JSON-массив `ExerciseHistory`.

Основные поля сущностей:

- **WorkoutSession:** `id`, `dateTime`, `totalDuration`, legacy `rounds` / `workDuration` / `restDuration`; для шаблонов — `workoutTemplateId`, `workoutName`, опционально `exercisesCompleted`, `totalRepetitions`, `totalWeight`, `exercisesWithWeight`, `intervalStats`.
- **IntervalStat:** привязка к индексу интервала, тип, имя, planned/actual duration, повторы, вес.
- **WorkoutInterval:** тип, длительность, порядок `order`, имя/повторы/вес для work.

Индексы БД отсутствуют. Объём данных ограничен возможностями prefs на платформе.

## 6. Configuration and Environment

- Переменные окружения не используются.
- **TimerConfig:** длительности work/rest, число раундов, `soundEnabled`, `countdownSoundEnabled`, `countdownSeconds` (1–10 в UI слайдера), `duckExternalAudio` (переключатель только на не-web Android).
- Ключи пользовательских звуков в `AudioHelper` (строковые константы для prefs).
- Версия приложения: `pubspec.yaml` (`1.0.1+4` на момент аудита).

## 7. External Dependencies

| Зависимость | Роль |
|-------------|------|
| `shared_preferences` | Локальное KV-хранилище |
| `audioplayers` | Звуки интервалов и кастомные файлы |
| `intl` | Форматирование дат в моделях/UI |
| `file_picker` | Выбор файлов звука, сохранение/загрузка экспортов |
| `wakelock_plus` | Удержание экрана при активной тренировке |
| `flutter_svg` | SVG-ресурсы (если подключены в UI) |

При ошибках JSON в `StorageService.loadConfig/loadHistory/loadTemplates` возвращаются значения по умолчанию или пустые списки (catch с fallback). Импорт показывает snackbar/dialog с ошибкой или счётчиками.

## 8. Business Rules

- Интервалы сортируются по полю `order` при инициализации из шаблона.
- **Ручной интервал:** `duration == null` или `0`; автоматический переход по таймеру в `_handleIntervalComplete` для него не выполняется; время фиксируется через `_manualIntervalStartTime` / `getManualIntervalElapsedTime`.
- В **оценке оставшегося времени** для ручных интервалов: усреднение по истории (по имени work, по шаблону+типу, по типу); fallback секунды: work 45, rest 15, restBetweenSets 60 (константы в `_estimateManualIntervalDuration`).
- **IntervalStat для ручных:** в истории сессий признак ручного интервала в расчётах оценок — `plannedDuration == 0` (в коде `warmupManualIntervalEstimates` отбрасываются записи с `plannedDuration != 0`).
- **Прогресс по работе:** `getProgress()` = доля завершённых work-интервалов от общего числа work-интервалов (по индексу, не по времени).
- **Принудительное завершение:** пользователь может не сохранять сессию (чекбокс в диалоге).
- **Сравнение шаблонов** (`getTemplateComparisonStats`): сессии фильтру по `workoutTemplateId`, сортировка по дате убыванию; агрегация упражнений только из `IntervalStat` типа `work` с непустым именем; PR считаются по всем сессиям шаблона в памяти после фильтра.

## 9. Known Issues and Technical Debt

- В `TimerService.previousInterval` комментарий о **упрощённой логике** удаления статистики при шаге назад — откат интервала не восстанавливает `_intervalStats` полностью согласованно с предыдущим состоянием.
- После **`resume`** wake lock не включается явно (в отличие от веток в `start`); фактическое поведение — экран может гаснуть в зависимости от ОС до следующего полного цикла `start`.
- Диалог импорта шаблонов дублирует текст «тренировок» в сообщении счётчиков (косметика строк).
- Маркеров `TODO`/`FIXME`/`HACK` в `lib/` при сканировании не найдено.
- Ограничение размера истории/шаблонов в одной строке prefs не реализовано — риск для очень больших данных на устройстве.

## 10. Tests

- Единственный тест: `test/widget_test.dart` — монтирование `TimerApp`, наличие `MaterialApp`; не проверяется `HomeScreen`, таймер, хранилище.
- Нет unit-тестов `TimerService` / `StorageService`.
- Нет интеграционных тестов импорта/экспорта.

## 11. Observations

- Архитектура **монолитная**, вся бизнес-логика таймера сосредоточена в одном `TimerService` с UI-колбэками; экраны напрямую вызывают сервис и `StorageService`.
- Разделение **шаблонный vs классический `TimerConfig`** сохранено в коде (`initialize` / `initializeWithTemplate`); на главном экране в состоянии `idle` без выбранного шаблона отображается список шаблонов или пустое состояние, а **панель управления** показывается только если `template != null` или состояние таймера не `idle`. Сценарий старта **только** из сохранённого `TimerConfig` без шаблона на домашнем экране **не представлен в UI** (при этом `_config` загружается и передаётся в `initialize`).

## 12. Open Questions

1. Нужен ли пользователям по продуктовым планам **классический режим** только из `TimerConfig` без шаблона — и должен ли он быть доступен с главного экрана?
2. Целевой набор платформ для поддержки (web/mobile/desktop) и ожидаемые лимиты размера истории.
3. Должен ли wake lock оставаться включённым после `resume` — намерение не выражено в коде явно.

---

*Документ составлен по состоянию кодовой базы репозитория; уточняющие раунды с владельцем продукта не проводились (0 раундов).*
