import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class TimerServiceScope extends InheritedNotifier<TimerService> {
  const TimerServiceScope({
    super.key,
    required TimerService notifier,
    required super.child,
  }) : super(notifier: notifier);

  static TimerService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TimerServiceScope>();
    assert(scope != null, 'TimerServiceScope not found in widget tree');
    return scope!.notifier!;
  }
}

