import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// final_plan_card — styled output block in the finalized itinerary view.
///
/// Props: { title, time, description, image_url, highlights: [str], vibe_color }
class FinalPlanCard extends StatelessWidget {
  final Map<String, dynamic> props;

  const FinalPlanCard({super.key, required this.props});

  String get _title => props['title'] as String? ?? '';
  String get _time => props['time'] as String? ?? '';
  String get _description => props['description'] as String? ?? '';
  String? get _imageUrl => props['image_url'] as String?;
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
        border: Border.all(color: _vibeColor.withValues(alpha: 0.3)),
        color: AppColors.elevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vibe header with optional image
          SizedBox(
            height: 130,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background: image or color tint
                Container(color: _vibeColor.withValues(alpha: 0.12)),
                if (_imageUrl != null)
                  Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                // Gradient overlay so text stays readable over image
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                    ),
                  ),
                ),
                // Time badge + title
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _vibeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_time,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              shadows: [
                                const Shadow(blurRadius: 4, color: Colors.black38)
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
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
                          Icon(Icons.star_rounded, size: 12, color: _vibeColor),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(h,
                                  style: Theme.of(context).textTheme.bodySmall)),
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
