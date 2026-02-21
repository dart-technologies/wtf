import 'package:flutter/material.dart';

/// conflict_card — shared decision on the center itinerary.
///
/// Props: { description, options: [{label, detail}] }
///
/// TODO(mike): add real-time vote count if both people need to interact.
class ConflictCardWidget extends StatelessWidget {
  final Map<String, dynamic> conflict;
  final void Function(Map<String, dynamic> option) onResolve;

  const ConflictCardWidget({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final description = conflict['description'] as String? ?? '';
    final options = List<Map<String, dynamic>>.from(conflict['options'] ?? []);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF3D2E1A),
        border: Border.all(color: const Color(0xFF6B4F2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFFB74D), size: 16),
              const SizedBox(width: 6),
              Text(
                'Conflict',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFFB74D),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton(
                onPressed: () => onResolve(option),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFB74D),
                  side: const BorderSide(color: Color(0xFF6B4F2A)),
                ),
                child: Text(option['label'] as String? ?? ''),
              ),
            ),
        ],
      ),
    );
  }
}
