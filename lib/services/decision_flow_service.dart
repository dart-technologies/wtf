import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/block.dart';
import '../models/component_response.dart';

/// State of a single block's decision flow.
enum FlowState { idle, loading, active, done, error }

/// Runs a multi-turn decision flow for one person deciding one itinerary block.
///
/// In mock mode (default), serves a pre-built component sequence for testing
/// without API calls. In live mode, manages a Claude conversation using the
/// persona agent prompt from docs/prompt_first_draft.md.
///
/// Usage:
/// ```dart
/// final runner = DecisionFlowRunner(personId: 'person_a', block: lunchBlock);
/// runner.addListener(() => setState(() {}));
/// await runner.start();           // first component appears
/// await runner.submit(userResult); // next component or done
/// ```
class DecisionFlowRunner extends ChangeNotifier {
  final String personId;
  final ItineraryBlock block;
  final Map<String, dynamic>? geographicContext;
  final String? apiKey;
  final bool useMock;

  FlowState _state = FlowState.idle;
  ComponentResponse? _currentComponent;
  Map<String, dynamic>? _finalResult;
  String? _error;
  int _stepIndex = 0;

  // Claude conversation history (live mode only)
  final List<Map<String, String>> _messages = [];

  // All user submissions across the flow
  final List<Map<String, dynamic>> _userResponses = [];

  // Mock flow state
  late final List<ComponentResponse> _mockFlow;
  int _mockStep = 0;

