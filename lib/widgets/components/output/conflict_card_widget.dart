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
        border: Border.all(color: Colors.orange.shade300),
        color: Colors.orange.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                'Conflict',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange.shade800,
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
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade400),
                ),
                child: Text(option['label'] as String? ?? ''),
              ),
            ),
        ],
      ),
    );
  }
}
