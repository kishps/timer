import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Условный импорт для веб
import 'audio_helper_web.dart' if (dart.library.io) 'audio_helper_stub.dart';

class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();
  static const String _customBeepKey = 'custom_beep_sound';
  static const String _customCountdownKey = 'custom_countdown_sound';
  static bool _initialized = false;

  // Инициализация аудио плеера для фонового воспроизведения
  static Future<void> _initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      // Сначала настраиваем аудио-контекст, чтобы он применялся до всех вызовов play()
      // Настройка аудио-фокуса для Android, чтобы не прерывать фоновую музыку
      // Используем gainTransientMayDuck — звуки воспроизводятся,
      // музыка временно приглушается и не ставится на паузу
      await _player.setAudioContext(
        const AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            // Используем медиа-атрибуты, чтобы звук шел по основному аудио-потоку
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck, // Лёгкое приглушение вместо паузы
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: [],
          ),
        ),
      );
      
      // Для совместимости и стабильности используем mediaPlayer
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      // Освобождаем ресурсы и фокус после завершения звука
      await _player.setReleaseMode(ReleaseMode.release);
      
      if (kDebugMode) {
        print('Аудио плеер инициализирован: gainTransientMayDuck, mediaPlayer, ReleaseMode.release');
      }
      
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации аудио плеера: $e');
        print('Стек ошибки: ${StackTrace.current}');
      }
    }
  }

  // Переинициализация аудио-контекста (для восстановления после потери фокуса)
  static Future<void> reinitialize() async {
    _initialized = false;
    await _initialize();
  }

  // Воспроизведение звука отсчета
  static Future<void> playCountdown() async {
    await _initialize();
    try {
      // Проверяем, есть ли пользовательский звук отсчета
      final prefs = await SharedPreferences.getInstance();
      final customSound = prefs.getString(_customCountdownKey);
      
      if (customSound != null) {
        // Воспроизводим пользовательский звук
        try {
          if (kIsWeb) {
            await _player.play(UrlSource(customSound));
          } else {
            await _player.play(DeviceFileSource(customSound));
          }
          if (kDebugMode) {
            print('Воспроизведен пользовательский звук отсчета: $customSound');
          }
          return;
        } catch (e) {
          if (kDebugMode) {
            print('Не удалось воспроизвести пользовательский звук отсчета: $e');
          }
          // Если пользовательский звук не воспроизводится, пробуем системный
        }
      }
      
      // Пытаемся использовать системный звук из assets (beep.mp3 для отсчета)
      try {
        await _player.play(AssetSource('sounds/beep.mp3'));
        if (kDebugMode) {
          print('Воспроизведен системный звук отсчета: beep.mp3');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Не удалось воспроизвести beep.mp3: $e');
        }
        // Если системный звук не найден, используем fallback
      }
      
      // Fallback: генерация звука или вибрация
      if (kIsWeb) {
        _generateWebBeep(800, 0.1);
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Критическая ошибка при воспроизведении звука отсчета: $e');
      }
      // В крайнем случае используем вибрацию
      if (!kIsWeb) {
        HapticFeedback.lightImpact();
      }
    }
  }

  static Future<void> playStartSound() async {
    await _initialize();
    try {
      // Пытаемся использовать системный звук из assets
      try {
        await _player.play(AssetSource('sounds/start.mp3'));
        if (kDebugMode) {
          print('Воспроизведен звук начала: start.mp3');
        }
        return;
      } catch (e) {
        // Если системный звук не найден, пробуем альтернативный путь
        if (kDebugMode) {
          print('Не удалось воспроизвести start.mp3: $e');
        }
      }
      
      // Fallback: вибрация
      if (!kIsWeb) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // В крайнем случае используем вибрацию
      if (kDebugMode) {
        print('Критическая ошибка при воспроизведении start.mp3: $e');
      }
      if (!kIsWeb) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  static Future<void> playEndSound() async {
    await _initialize();
    try {
      // Пытаемся использовать системный звук из assets
      try {
        await _player.play(AssetSource('sounds/end.mp3'));
        if (kDebugMode) {
          print('Воспроизведен звук завершения: end.mp3');
        }
        return;
      } catch (e) {
        // Если системный звук не найден, пробуем альтернативный путь
        if (kDebugMode) {
          print('Не удалось воспроизвести end.mp3: $e');
        }
      }
      
      // Fallback: вибрация
      if (!kIsWeb) {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // В крайнем случае используем вибрацию
      if (kDebugMode) {
        print('Критическая ошибка при воспроизведении end.mp3: $e');
      }
      if (!kIsWeb) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  static Future<void> playBeep() async {
    await _initialize();
    try {
      // Проверяем, есть ли пользовательский звук
      final prefs = await SharedPreferences.getInstance();
      final customSound = prefs.getString(_customBeepKey);
      
      if (customSound != null) {
        // Воспроизводим пользовательский звук
        try {
          if (kIsWeb) {
            await _player.play(UrlSource(customSound));
          } else {
            await _player.play(DeviceFileSource(customSound));
          }
          if (kDebugMode) {
            print('Воспроизведен пользовательский звук beep: $customSound');
          }
          return;
        } catch (e) {
          if (kDebugMode) {
            print('Не удалось воспроизвести пользовательский звук beep: $e');
          }
          // Если пользовательский звук не воспроизводится, пробуем системный
        }
      }
      
      // Пытаемся использовать системный звук из assets
      try {
        await _player.play(AssetSource('sounds/beep.mp3'));
        if (kDebugMode) {
          print('Воспроизведен системный звук beep: beep.mp3');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Не удалось воспроизвести beep.mp3: $e');
        }
        // Если системный звук не найден, используем fallback
      }
      
      // Fallback: генерация звука или вибрация
      if (kIsWeb) {
        _generateWebBeep(600, 0.1);
      } else {
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Критическая ошибка при воспроизведении beep: $e');
      }
      // В крайнем случае используем вибрацию
      if (!kIsWeb) {
        HapticFeedback.selectionClick();
      }
    }
  }

  // Сохранение пользовательского звука
  static Future<bool> saveCustomSound(String soundType, String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = soundType == 'beep' ? _customBeepKey : _customCountdownKey;
      
      if (kIsWeb) {
        // На веб сохраняем путь как есть (file_picker возвращает путь для веб)
        await prefs.setString(key, filePath);
      } else {
        // На мобильных/десктоп платформах сохраняем путь к файлу
        await prefs.setString(key, filePath);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Удаление пользовательского звука
  static Future<void> removeCustomSound(String soundType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = soundType == 'beep' ? _customBeepKey : _customCountdownKey;
    await prefs.remove(key);
  }

  // Проверка наличия пользовательского звука
  static Future<bool> hasCustomSound(String soundType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = soundType == 'beep' ? _customBeepKey : _customCountdownKey;
    return prefs.containsKey(key);
  }

  // Генерация простого звука для веб-платформы через Web Audio API
  static void _generateWebBeep(int frequency, double duration) {
    if (!kIsWeb) return;
    
    try {
      // Используем условный импорт для веб
      generateWebBeep(frequency, duration);
    } catch (e) {
      // Игнорируем ошибки генерации звука
    }
  }

  static Future<void> playIntervalWork() async {
    await _initialize();
    try {
      // Пытаемся использовать системный звук из assets
      try {
        await _player.play(AssetSource('sounds/interval_work.mp3'));
        if (kDebugMode) {
          print('Воспроизведен звук интервала работы: interval_work.mp3');
        }
        return;
      } catch (e) {
        // Если системный звук не найден, используем fallback
        if (kDebugMode) {
          print('Не удалось воспроизвести interval_work.mp3: $e');
        }
      }
      
      // Fallback: вибрация
      if (!kIsWeb) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // В крайнем случае используем вибрацию
      if (kDebugMode) {
        print('Критическая ошибка при воспроизведении interval_work.mp3: $e');
      }
      if (!kIsWeb) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  static Future<void> playIntervalRest() async {
    await _initialize();
    try {
      // Пытаемся использовать системный звук из assets
      try {
        await _player.play(AssetSource('sounds/interval_rest.mp3'));
        if (kDebugMode) {
          print('Воспроизведен звук интервала отдыха: interval_rest.mp3');
        }
        return;
      } catch (e) {
        // Если системный звук не найден, используем fallback
        if (kDebugMode) {
          print('Не удалось воспроизвести interval_rest.mp3: $e');
        }
      }
      
      // Fallback: вибрация
      if (!kIsWeb) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // В крайнем случае используем вибрацию
      if (kDebugMode) {
        print('Критическая ошибка при воспроизведении interval_rest.mp3: $e');
      }
      if (!kIsWeb) {
        HapticFeedback.lightImpact();
      }
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
