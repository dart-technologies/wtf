import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// vibe_slider_2d — two-axis drag-point decision.
///
/// Props: { x_left_label, x_right_label, y_top_label, y_bottom_label, quadrant_images }
///
/// TODO(mike): add quadrant background images, smooth drag feedback.
class VibeSlider2D extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const VibeSlider2D({super.key, required this.props, required this.onSubmit});

  @override
  State<VibeSlider2D> createState() => _VibeSlider2DState();
}

class _VibeSlider2DState extends State<VibeSlider2D> {
  // Normalized 0..1 from top-left
  Offset _position = const Offset(0.5, 0.5);

  static const _size = 260.0;

  String get _xLeft => widget.props['x_left_label'] as String? ?? 'Local';
  String get _xRight => widget.props['x_right_label'] as String? ?? 'Tourist';
  String get _yTop => widget.props['y_top_label'] as String? ?? 'High-energy';
  String get _yBottom => widget.props['y_bottom_label'] as String? ?? 'Chill';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Y-axis top label
        Text(_yTop, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // X-axis left label
            RotatedBox(
              quarterTurns: 3,
              child: Text(_xLeft, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onPanUpdate: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                setState(() {
                  _position = Offset(
                    (_position.dx + details.delta.dx / _size).clamp(0.0, 1.0),
                    (_position.dy + details.delta.dy / _size).clamp(0.0, 1.0),
                  );
                });
              },
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                  // TODO(mike): quadrant background images
                  gradient: LinearGradient(
                    colors: [
                      AppColors.personA.withValues(alpha: 0.1),
                      AppColors.personB.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _GridPainter(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _position.dx * _size - 12,
                        top: _position.dy * _size - 12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.personA,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.personA.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            RotatedBox(
              quarterTurns: 1,
              child: Text(_xRight, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(_yBottom, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => widget.onSubmit({
            'x': _position.dx,
            'y': _position.dy,
            'x_left_label': _xLeft,
            'x_right_label': _xRight,
            'y_top_label': _yTop,
            'y_bottom_label': _yBottom,
          }),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