  DecisionFlowRunner({
    required this.personId,
    required this.block,
    this.geographicContext,
    this.apiKey,
    this.useMock = true,
  }) {
    if (useMock) {
      _mockFlow = _buildMockFlow();
    }
  }

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  FlowState get state => _state;
  ComponentResponse? get currentComponent => _currentComponent;
  Map<String, dynamic>? get finalResult => _finalResult;
  String? get error => _error;
  int get stepIndex => _stepIndex;
  int get totalMockSteps => useMock ? _mockFlow.length : 0;
  List<Map<String, dynamic>> get userResponses =>
      List.unmodifiable(_userResponses);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Kick off the decision flow. Sends initial context to Claude (or serves
  /// the first mock component) and transitions to [FlowState.active].
  Future<void> start() async {
    _state = FlowState.loading;
    _stepIndex = 0;
    notifyListeners();

    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        _currentComponent = _mockFlow[0];
        _mockStep = 1;
        _state = FlowState.active;
      } else {
        final brief = await _buildInitialBrief();
        _messages.add({'role': 'user', 'content': brief});
        final raw = await _callClaude();
        _messages.add({'role': 'assistant', 'content': raw});
        _processClaudeResponse(raw);
      }
    } catch (e) {
      _error = e.toString();
      _state = FlowState.error;
    }
    notifyListeners();
  }

  /// Submit the user's response to the current component. Sends it to Claude
  /// (or advances the mock) and either shows the next component or finishes.
  Future<void> submit(Map<String, dynamic> result) async {
    _userResponses.add(result);
    _state = FlowState.loading;
    _stepIndex++;
    notifyListeners();

    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (_mockStep >= _mockFlow.length) {
          _finalResult = _extractResult();
          _state = FlowState.done;
        } else {
          _currentComponent = _mockFlow[_mockStep];
          _mockStep++;
          _state = FlowState.active;
        }
      } else {
        final msg = jsonEncode({
          'component_responded': _currentComponent?.component,
          'user_response': result,
        });
        _messages.add({'role': 'user', 'content': msg});
        final raw = await _callClaude();
        _messages.add({'role': 'assistant', 'content': raw});
        _processClaudeResponse(raw);
      }
    } catch (e) {
      _error = e.toString();
      _state = FlowState.error;
    }
    notifyListeners();
  }

  /// Reset to idle so the user can pick a different block.
  void reset() {
    _state = FlowState.idle;
    _currentComponent = null;
    _finalResult = null;
    _error = null;
    _stepIndex = 0;
    _mockStep = 0;
    _messages.clear();
    _userResponses.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Claude API (live mode)
  // ---------------------------------------------------------------------------

  Future<String> _buildInitialBrief() async {
    final domain = block.category == BlockCategory.meal ? 'meal' : 'activity';
    final venues = await _loadVenuesForCategory();
    return jsonEncode({
      'block_id': block.id,
      'domain': domain,
      'time_range': block.timeRange,
      'geographic_context': geographicContext ?? {},
      'user_responses_so_far': [],
      if (venues.isNotEmpty) 'available_venues': venues,
    });
  }

  /// Load seed venues filtered to this block's category.
  Future<List<Map<String, dynamic>>> _loadVenuesForCategory() async {
    try {
      final raw = await rootBundle.loadString('data/seed.json');
      final all = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
      return all.where((v) => v['category'] == block.id).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> _callClaude() async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw Exception(
          'No API key configured. Set apiKey or use mock mode.');
    }

    debugPrint('[WTF] Calling Claude API (${_messages.length} messages)...');

    final body = jsonEncode({
      'model': 'claude-haiku-4-5-20251001',
      'max_tokens': 1024,
      'system': personaAgentPrompt,
      'messages': _messages,
    });

    // Route through local proxy to avoid CORS in Flutter web.
    // The proxy adds the API key and forwards to Anthropic.
    const proxyUrl = 'http://localhost:8080/v1/messages';
    final resp = await http.post(
      Uri.parse(proxyUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      debugPrint('[WTF] Claude API error: ${resp.statusCode}');
      debugPrint('[WTF] Response: ${resp.body}');
      throw Exception('Claude API ${resp.statusCode}: ${resp.body}');
    }

    debugPrint('[WTF] Claude responded OK');

    final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
    return (parsed['content'] as List).first['text'] as String;
  }

  void _processClaudeResponse(String raw) {
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final json = jsonDecode(cleaned) as Map<String, dynamic>;

    final flowState = json['flow_state'] as String? ?? 'continue';

    _currentComponent = ComponentResponse(
      targetUser: personId,
      targetBlock: block.id,
      component: json['component'] as String,
      props: Map<String, dynamic>.from(json['props'] ?? {}),
    );

    if (flowState == 'done') {
      _finalResult =
          json['result'] as Map<String, dynamic>? ?? _extractResult();
      _state = FlowState.done;
    } else {
      _state = FlowState.active;
    }
  }

  // ---------------------------------------------------------------------------
  // Result extraction
  // ---------------------------------------------------------------------------

  /// Try to pull a meaningful venue result from user submissions.
  Map<String, dynamic> _extractResult() {
    for (final resp in _userResponses.reversed) {
      if (resp.containsKey('selected') && resp['selected'] is Map) {
        final sel = resp['selected'] as Map;
        return {
          'venue': sel['title'] ?? 'Selected venue',
          'neighborhood':
              (sel['subtitle'] as String?)?.split('\u00b7').first.trim() ?? '',
          'one_liner': sel['detail'] ?? '',
        };
      }
    }
    return {
      'venue': 'Decision complete',
      'one_liner': '${_userResponses.length} interactions',
    };
  }

  // ---------------------------------------------------------------------------
  // Mock flows
  // ---------------------------------------------------------------------------

  List<ComponentResponse> _buildMockFlow() {
    return block.category == BlockCategory.meal
        ? _mealMockFlow()
        : _activityMockFlow();
  }

  /// Meal flow: mood_board → vibe_slider → comparison_cards → quick_confirm
  List<ComponentResponse> _mealMockFlow() {
    final bid = block.id;
    final label = block.label.toLowerCase();
    return [
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'mood_board',
        props: {
          'prompt': 'What does $label feel like?',
          'max_select': 2,
          'options': [
            {'label': 'Cozy corner spot', 'image_url': ''},
            {'label': 'Trendy & buzzing', 'image_url': ''},
            {'label': 'Classic NYC deli', 'image_url': ''},
            {'label': 'Adventurous eats', 'image_url': ''},
            {'label': 'Chill caf\u00e9 vibes', 'image_url': ''},
            {'label': 'Something fancy', 'image_url': ''},
          ],
        },
      ),
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'vibe_slider',
        props: {
          'left_label': 'Casual',
          'right_label': 'Fancy',
          'left_image': '',
          'right_image': '',
        },
      ),
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'comparison_cards',
        props: {
          'prompt': 'Three spots that match the vibe.',
          'expandable': true,
          'options': [
            {
              'title': 'Lilia',
              'subtitle': 'Williamsburg \u00b7 Italian',
              'image_url': '',
              'vibe_tags': ['pasta', 'date night', 'warm'],
              'match_score': 94,
              'detail':
                  'Michelin-starred Italian with house-made pasta. Reservations recommended. \$\$\$',
            },
            {
              'title': "Roberta's",
              'subtitle': 'Bushwick \u00b7 Pizza',
              'image_url': '',
              'vibe_tags': ['pizza', 'casual', 'brooklyn'],
              'match_score': 81,
              'detail':
                  'Wood-fired pizza in a converted garage. Walk-ins welcome. \$\$',
            },
            {
              'title': 'Don Angie',
              'subtitle': 'West Village \u00b7 Italian-American',
              'image_url': '',
              'vibe_tags': ['cozy', 'creative', 'pinwheel lasagna'],
              'match_score': 78,
              'detail':
                  'Italian-American with a creative twist. Known for the pinwheel lasagna. \$\$\$',
            },
          ],
        },
      ),
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'quick_confirm',
        props: {
          'prompt': 'Lock this in for $label?',
          'suggestion': 'Lilia \u2014 Williamsburg, Italian',
          'image_url': '',
        },
      ),
    ];
  }

  /// Activity flow: this_or_that → vibe_slider_2d → comparison_cards → quick_confirm
  List<ComponentResponse> _activityMockFlow() {
    final bid = block.id;
    final label = block.label.toLowerCase();
    return [
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'this_or_that',
        props: {
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
        },
      ),
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'vibe_slider_2d',
        props: {
          'x_left_label': 'Local',
          'x_right_label': 'Tourist',
          'y_top_label': 'High-energy',
          'y_bottom_label': 'Chill',
        },
      ),
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'comparison_cards',
        props: {
          'prompt': 'Three options that match your energy.',
          'expandable': true,
          'options': [
            {
              'title': 'The High Line',
              'subtitle': 'Chelsea \u00b7 Walk',
              'image_url': '',
              'vibe_tags': ['outdoors', 'views', 'iconic'],
              'match_score': 91,
              'detail':
                  'Elevated park with art installations and Hudson River views. Free, about 1.5 miles.',
            },
            {
              'title': 'Brooklyn Flea',
              'subtitle': 'DUMBO \u00b7 Market',
              'image_url': '',
              'vibe_tags': ['vintage', 'food stalls', 'waterfront'],
              'match_score': 85,
              'detail':
                  'Weekend market with vintage finds, local crafts, and great food. Manhattan Bridge views.',
            },
            {
              'title': 'The Met Cloisters',
              'subtitle': 'Fort Tryon Park \u00b7 Museum',
              'image_url': '',
              'vibe_tags': ['quiet', 'medieval', 'gardens'],
              'match_score': 76,
              'detail':
                  'Medieval art in a peaceful uptown setting. Beautiful gardens. Pay-what-you-wish.',
            },
          ],
        },
      ),
      ComponentResponse(
        targetUser: personId,
        targetBlock: bid,
        component: 'quick_confirm',
        props: {
          'prompt': 'Lock this in for $label?',
          'suggestion': 'The High Line \u2014 Chelsea, elevated park walk',
          'image_url': '',
        },
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Persona Agent System Prompt
// ---------------------------------------------------------------------------
//
// Based on docs/prompt_first_draft.md — same philosophy, real component names.
// Exported so ClaudeService or tests can reference it.

const personaAgentPrompt = '''
You are a Persona Agent for "Where To Flock," a collaborative NYC day planner.

You guide one person through deciding a single itinerary block — a meal or activity in their NYC day. Take them from "I have no idea" to "that's the one" in 2–4 steps by choosing the right type of question at each step.

## The Narrowing Funnel

1. **Vibe** — What does this moment feel like? Use visual/spatial components.
2. **Shape** — Refine along dimensions that matter. Use spectrum components.
3. **Options** — Specific venues that match. Use comparison components.
4. **Lock** — Confirm the pick (only if the prior step was ambiguous).

Skip steps when the user gives decisive signals. If they say "loud cheap dumplings" — skip straight to options. If they enthusiastically pick a venue — skip confirm. Match the funnel speed to their energy.

## Component Catalog

### Early funnel (discovering vibes)

**mood_board** — Discover vibe through images. Best for opening meal decisions.
Props: { "prompt": str, "options": [{"label": str, "image_url": str}], "max_select": int }
Provide 4–6 options spanning a wide aesthetic range.

**this_or_that** — Rapid binary preferences. Best for opening activity decisions.
Props: { "pairs": [{"left": {"label": str, "image_url": str}, "right": {"label": str, "image_url": str}}] }
2–3 pairs max before it gets tedious.

**vibe_slider_2d** — Two independent axes that both matter (e.g. tourist↔local × chill↔energetic). One per block max.
Props: { "x_left_label": str, "x_right_label": str, "y_top_label": str, "y_bottom_label": str }

### Mid funnel (refining)

**vibe_slider** — One meaningful spectrum (casual↔fancy, budget↔splurge). Labels should be concrete and evocative.
Props: { "left_label": str, "right_label": str, "left_image": str, "right_image": str }

### Late funnel (evaluating options)

**comparison_cards** — 2–4 venue cards with expandable detail. Include match_score (0–100) and vibe_tags.
Props: { "prompt": str, "options": [{"title": str, "subtitle": "Neighborhood · Category", "image_url": str, "vibe_tags": [str], "match_score": int, "detail": str}], "expandable": bool }

**comparison_table** — Feature-based side-by-side for analytical decisions.
Props: { "prompt": str, "options": [{"title": str, "image_url": str, "features": {"key": "value"}}] }

### Confirm

**quick_confirm** — Yes/no on the selected venue. Skip if they were decisive in the options step.
Props: { "prompt": str, "suggestion": str, "image_url": str }

## Domain Defaults

**Meals** are vibe-first. People choose restaurants by how they want to feel — cozy, adventurous, celebratory, efficient. Start with mood_board or vibe_slider on the casual↔fancy axis. Neighborhood matters for meals, so factor geographic constraints early.

**Activities** are structure-first. First useful cut is usually physical (indoors/outdoors) or energy (chill/active). Start with this_or_that, then refine with vibe_slider or vibe_slider_2d. Activities vary more in duration and geography — transition time to adjacent blocks matters.

These are defaults, not rules. A foodie who says "ramen" gets options immediately. An activity after heavy lunch might start with vibes instead.

## Reading Responses

After each user submission, assess:
- **Decisiveness**: Instant pick → accelerate. Exploring → add a shaping step.
- **Specificity**: Named a thing ("ramen," "the Met") → jump to matching options. Abstract ("something chill") → another vibe step.
- **Constraints**: "nothing too far," "vegetarian" → factor immediately.
- **Enthusiasm**: Spike on one option → lean in hard.

## Geographic Context

You receive context about already-decided blocks. Use it to avoid suggesting the same neighborhood as adjacent blocks and factor transition time. Name constraints when relevant: "Since you'll be near the West Village around 1:30..."

Don't over-constrain when few blocks are decided.

## Tone

You're a friend who knows every neighborhood, not a concierge reading from a binder. Be opinionated when you have reason. "Loud, cramped, perfect" beats "casual dining environment." Use voice.

## Venue Data

When the initial brief includes "available_venues", you MUST select from those venues for comparison_cards and quick_confirm. Use their exact names, neighborhoods, vibe_tags, one_liners, and price tiers. For image_url, use their unsplash_search_term value so the client can resolve images.

When no venue data is provided, generate plausible NYC restaurants and activities. Use real neighborhood names, transit context, authentic vibes. For image_url fields, use empty strings.

## Response Format

ALWAYS respond with exactly one JSON object. No markdown fences, no explanation outside the JSON.

{
  "component": "component_name",
  "props": { ... },
  "flow_state": "continue",
  "reasoning": "why this component now (for debugging, not shown to user)"
}

When the decision is complete, set flow_state to "done" and include the result:

{
  "component": "quick_confirm",
  "props": { ... },
  "flow_state": "done",
  "reasoning": "...",
  "result": {
    "venue": "Venue Name",
    "neighborhood": "NYC Neighborhood",
    "one_liner": "Short evocative description",
    "vibe_tags": ["tag1", "tag2"]
  }
}

## Input Format

First message: JSON brief with block_id, domain, time_range, and geographic_context.
Subsequent messages: JSON with the component you sent and the user's response to it.
''';
