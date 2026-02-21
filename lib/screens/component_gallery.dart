import 'package:flutter/material.dart';
import '../models/component_response.dart';
import '../theme/app_theme.dart';
import '../widgets/components/component_renderer.dart';

/// A visual gallery of all decision components with sample NYC data.
///
/// Run the app and navigate here to preview every component with hot reload.
/// Toggle between Person A (magenta) and Person B (blue) to verify accent colors.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  String _targetUser = 'person_a';
  final List<String> _log = [];

  void _onSubmit(String componentName, Map<String, dynamic> result) {
    setState(() {
      _log.insert(0, '[$componentName] ${_formatResult(result)}');
    });
  }

  String _formatResult(Map<String, dynamic> result) {
    if (result.containsKey('selected')) {
      final sel = result['selected'];
      if (sel is Map) return 'Selected: ${sel['title'] ?? sel['label'] ?? sel}';
      if (sel is List) return 'Selected: ${sel.map((s) => s['label'] ?? s).join(', ')}';
      return 'Selected: $sel';
    }
    if (result.containsKey('answer')) return 'Answer: ${result['answer']}';
    if (result.containsKey('answers')) return 'Answers: ${result['answers']}';
    if (result.containsKey('value')) return 'Value: ${(result['value'] as double).toStringAsFixed(2)}';
    if (result.containsKey('x')) {
      return 'Position: (${(result['x'] as double).toStringAsFixed(2)}, ${(result['y'] as double).toStringAsFixed(2)})';
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Gallery'),
        actions: [
          // Person toggle
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'person_a', label: Text('Abby')),
              ButtonSegment(value: 'person_b', label: Text('Mike')),
            ],
            selected: {_targetUser},
            onSelectionChanged: (v) => setState(() => _targetUser = v.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.forPersonId(_targetUser).withOpacity(0.15);
                }
                return null;
              }),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Components list (sidebar width to match real layout)
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in _sampleComponents)
                  _ComponentSection(
                    title: entry.displayName,
                    child: ComponentRenderer(
                      response: ComponentResponse(
                        targetUser: _targetUser,
                        targetBlock: 'lunch',
                        component: entry.name,
                        props: entry.props,
                      ),
                      onSubmit: (result) => _onSubmit(entry.name, result),
                    ),
                  ),
              ],
            ),
          ),
          // Event log
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Event Log',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _log.clear()),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _log.isEmpty
                      ? const Center(
                          child: Text(
                            'Interact with components to see events here',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _log.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              _log[i],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ComponentSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sample data — NYC venues and vibes for previewing each component
// ---------------------------------------------------------------------------

class _SampleComponent {
  final String name;       // component key sent to ComponentRenderer
  final String displayName; // friendly label for gallery section header
  final Map<String, dynamic> props;
  const _SampleComponent(this.name, this.displayName, this.props);
}

const _sampleComponents = <_SampleComponent>[
  _SampleComponent('mood_board', 'Mood Board', {
    'prompt': 'What does lunch feel like?',
    'max_select': 2,
    'options': [
      {'label': 'Cozy ramen spot', 'image_url': ''},
      {'label': 'Trendy brunch', 'image_url': ''},
      {'label': 'Old-school deli', 'image_url': ''},
      {'label': 'Street food market', 'image_url': ''},
    ],
  }),
  _SampleComponent('this_or_that', 'This or That', {
    'pairs': [
      {
        'left': {'label': 'Outdoors', 'image_url': ''},
        'right': {'label': 'Indoors', 'image_url': ''},
      },
      {
        'left': {'label': 'Chill', 'image_url': ''},
        'right': {'label': 'Active', 'image_url': ''},
      },
      {
        'left': {'label': 'Iconic NYC', 'image_url': ''},
        'right': {'label': 'Hidden gem', 'image_url': ''},
      },
    ],
  }),
  _SampleComponent('vibe_slider', 'Vibe Slider', {
    'left_label': 'Casual',
    'right_label': 'Fancy',
    'left_image': '',
    'right_image': '',
  }),
  _SampleComponent('vibe_slider_2d', 'Vibe Slider 2D', {
    'x_left_label': 'Local',
    'x_right_label': 'Tourist',
    'y_top_label': 'High-energy',
    'y_bottom_label': 'Chill',
  }),
  _SampleComponent('comparison_cards', 'Comparison Cards', {
    'prompt': 'Three spots that match the vibe.',
    'expandable': true,
    'options': [
      {
        'title': 'Lilia',
        'subtitle': 'Williamsburg · Italian',
        'image_url': '',
        'vibe_tags': ['pasta', 'date night', 'warm'],
        'match_score': 94,
        'detail':
            'Michelin-starred Italian with house-made pasta. Reservations recommended. \$\$\$',
      },
      {
        'title': "Roberta's",
        'subtitle': 'Bushwick · Pizza',
        'image_url': '',
        'vibe_tags': ['pizza', 'casual', 'brooklyn'],
        'match_score': 81,
        'detail':
            'Wood-fired pizza in a converted garage. Walk-ins welcome. \$\$',
      },
      {
        'title': 'Don Angie',
        'subtitle': 'West Village · Italian-American',
        'image_url': '',
        'vibe_tags': ['cozy', 'creative', 'pinwheel lasagna'],
        'match_score': 78,
        'detail':
            'Italian-American with a creative twist. Known for the pinwheel lasagna. \$\$\$',
      },
    ],
  }),
  _SampleComponent('choice_stack', 'Choice Stack (Swipeable)', {
    'prompt': 'Swipe right to pick, left to skip.',
    'options': [
      {
        'title': 'Lilia',
        'subtitle': 'Williamsburg · Italian',
        'image_url': '',
        'vibe_tags': ['pasta', 'date night'],
        'match_score': 94,
        'detail': 'Michelin-starred Italian with house-made pasta.',
      },
      {
        'title': "Roberta's",
        'subtitle': 'Bushwick · Pizza',
        'image_url': '',
        'vibe_tags': ['pizza', 'casual'],
        'match_score': 81,
        'detail': 'Wood-fired pizza in a converted garage.',
      },
      {
        'title': 'Don Angie',
        'subtitle': 'West Village · Italian-American',
        'image_url': '',
        'vibe_tags': ['cozy', 'creative'],
        'match_score': 78,
        'detail': 'Known for the pinwheel lasagna.',
      },
    ],
  }),
  _SampleComponent('comparison_table', 'Comparison Table', {
    'prompt': 'Compare your top picks.',
    'options': [
      {
        'title': 'Lilia',
        'image_url': '',
        'features': {
          'Cuisine': 'Italian',
          'Price': '\$\$\$',
          'Vibe': 'Romantic',
          'Wait': '30 min',
        },
      },
      {
        'title': "Roberta's",
        'image_url': '',
        'features': {
          'Cuisine': 'Pizza',
          'Price': '\$\$',
          'Vibe': 'Casual',
          'Wait': 'Walk-in',
        },
      },
      {
        'title': 'Don Angie',
        'image_url': '',
        'features': {
          'Cuisine': 'Italian-American',
          'Price': '\$\$\$',
          'Vibe': 'Cozy',
          'Wait': '45 min',
        },
      },
    ],
  }),
  _SampleComponent('quick_confirm', 'Quick Confirm', {
    'prompt': 'Lock this in for dinner?',
    'suggestion': 'Lilia — Williamsburg, Italian',
    'image_url': '',
  }),
];
