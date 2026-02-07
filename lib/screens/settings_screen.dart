import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/timer_config.dart';
import '../services/storage_service.dart';
import '../utils/audio_helper.dart';
import '../widgets/workout_navigator_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  late TimerConfig _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _storageService.loadConfig();
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    await _storageService.saveConfig(_config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const WorkoutNavigatorBar(margin: EdgeInsets.zero),
          const SizedBox(height: 12),
          // Звуковые сигналы
          Card(
            child: SwitchListTile(
              title: const Text(
                'Звуковые сигналы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text('Воспроизводить звук при смене интервалов'),
              value: _config.soundEnabled,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(soundEnabled: value);
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Звук отсчета
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Звук отсчета',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Воспроизводить звук за несколько секунд до конца интервала'),
                    value: _config.countdownSoundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(countdownSoundEnabled: value);
                      });
                    },
                  ),
                  if (_config.countdownSoundEnabled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'За сколько секунд начинать отсчет',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_config.countdownSeconds} секунд',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _config.countdownSeconds.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${_config.countdownSeconds}',
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(
                            countdownSeconds: value.toInt(),
                          );
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Пользовательские звуки
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Пользовательские звуки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSoundSelector('Звук смены интервала', 'beep'),
                  const SizedBox(height: 16),
                  _buildSoundSelector('Звук отсчета', 'countdown'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSelector(String title, String soundType) {
    return FutureBuilder<bool>(
      future: AudioHelper.hasCustomSound(soundType),
      builder: (context, snapshot) {
        final hasCustom = snapshot.data ?? false;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadCustomSound(soundType),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Загрузить звук'),
                  ),
                ),
                if (hasCustom) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _removeCustomSound(soundType),
                      icon: const Icon(Icons.delete),
                      label: const Text('Удалить'),
                    ),
                  ),
                ],
              ],
            ),
            if (hasCustom)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Используется пользовательский звук',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _loadCustomSound(String soundType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['mp3', 'wav', 'ogg'],
      );

      if (result != null) {
        String? filePath;
        
        if (kIsWeb) {
          // На веб конвертируем файл в data URL
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            final base64 = base64Encode(bytes);
            final extension = result.files.single.extension ?? 'mp3';
            filePath = 'data:audio/$extension;base64,$base64';
          }
        } else {
          // На мобильных/десктоп используем путь к файлу
          filePath = result.files.single.path;
        }
        
        if (filePath != null) {
          final success = await AudioHelper.saveCustomSound(soundType, filePath);
          
          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Звук "$soundType" загружен')),
              );
              setState(() {}); // Обновляем UI
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка при загрузке звука')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _removeCustomSound(String soundType) async {
    await AudioHelper.removeCustomSound(soundType);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пользовательский звук "$soundType" удален')),
      );
      setState(() {}); // Обновляем UI
    }
  }
}
