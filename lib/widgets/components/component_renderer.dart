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
/// Person A's sidebar highlights in blue and Person B's in coral.
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
      _ => _UnknownComponent(name: response.component),
    };
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        'Unknown component: "$name"\nCheck that Claude\'s response matches the catalog.',
        style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
      ),
    );
  }
}
