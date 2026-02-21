import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// comparison_table — feature-based option comparison.
///
/// Props: { prompt, options: [{title, image_url, features: {key: value}}] }
///
/// TODO(mike): style feature rows, add image thumbnails.
class ComparisonTable extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const ComparisonTable({super.key, required this.props, required this.onSubmit});

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

    // Collect all feature keys from first option
    final featureKeys = Map<String, dynamic>.from(
      (_options.first as Map<String, dynamic>)['features'] ?? {},
    ).keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: AppColors.divider, width: 1),
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(color: AppColors.background),
                children: [
                  const _Cell(text: ''),
                  for (int i = 0; i < _options.length; i++)
                    _Cell(
                      text: (_options[i] as Map<String, dynamic>)['title'] as String? ?? '',
                      bold: true,
                      highlight: _selected == i,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
              // Feature rows
              for (final key in featureKeys)
                TableRow(
                  children: [
                    _Cell(text: key, bold: true),
                    for (final opt in _options)
                      _Cell(
                        text: (Map<String, dynamic>.from(
                          (opt as Map<String, dynamic>)['features'] ?? {},
                        ))[key]?.toString() ?? '—',
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  final bool highlight;
  final VoidCallback? onTap;

  const _Cell({
    required this.text,
    this.bold = false,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: highlight ? AppColors.personA.withValues(alpha: 0.1) : null,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
