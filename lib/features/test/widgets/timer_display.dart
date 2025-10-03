// timer_display.dart
import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final Duration duration;

  const TimerDisplay({Key? key, required this.duration}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Text(
      'Time: $minutes:${seconds.toString().padLeft(2, '0')}',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
