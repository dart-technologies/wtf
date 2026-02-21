import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// this_or_that — rapid binary preference discovery.
///
/// Props: { pairs: [{left: {label, image_url}, right: {label, image_url}}] }
///
/// TODO(mike): implement pair stepping, image loading, swipe gesture.
class ThisOrThat extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const ThisOrThat({super.key, required this.props, required this.onSubmit});

  @override
  State<ThisOrThat> createState() => _ThisOrThatState();
}

class _ThisOrThatState extends State<ThisOrThat> {
  int _currentPair = 0;
  final List<String> _answers = [];

  List<dynamic> get _pairs => widget.props['pairs'] as List? ?? [];

  bool get _done => _currentPair >= _pairs.length;

  void _pick(String side) {
    setState(() {
      _answers.add(side);
      _currentPair++;
    });
    if (_currentPair >= _pairs.length) {
      widget.onSubmit({'answers': _answers});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty) return const SizedBox.shrink();
    if (_done) {
      return Center(
        child: Text('Done!', style: Theme.of(context).textTheme.titleMedium),
      );
    }

    final pair = _pairs[_currentPair] as Map<String, dynamic>;
    final left = pair['left'] as Map<String, dynamic>;
    final right = pair['right'] as Map<String, dynamic>;

    return Column(
      children: [
        Text(
          '${_currentPair + 1} of ${_pairs.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _OptionCard(option: left, onTap: () => _pick('left'))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('or', style: TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(child: _OptionCard(option: right, onTap: () => _pick('right'))),
          ],
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final VoidCallback onTap;

  const _OptionCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.background,
          border: Border.all(color: AppColors.divider),
        ),
        child: Stack(
          children: [
            // TODO(mike): CachedNetworkImage
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: AppColors.unclaimed.withValues(alpha: 0.3),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Text(
                  option['label'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
