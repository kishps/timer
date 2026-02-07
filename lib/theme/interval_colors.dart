import 'package:flutter/material.dart';

@immutable
class IntervalColors extends ThemeExtension<IntervalColors> {
  final Color work;
  final Color rest;
  final Color restBetweenSets;
  final Color manual;

  const IntervalColors({
    required this.work,
    required this.rest,
    required this.restBetweenSets,
    required this.manual,
  });

  static IntervalColors of(BuildContext context) {
    final ext = Theme.of(context).extension<IntervalColors>();
    assert(ext != null, 'IntervalColors theme extension is not configured');
    return ext!;
  }

  @override
  IntervalColors copyWith({
    Color? work,
    Color? rest,
    Color? restBetweenSets,
    Color? manual,
  }) {
    return IntervalColors(
      work: work ?? this.work,
      rest: rest ?? this.rest,
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
      manual: manual ?? this.manual,
    );
  }

  @override
  IntervalColors lerp(ThemeExtension<IntervalColors>? other, double t) {
    if (other is! IntervalColors) return this;
    return IntervalColors(
      work: Color.lerp(work, other.work, t) ?? work,
      rest: Color.lerp(rest, other.rest, t) ?? rest,
      restBetweenSets: Color.lerp(restBetweenSets, other.restBetweenSets, t) ?? restBetweenSets,
      manual: Color.lerp(manual, other.manual, t) ?? manual,
    );
  }
}

