import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// comparison_table — feature-based option comparison in table format.
///
/// Props: { prompt, options: [{title, image_url, features: {key: value}}] }
/// Output: { selected: option }
class ComparisonTable extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const ComparisonTable({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

  @override
  State<ComparisonTable> createState() => _ComparisonTableState();
}

class _ComparisonTableState extends State<ComparisonTable> {
  int? _selected;

  List<dynamic> get _options => widget.props['options'] as List? ?? [];
  String get _prompt => widget.props['prompt'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    if (_options.isEmpty) return const SizedBox.shrink();

    // Collect all feature keys across all options
    final featureKeys = <String>{};
    for (final opt in _options) {
      final features =
          Map<String, dynamic>.from((opt as Map<String, dynamic>)['features'] ?? {});
      featureKeys.addAll(features.keys);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        // Scrollable table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with images + titles
              Row(
                children: [
                  // Empty corner cell
                  const SizedBox(width: 80),
                  for (int i = 0; i < _options.length; i++)
                    _HeaderCell(
                      option: _options[i] as Map<String, dynamic>,
                      selected: _selected == i,
                      accentColor: widget.accentColor,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              // Feature rows
              for (int r = 0; r < featureKeys.length; r++)
                _FeatureRow(
                  featureKey: featureKeys.elementAt(r),
                  options: _options,
                  selectedIndex: _selected,
                  accentColor: widget.accentColor,
                  isEven: r.isEven,
                ),
            ],
          ),
        ),
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

class _HeaderCell extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _HeaderCell({
    required this.option,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = option['image_url'] as String?;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? accentColor.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accentColor : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 60,
                height: 40,
                child: _buildImage(imageUrl),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option['title'] as String? ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? accentColor : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle, color: accentColor, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: AppColors.unclaimed.withOpacity(0.3),
        child: const Center(
          child: Icon(Icons.image, color: AppColors.textSecondary, size: 16),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          Container(color: AppColors.unclaimed.withOpacity(0.15)),
      errorWidget: (context, url, error) => Container(
        color: AppColors.unclaimed.withOpacity(0.3),
        child: const Center(
          child: Icon(Icons.broken_image,
              color: AppColors.textSecondary, size: 14),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String featureKey;
  final List<dynamic> options;
  final int? selectedIndex;
  final Color accentColor;
  final bool isEven;

  const _FeatureRow({
    required this.featureKey,
    required this.options,
    this.selectedIndex,
    required this.accentColor,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Feature key label
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: isEven ? AppColors.background : AppColors.surface,
          child: Text(
            featureKey,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Feature values for each option
        for (int i = 0; i < options.length; i++)
          Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: selectedIndex == i
                ? accentColor.withOpacity(0.05)
                : isEven
                    ? AppColors.background
                    : AppColors.surface,
            child: Text(
              (Map<String, dynamic>.from(
                    (options[i] as Map<String, dynamic>)['features'] ?? {},
                  ))[featureKey]
                      ?.toString() ??
                  '\u2014',
              style: TextStyle(
                fontSize: 11,
                color: selectedIndex == i
                    ? accentColor
                    : AppColors.textSecondary,
                fontWeight:
                    selectedIndex == i ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
