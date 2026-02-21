import 'package:flutter/material.dart';
import '../../models/component_response.dart';
import '../../theme/app_theme.dart';
import 'input/mood_board.dart';
import 'input/this_or_that.dart';
import 'input/vibe_slider.dart';
import 'input/vibe_slider_2d.dart';
import 'input/comparison_cards.dart';
import 'input/choice_stack.dart';
import 'input/comparison_table.dart';
import 'input/quick_confirm.dart';
import 'input/domain_claim.dart';

/// Dispatches a [ComponentResponse] from Claude to the correct widget.
///
/// Derives the accent color from [response.targetUser] so that
/// Person A's sidebar highlights in magenta pink and Person B's in deep blue.
class ComponentRenderer extends StatelessWidget {
  final ComponentResponse response;
  final void Function(Map<String, dynamic> value) onSubmit;

  const ComponentRenderer({
    super.key,
    required this.response,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final props = response.props;
    final accent = AppColors.forPersonId(response.targetUser);

    return switch (response.component) {
      'mood_board' => MoodBoard(props: props, onSubmit: onSubmit, accentColor: accent),
      'this_or_that' => ThisOrThat(props: props, onSubmit: onSubmit, accentColor: accent),
      'vibe_slider' => VibeSlider(props: props, onSubmit: onSubmit, accentColor: accent),
      'vibe_slider_2d' => VibeSlider2D(props: props, onSubmit: onSubmit, accentColor: accent),
      'comparison_cards' => ComparisonCards(props: props, onSubmit: onSubmit, accentColor: accent),
      'choice_stack' => ChoiceStack(props: props, onSubmit: onSubmit, accentColor: accent),
      'comparison_table' => ComparisonTable(props: props, onSubmit: onSubmit, accentColor: accent),
      'quick_confirm' => QuickConfirm(props: props, onSubmit: onSubmit, accentColor: accent),
      'domain_claim' => DomainClaim(props: props, onSubmit: onSubmit),
      'claude_thinking' => _ClaudeThinkingWidget(props: props),
      _ => _UnknownComponent(name: response.component),
    };
  }
}

/// Placeholder shown while Claude is selecting and populating a component.
class _ClaudeThinkingWidget extends StatefulWidget {
  final Map<String, dynamic> props;
  const _ClaudeThinkingWidget({required this.props});

  @override
  State<_ClaudeThinkingWidget> createState() => _ClaudeThinkingWidgetState();
}

class _ClaudeThinkingWidgetState extends State<_ClaudeThinkingWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _dotCtrl;
  late final List<Animation<double>> _dotAnim;

  static const _dotCount = 3;

  @override
  void initState() {
    super.initState();
    _dotCtrl = List.generate(
      _dotCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _dotAnim = _dotCtrl
        .map((c) => Tween<double>(begin: 0.2, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _dotCtrl[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _dotCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.props['label'] as String? ?? 'Claude is thinking…';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        color: AppColors.background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_dotCount, (i) {
              return AnimatedBuilder(
                animation: _dotAnim[i],
                builder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Opacity(
                    opacity: _dotAnim[i].value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

class _UnknownComponent extends StatelessWidget {
  final String name;
  const _UnknownComponent({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2E1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6B4F2A)),
      ),
      child: Text(
        'Unknown component: "$name"\nCheck that Claude\'s response matches the catalog.',
        style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 13),
      ),
    );
  }
}
