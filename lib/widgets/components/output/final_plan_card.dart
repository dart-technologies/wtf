import 'package:flutter/material.dart';

/// final_plan_card — styled output block in the final itinerary view.
///
/// Props: { title, time, description, image_url, highlights: [str], vibe_color }
///
/// TODO(mike): load image, parse vibe_color hex string, polish typography.
class FinalPlanCard extends StatelessWidget {
  final Map<String, dynamic> props;

  const FinalPlanCard({super.key, required this.props});

  String get _title => props['title'] as String? ?? '';
  String get _time => props['time'] as String? ?? '';
  String get _description => props['description'] as String? ?? '';
  List<String> get _highlights => List<String>.from(props['highlights'] ?? []);
  Color get _vibeColor {
    final hex = props['vibe_color'] as String? ?? '#4A9EFF';
    final value = int.tryParse(hex.replaceAll('#', ''), radix: 16);
    return value != null ? Color(0xFF000000 | value) : const Color(0xFF4A9EFF);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _vibeColor.withOpacity(0.3)),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vibe color header + image
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              color: _vibeColor.withOpacity(0.15),
              // TODO(mike): CachedNetworkImage as background
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _vibeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: _vibeColor.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_description, style: Theme.of(context).textTheme.bodyMedium),
                if (_highlights.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final h in _highlights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 12, color: _vibeColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(h, style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
