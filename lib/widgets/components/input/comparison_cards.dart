import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// comparison_cards — 2–4 specific options with expandable detail.
///
/// Props: { prompt, options: [{title, image_url, subtitle, vibe_tags, match_score, detail}], expandable }
/// Output: { selected: option }
class ComparisonCards extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const ComparisonCards({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

  @override
  State<ComparisonCards> createState() => _ComparisonCardsState();
}

class _ComparisonCardsState extends State<ComparisonCards> {
  int? _selected;
  int? _expanded;

  List<dynamic> get _options => widget.props['options'] as List? ?? [];
  bool get _expandable => widget.props['expandable'] as bool? ?? true;
  String get _prompt => widget.props['prompt'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (int i = 0; i < _options.length; i++) ...[
          _OptionCard(
            option: _options[i] as Map<String, dynamic>,
            selected: _selected == i,
            expanded: _expanded == i,
            expandable: _expandable,
            accentColor: widget.accentColor,
            onTap: () => setState(() => _selected = i),
            onExpand: _expandable
                ? () => setState(() => _expanded = _expanded == i ? null : i)
                : null,
          ),
          if (i < _options.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => widget.onSubmit({'selected': _options[_selected!]}),
          style: FilledButton.styleFrom(
            backgroundColor: widget.accentColor,
          ),
          child: const Text('Choose this'),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool selected;
  final bool expanded;
  final bool expandable;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onExpand;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.expanded,
    required this.expandable,
    required this.accentColor,
    required this.onTap,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(option['vibe_tags'] ?? []);
    final imageUrl = option['image_url'] as String?;
    final matchScore = option['match_score'] as num?;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accentColor : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          color: AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image header with match score badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                  child: _buildImage(imageUrl, height: 100),
                ),
                // Match score badge
                if (matchScore != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _scoreColor(matchScore.toDouble()),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${matchScore.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Selection checkmark
                if (selected)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option['title'] as String? ?? '',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (expandable)
                        GestureDetector(
                          onTap: onExpand,
                          child: Icon(
                            expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  if (option['subtitle'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option['subtitle'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  // Expandable detail
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: option['detail'] != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              option['detail'] as String,
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : const SizedBox.shrink(),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(double score) {
    if (score >= 85) return const Color(0xFF4CAF50);
    if (score >= 70) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  static Widget _buildImage(String? imageUrl, {double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: height,
        color: AppColors.unclaimed.withOpacity(0.3),
        child: const Center(
          child: Icon(Icons.restaurant,
              color: AppColors.textSecondary, size: 28),
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
        color: AppColors.unclaimed.withOpacity(0.15),
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
        color: AppColors.unclaimed.withOpacity(0.3),
        child: const Center(
          child: Icon(Icons.broken_image,
              color: AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }
}
