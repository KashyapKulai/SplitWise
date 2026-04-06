import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animated number counter with smooth transitions
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final formatted = NumberFormat.currency(
          symbol: prefix,
          decimalDigits: decimals,
        ).format(animatedValue);
        return Text(
          '$formatted$suffix',
          style: style ?? Theme.of(context).textTheme.displayMedium,
        );
      },
    );
  }
}
