import 'package:flutter/material.dart';
enum Timeframe { d7, d30, d90 }
class TimeframeSelector extends StatelessWidget {
  final Timeframe value;
  final ValueChanged<Timeframe> onChanged;
  const TimeframeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Timeframe>(
      segments: const [
        ButtonSegment(value: Timeframe.d7, label: Text('7 j')),
        ButtonSegment(value: Timeframe.d30, label: Text('30 j')),
        ButtonSegment(value: Timeframe.d90, label: Text('90 j')),
      ],
      selected: {value},
      onSelectionChanged: (set) => onChanged(set.first),
      showSelectedIcon: false,
    );
  }
}
extension TimeframeExtension on Timeframe {
  String toDisplayString() {
    switch (this) {
      case Timeframe.d7:
        return '7 derniers jours';
      case Timeframe.d30:
        return '30 derniers jours';
      case Timeframe.d90:
        return '90 derniers jours';
    }
  }
}