import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// choice_stack — swipeable venue cards for quick, fun final selection.
///
/// Props: { options: [{title, image_url, subtitle, vibe_tags, match_score, detail}] }
/// Output: { selected: option }
///
/// Swipe right to select, swipe left to skip. Cards are stacked with a
/// depth effect (next card slightly scaled down behind the current one).
class ChoiceStack extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const ChoiceStack({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

  @override
  State<ChoiceStack> createState() => _ChoiceStackState();
}

class _ChoiceStackState extends State<ChoiceStack> {
  int _currentIndex = 0;

  List<dynamic> get _options => widget.props['options'] as List? ?? [];
  String get _prompt => widget.props['prompt'] as String? ?? '';

  void _onDismissed(DismissDirection direction) {
    final option = _options[_currentIndex] as Map<String, dynamic>;
    if (direction == DismissDirection.startToEnd) {
      // Swiped right -> select
      widget.onSubmit({'selected': option});
    } else {
      // Swiped left -> skip
      setState(() {
        if (_currentIndex + 1 < _options.length) {
          _currentIndex++;
        } else {
          // Wrapped around — all skipped, reset to first
          _currentIndex = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_prompt.isNotEmpty) ...[
          Text(_prompt, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
        ],
        // Card counter
        Center(
          child: Text(
            '${_currentIndex + 1} of ${_options.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        // Swipe hint
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.arrow_back, size: 12, color: Colors.red.shade300),
                const SizedBox(width: 4),
                Text('Skip',
                    style: TextStyle(
                        fontSize: 11, color: Colors.red.shade300)),
              ],
            ),
            Row(
              children: [
                Text('Pick',
                    style: TextStyle(
                        fontSize: 11, color: Colors.green.shade300)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward,
                    size: 12, color: Colors.green.shade300),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Card stack
        SizedBox(
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Next card (behind, slightly scaled)
              if (_currentIndex + 1 < _options.length)
                Transform.scale(
                  scale: 0.94,
                  child: Transform.translate(
                    offset: const Offset(0, 6),
                    child: Opacity(
                      opacity: 0.6,
                      child: _VenueCard(
                        option:
                            _options[_currentIndex + 1] as Map<String, dynamic>,
                        accentColor: widget.accentColor,
                      ),
                    ),
                  ),
                ),
              // Current card (dismissible)
              Dismissible(
                key: ValueKey('$_currentIndex-${(_options[_currentIndex] as Map)['title']}'),
                direction: DismissDirection.horizontal,
                onDismissed: _onDismissed,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade300, size: 40),
                      const SizedBox(height: 4),
                      Text('Pick!',
                          style: TextStyle(
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, color: Colors.red.shade300, size: 40),
                      const SizedBox(height: 4),
                      Text('Skip',
                          style: TextStyle(
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                child: _VenueCard(
                  option:
                      _options[_currentIndex] as Map<String, dynamic>,
                  accentColor: widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final Color accentColor;

  const _VenueCard({
    required this.option,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(option['vibe_tags'] ?? []);
    final imageUrl = option['image_url'] as String?;
    final matchScore = option['match_score'] as num?;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image header
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: _buildImage(imageUrl, height: 160),
              ),
              if (matchScore != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _scoreColor(matchScore.toDouble()),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '${matchScore.toInt()}% match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['title'] as String? ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                  if (option['subtitle'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      option['subtitle'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
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
                  if (option['detail'] != null) ...[
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        option['detail'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.place,
              color: AppColors.textSecondary, size: 36),
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
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.broken_image,
              color: AppColors.textSecondary, size: 28),
        ),
      ),
    );
  }
}
