import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// vibe_slider — single-axis spectrum decision between two poles.
///
/// Props: { left_label, right_label, left_image, right_image }
/// Output: { value, left_label, right_label }
class VibeSlider extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const VibeSlider({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

  @override
  State<VibeSlider> createState() => _VibeSliderState();
}

class _VibeSliderState extends State<VibeSlider> {
  double _value = 0.5;

  String get _leftLabel =>
      widget.props['left_label'] as String? ?? 'Casual';
  String get _rightLabel =>
      widget.props['right_label'] as String? ?? 'Fancy';
  String? get _leftImage => widget.props['left_image'] as String?;
  String? get _rightImage => widget.props['right_image'] as String?;

  String get _positionLabel {
    if (_value < 0.35) return 'More $_leftLabel';
    if (_value > 0.65) return 'More $_rightLabel';
    return 'A mix of both';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pole images + labels
        Row(
          children: [
            Expanded(
              child: _PoleWidget(
                label: _leftLabel,
                imageUrl: _leftImage,
                active: _value < 0.4,
                accentColor: widget.accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PoleWidget(
                label: _rightLabel,
                imageUrl: _rightImage,
                active: _value > 0.6,
                accentColor: widget.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Slider with gradient track
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.accentColor,
            inactiveTrackColor: widget.accentColor.withOpacity(0.2),
            thumbColor: widget.accentColor,
            overlayColor: widget.accentColor.withOpacity(0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
        ),
        const SizedBox(height: 8),
        // Position description
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              _positionLabel,
              key: ValueKey(_positionLabel),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: widget.accentColor,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => widget.onSubmit({
            'value': _value,
            'left_label': _leftLabel,
            'right_label': _rightLabel,
          }),
          style: FilledButton.styleFrom(
            backgroundColor: widget.accentColor,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _PoleWidget extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool active;
  final Color accentColor;

  const _PoleWidget({
    required this.label,
    this.imageUrl,
    required this.active,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceElevated,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
            border: Border.all(
              color: active ? accentColor : AppColors.divider,
              width: active ? 2.5 : 1,
            ),
          ),
          child: ClipOval(child: _buildImage(imageUrl)),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? accentColor : AppColors.textSecondary,
          ),
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  static Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: AppColors.surfaceElevated,
        child: const Center(
          child:
              Icon(Icons.auto_awesome, color: AppColors.textSecondary, size: 20),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.surfaceElevated,
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.broken_image,
              color: AppColors.textSecondary, size: 16),
        ),
      ),
    );
  }
}
