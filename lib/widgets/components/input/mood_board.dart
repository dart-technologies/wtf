import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/image_service.dart';
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
  final Map<int, String> _resolvedUrls = {};
  static final _imageService = ImageService();

  List<dynamic> get _options => widget.props['options'] as List? ?? [];
  int get _maxSelect => widget.props['max_select'] as int? ?? 1;
  String get _prompt => widget.props['prompt'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _resolveImages();
  }

  Future<void> _resolveImages() async {
    for (int i = 0; i < _options.length; i++) {
      final option = _options[i] as Map<String, dynamic>;
      final descriptor = option['image_url'] as String? ?? '';
      if (descriptor.isEmpty) continue;
      final url = await _imageService.resolve(descriptor);
      if (mounted) setState(() => _resolvedUrls[i] = url);
    }
  }

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
              imageUrl: _resolvedUrls[i] ?? option['image_url'] as String?,
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
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
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
                        Colors.black.withOpacity(0.6),
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
              if (selected)
                Container(color: accentColor.withOpacity(0.15)),
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
        color: AppColors.surfaceElevated,
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
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.broken_image,
              color: AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }
}
