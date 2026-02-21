import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// comparison_cards — 2–4 specific options with expandable detail.
///
/// Props: { prompt, options: [{title, image_url, subtitle, vibe_tags, detail}], expandable }
///
/// TODO(mike): add CachedNetworkImage, expand animation.
class ComparisonCards extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const ComparisonCards({super.key, required this.props, required this.onSubmit});

  @override
  State<ComparisonCards> createState() => _ComparisonCardsState();
}

class _ComparisonCardsState extends State<ComparisonCards> {
  int? _selected;
  int? _expanded;

  List<dynamic> get _options => widget.props['options'] as List? ?? [];
  bool get _expandable => widget.props['expandable'] as bool? ?? false;
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
            onTap: () => setState(() => _selected = i),
            onExpand: _expandable
                ? () => setState(() => _expanded = _expanded == i ? null : i)
                : null,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => widget.onSubmit({'selected': _options[_selected!]}),
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
  final VoidCallback onTap;
  final VoidCallback? onExpand;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.expanded,
    required this.expandable,
    required this.onTap,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(option['vibe_tags'] ?? []);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.personA : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          color: AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                color: AppColors.unclaimed.withOpacity(0.3),
              ),
              // TODO(mike): CachedNetworkImage(url: option['image_url'])
            ),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: AppColors.personA, size: 18),
                      if (expandable && !selected)
                        GestureDetector(
                          onTap: onExpand,
                          child: Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    option['subtitle'] as String? ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Text(t, style: Theme.of(context).textTheme.bodySmall),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (expanded && option['detail'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      option['detail'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
