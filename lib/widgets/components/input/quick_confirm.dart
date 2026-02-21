import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// quick_confirm — yes/no approval card shown during cross-approval turn.
///
/// Props: { title, subtitle, image_url }
/// onSubmit → {'answer': 'yes'} | {'answer': 'no'}
class QuickConfirm extends StatelessWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic> value) onSubmit;

  const QuickConfirm({super.key, required this.props, required this.onSubmit});

  String get _title => props['title'] as String? ?? '';
  String get _subtitle => props['subtitle'] as String? ?? '';
  String? get _imageUrl => props['image_url'] as String?;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image card
        Container(
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.unclaimed.withValues(alpha: 0.15),
          ),
          child: _imageUrl != null
              ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(_title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        if (_subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onSubmit({'answer': 'no'}),
                child: const Text('Not this'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => onSubmit({'answer': 'yes'}),
                child: const Text('Yes! 👍'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
