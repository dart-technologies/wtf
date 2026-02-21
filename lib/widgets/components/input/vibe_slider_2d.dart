import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// vibe_slider_2d — two-axis drag-point decision.
///
/// Props: { x_left_label, x_right_label, y_top_label, y_bottom_label, quadrant_images }
/// Output: { x, y, x_left_label, x_right_label, y_top_label, y_bottom_label }
class VibeSlider2D extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const VibeSlider2D({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

  @override
  State<VibeSlider2D> createState() => _VibeSlider2DState();
}

class _VibeSlider2DState extends State<VibeSlider2D> {
  // Normalized 0..1 from top-left
  Offset _position = const Offset(0.5, 0.5);

  // Grid size is computed dynamically in build() via LayoutBuilder.

  String get _xLeft =>
      widget.props['x_left_label'] as String? ?? 'Local';
  String get _xRight =>
      widget.props['x_right_label'] as String? ?? 'Tourist';
  String get _yTop =>
      widget.props['y_top_label'] as String? ?? 'High-energy';
  String get _yBottom =>
      widget.props['y_bottom_label'] as String? ?? 'Chill';

  /// Descriptive label based on current position quadrant.
  String get _positionLabel {
    final xLabel = _position.dx < 0.4
        ? _xLeft
        : _position.dx > 0.6
            ? _xRight
            : null;
    final yLabel = _position.dy < 0.4
        ? _yTop
        : _position.dy > 0.6
            ? _yBottom
            : null;
    if (xLabel != null && yLabel != null) return '$xLabel + $yLabel';
    if (xLabel != null) return xLabel;
    if (yLabel != null) return yLabel;
    return 'Right in the middle';
  }

  @override
  Widget build(BuildContext context) {
    // Reserve space for rotated axis labels (~20px each side) + gaps (8px each).
    const _labelSpace = 20.0 + 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit the grid to the available width minus label gutters on both sides.
        final gridSize = (constraints.maxWidth - _labelSpace * 2)
            .clamp(120.0, 300.0);

        return Column(
          children: [
            // Y-axis top label
            _AxisLabel(text: _yTop, active: _position.dy < 0.4, accentColor: widget.accentColor),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // X-axis left label
                RotatedBox(
                  quarterTurns: 3,
                  child: _AxisLabel(
                    text: _xLeft,
                    active: _position.dx < 0.4,
                    accentColor: widget.accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Drag area
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _position = Offset(
                        (_position.dx + details.delta.dx / gridSize)
                            .clamp(0.0, 1.0),
                        (_position.dy + details.delta.dy / gridSize)
                            .clamp(0.0, 1.0),
                      );
                    });
                  },
                  child: Container(
                    width: gridSize,
                    height: gridSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          // Quadrant background colors
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: widget.accentColor.withOpacity(0.06),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        color: widget.accentColor.withOpacity(0.03),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: widget.accentColor.withOpacity(0.09),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        color: widget.accentColor.withOpacity(0.04),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Grid crosshairs
                          CustomPaint(
                            size: Size(gridSize, gridSize),
                            painter: _GridPainter(),
                          ),
                          // Drag indicator
                          Positioned(
                            left: _position.dx * gridSize - 14,
                            top: _position.dy * gridSize - 14,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: widget.accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.accentColor.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
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
                // X-axis right label
                RotatedBox(
                  quarterTurns: 1,
                  child: _AxisLabel(
                    text: _xRight,
                    active: _position.dx > 0.6,
                    accentColor: widget.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Y-axis bottom label
            _AxisLabel(text: _yBottom, active: _position.dy > 0.6, accentColor: widget.accentColor),
            const SizedBox(height: 10),
            // Position description
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Container(
                key: ValueKey(_positionLabel),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _positionLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
              ),
            ),
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
              style: FilledButton.styleFrom(
                backgroundColor: widget.accentColor,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;
  final bool active;
  final Color accentColor;

  const _AxisLabel({
    required this.text,
    required this.active,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: 11,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        color: active ? accentColor : AppColors.textSecondary,
      ),
      child: Text(text),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withOpacity(0.6)
      ..strokeWidth = 1;
    // Vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    // Horizontal center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
