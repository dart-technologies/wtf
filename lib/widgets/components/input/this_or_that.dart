import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// this_or_that — rapid binary preference discovery.
///
/// Props: { pairs: [{left: {label, image_url}, right: {label, image_url}}] }
/// Output: { answers: ['left'|'right', ...] }
///
/// Steps through pairs one at a time. Tapping a side highlights it briefly,
/// then advances. Auto-submits when all pairs are answered.
class ThisOrThat extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const ThisOrThat({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

  @override
  State<ThisOrThat> createState() => _ThisOrThatState();
}

class _ThisOrThatState extends State<ThisOrThat> {
  int _currentPair = 0;
  final List<String> _answers = [];
  String? _lastPick; // 'left' or 'right', briefly shown before advancing
  bool _advancing = false;

  List<dynamic> get _pairs => widget.props['pairs'] as List? ?? [];
  bool get _done => _currentPair >= _pairs.length;

  Future<void> _pick(String side) async {
    if (_advancing) return;
    _advancing = true;
    setState(() => _lastPick = side);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _answers.add(side);
    if (_currentPair + 1 >= _pairs.length) {
      widget.onSubmit({'answers': _answers});
      setState(() {
        _currentPair++;
        _lastPick = null;
        _advancing = false;
      });
    } else {
      setState(() {
        _currentPair++;
        _lastPick = null;
        _advancing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pairs.isEmpty) return const SizedBox.shrink();
    if (_done) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: widget.accentColor, size: 48),
            const SizedBox(height: 8),
            Text('All set!', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    final pair = _pairs[_currentPair] as Map<String, dynamic>;
    final left = pair['left'] as Map<String, dynamic>;
    final right = pair['right'] as Map<String, dynamic>;

    return Column(
      children: [
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pairs.length, (i) {
            final isActive = i == _currentPair;
            final isDone = i < _currentPair;
            return Container(
              width: isActive ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDone
                    ? widget.accentColor
                    : isActive
                        ? widget.accentColor.withOpacity(0.5)
                        : AppColors.divider,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          '${_currentPair + 1} of ${_pairs.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        // Pair cards with animated transition
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Row(
            key: ValueKey(_currentPair),
            children: [
              Expanded(
                child: _OptionCard(
                  option: left,
                  highlighted: _lastPick == 'left',
                  accentColor: widget.accentColor,
                  onTap: () => _pick('left'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'or',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _OptionCard(
                  option: right,
                  highlighted: _lastPick == 'right',
                  accentColor: widget.accentColor,
                  onTap: () => _pick('right'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool highlighted;
  final Color accentColor;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.highlighted,
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
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted ? accentColor : AppColors.divider,
            width: highlighted ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(highlighted ? 9.5 : 11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              _buildImage(imageUrl),
              // Label overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
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
              // Selection highlight
              if (highlighted)
                Container(color: accentColor.withOpacity(0.2)),
              if (highlighted)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: AppColors.unclaimed.withOpacity(0.3),
        child: const Center(
          child:
              Icon(Icons.image, color: AppColors.textSecondary, size: 28),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.unclaimed.withOpacity(0.15),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.unclaimed.withOpacity(0.3),
        child: const Center(
          child: Icon(Icons.broken_image,
              color: AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }
}
