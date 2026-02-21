import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// mood_board — image grid for vibe decisions.
///
/// Props: { prompt, options: [{label, image_url}], max_select }
///
/// TODO(mike): implement image loading, selection state, submit.
class MoodBoard extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const MoodBoard({super.key, required this.props, required this.onSubmit});

  @override
  State<MoodBoard> createState() => _MoodBoardState();
}

class _MoodBoardState extends State<MoodBoard> {
  final Set<int> _selected = {};

  List<dynamic> get _options => widget.props['options'] as List? ?? [];
  int get _maxSelect => widget.props['max_select'] as int? ?? 1;
  String get _prompt => widget.props['prompt'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _options.length,
          itemBuilder: (context, i) {
            final option = _options[i] as Map<String, dynamic>;
            final selected = _selected.contains(i);
            return _MoodTile(
              label: option['label'] as String? ?? '',
              imageUrl: option['image_url'] as String? ?? '',
              selected: selected,
              onTap: () => setState(() {
                if (selected) {
                  _selected.remove(i);
                } else if (_selected.length < _maxSelect) {
                  _selected.add(i);
                }
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => widget.onSubmit({
                    'selected': _selected
                        .map((i) => _options[i])
                        .toList(),
                  }),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _MoodTile extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _MoodTile({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.personA : AppColors.divider,
            width: selected ? 2.5 : 1,
          ),
          color: AppColors.background,
        ),
        child: Stack(
          children: [
            // TODO(mike): replace with CachedNetworkImage
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: AppColors.unclaimed.withOpacity(0.3),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.personA,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
