// Условный импорт для веб-платформы
import 'dart:js' as js;

void generateWebBeep(int frequency, double duration) {
  try {
    final window = js.context['window'];
    final AudioContext = window['AudioContext'] ?? window['webkitAudioContext'];
    if (AudioContext == null) return;
    
    final context = AudioContext.callMethod('new', []);
    final oscillator = context.callMethod('createOscillator', []);
    final gainNode = context.callMethod('createGain', []);
    
    oscillator.callMethod('connect', [gainNode]);
    gainNode.callMethod('connect', [context['destination']]);
    
    oscillator['frequency']['value'] = frequency;
    oscillator['type'] = 'sine';
    
    final currentTime = context['currentTime'];
    gainNode['gain']['setValueAtTime'](0.3, currentTime);
    gainNode['gain']['exponentialRampToValueAtTime'](0.01, currentTime + duration);
    
    oscillator.callMethod('start', [currentTime]);
    oscillator.callMethod('stop', [currentTime + duration]);
  } catch (e) {
    // Игнорируем ошибки генерации звука
  }
}
