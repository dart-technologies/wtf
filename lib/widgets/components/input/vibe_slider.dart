import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// vibe_slider — spectrum decision between two poles.
///
/// Props: { left_label, right_label, left_image, right_image }
///
/// TODO(mike): add endpoint images, animate gradient as slider moves.
class VibeSlider extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const VibeSlider({super.key, required this.props, required this.onSubmit});

  @override
  State<VibeSlider> createState() => _VibeSliderState();
}

class _VibeSliderState extends State<VibeSlider> {
  double _value = 0.5;

  String get _leftLabel => widget.props['left_label'] as String? ?? 'Casual';
  String get _rightLabel => widget.props['right_label'] as String? ?? 'Fancy';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TODO(mike): show left_image and right_image at the poles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_leftLabel, style: Theme.of(context).textTheme.bodyMedium),
            Text(_rightLabel, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.personA,
            thumbColor: AppColors.personA,
            overlayColor: AppColors.personA.withOpacity(0.2),
          ),
          child: Slider(
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => widget.onSubmit({
            'value': _value,
            'left_label': _leftLabel,
            'right_label': _rightLabel,
          }),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
