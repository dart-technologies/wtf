import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// quick_confirm — simple yes/no on a suggestion.
///
/// Props: { prompt, suggestion, image_url }
///
/// TODO(mike): add image, polish card layout.
class QuickConfirm extends StatelessWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const QuickConfirm({super.key, required this.props, required this.onSubmit});

  String get _prompt => props['prompt'] as String? ?? '';
  String get _suggestion => props['suggestion'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
            color: AppColors.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder — TODO(mike): CachedNetworkImage
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.unclaimed.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _suggestion,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onSubmit({'answer': 'no', 'suggestion': _suggestion}),
                child: const Text('Not this'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => onSubmit({'answer': 'yes', 'suggestion': _suggestion}),
                child: const Text('Yes!'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
