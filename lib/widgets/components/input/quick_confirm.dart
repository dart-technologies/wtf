import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// quick_confirm — simple yes/no on a suggestion or cross-approval.
///
/// Props (flow):   { prompt, suggestion, image_url }
/// Props (demo):   { title, subtitle, image_url }
/// Output: { answer: 'yes'|'no', suggestion }
class QuickConfirm extends StatelessWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const QuickConfirm({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

  // Accept both prop name conventions
  String get _title =>
      props['title'] as String? ?? props['prompt'] as String? ?? '';
  String get _subtitle =>
      props['subtitle'] as String? ?? props['suggestion'] as String? ?? '';
  String? get _imageUrl => props['image_url'] as String?;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_title.isNotEmpty) ...[
          Text(_title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
        ],
        // Suggestion card
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildImage(_imageUrl, height: 140),
              ),
              if (_subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Yes / No buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    onSubmit({'answer': 'no', 'suggestion': _subtitle}),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Not this'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    onSubmit({'answer': 'yes', 'suggestion': _subtitle}),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Yes!'),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildImage(String? imageUrl, {double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.place,
              color: AppColors.textSecondary, size: 32),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.broken_image,
              color: AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }
}
