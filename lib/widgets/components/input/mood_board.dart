import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// mood_board — image grid for vibe/taste discovery.
///
/// Props: { prompt, options: [{label, image_url}], max_select }
/// Output: { selected: [options] }
class MoodBoard extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;
  final Color accentColor;

  const MoodBoard({
    super.key,
    required this.props,
    required this.onSubmit,
    this.accentColor = AppColors.personA,
  });

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
        const SizedBox(height: 4),
        Text(
          'Select up to $_maxSelect',
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
              imageUrl: option['image_url'] as String?,
              selected: selected,
              accentColor: widget.accentColor,
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
                    'selected': _selected.map((i) => _options[i]).toList(),
                  }),
          style: FilledButton.styleFrom(
            backgroundColor: widget.accentColor,
          ),
          child: Text(
            'Confirm${_selected.isNotEmpty ? ' (${_selected.length})' : ''}',
          ),
        ),
      ],
    );
  }
}

class _MoodTile extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _MoodTile({
    required this.label,
    this.imageUrl,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accentColor : AppColors.divider,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 9.5 : 11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              _buildImage(imageUrl),
              // Gradient overlay for label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Selection tint
              if (selected)
                Container(color: accentColor.withOpacity(0.15)),
              // Check badge
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 14),
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
              Icon(Icons.image, color: AppColors.textSecondary, size: 32),
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
            width: 20,
            height: 20,
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
