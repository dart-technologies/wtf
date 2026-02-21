import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// transition_block — getting between activities.
///
/// Props: { from, to, duration, method, note }
class TransitionBlockWidget extends StatelessWidget {
  final Map<String, dynamic> props;

  const TransitionBlockWidget({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final from = props['from'] as String? ?? '';
    final to = props['to'] as String? ?? '';
    final duration = props['duration'] as String? ?? '';
    final method = props['method'] as String? ?? 'Transit';
    final note = props['note'] as String?;

    final icon = switch (method.toLowerCase()) {
      'walk' || 'walking' => Icons.directions_walk,
      'subway' || 'train' || 'transit' => Icons.subway,
      'taxi' || 'uber' || 'car' => Icons.local_taxi,
      'bike' || 'citi bike' => Icons.pedal_bike,
      _ => Icons.directions_transit,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$from \u2192 $to \u00b7 $duration',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (note != null)
            Tooltip(
              message: note,
              child: const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
