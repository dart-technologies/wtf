import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/component_response.dart';

/// Client for Claude API. Sends labeled user inputs and parses structured
/// JSON component responses.
///
/// TODO(abby): implement prompt construction, conversation history,
///             decision flow per block, conflict detection, final plan.
class ClaudeService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  final String _apiKey;

  /// In-memory conversation history for the current trip session.
  /// All messages are labeled by person so Claude maintains context.
  final List<Map<String, String>> _history = [];

  /// Pass [apiKey] directly, or leave null to read from .env.
  ClaudeService({String? apiKey})
      : _apiKey = apiKey ?? dotenv.get('CLAUDE_API_KEY', fallback: '');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sends a labeled user action and returns Claude's component response.
  ///
  /// [personId] — 'person_a' or 'person_b'
  /// [blockId]  — which itinerary block this input relates to
  /// [input]    — human-readable description of the action taken
  ///
  /// Example: sendInput('person_a', 'lunch', 'selected "cozy ramen" from mood board')
  Future<ComponentResponse> sendInput({
    required String personId,
    required String blockId,
    required String input,
  }) async {
    final label = '[${_personLabel(personId)} selected "$input" for $blockId]';
    _history.add({'role': 'user', 'content': label});

    final response = await _callClaude();
    _history.add({'role': 'assistant', 'content': response});

    return _parseResponse(response);
  }

  /// Asks Claude to generate the final plan from the decided blocks.
  Future<Map<String, dynamic>> generateFinalPlan({
    required Map<String, dynamic> decidedBlocks,
  }) async {
    final prompt =
        '[All blocks decided. Generate final_plan JSON with final_plan_card props for each block.]';
    _history.add({'role': 'user', 'content': prompt});

    final response = await _callClaude();
    _history.add({'role': 'assistant', 'content': response});

    // TODO(abby): parse final plan from response
    return jsonDecode(response) as Map<String, dynamic>;
  }

  /// Resets the conversation history (e.g. new trip session).
  void reset() => _history.clear();

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  String _personLabel(String personId) {
    return personId == 'person_a' ? 'Person A' : 'Person B';
  }

  Future<String> _callClaude() async {
    final body = jsonEncode({
      'model': 'claude-haiku-4-5-20251001',
      'max_tokens': 1024,
      'system': _systemPrompt,
      'messages': _history,
    });

    final resp = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Claude API error ${resp.statusCode}: ${resp.body}');
    }

    final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
    return (parsed['content'] as List).first['text'] as String;
  }

  ComponentResponse _parseResponse(String raw) {
    // Claude should return a JSON code block. Strip markdown fences if present.
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    return ComponentResponse.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // System prompt
  // ---------------------------------------------------------------------------

  // TODO(abby): expand this prompt with full decision flow specs, component
  //             catalog with prop schemas, conflict detection rules, and
  //             final plan generation instructions.
  static const _systemPrompt = '''
You are the AI planner for "Where To Flock", a collaborative NYC day-trip app.

Two people are planning a shared day together. You manage the itinerary and guide each person through decisions about their claimed sections, selecting the right UI component for each decision.

## Your job
- Receive labeled inputs from Person A and Person B.
- For each input, respond with a single JSON object specifying the next component to show.
- Select the component that best fits the decision type, domain, and person's preferences.
- After 2-3 steps per block, mark it as decided and include the result.
- If two decisions create a logistical conflict, surface it with a conflict_card.

## Response format (ALWAYS return valid JSON, no extra text)
```json
{
  "target_user": "person_a",
  "target_block": "lunch",
  "component": "comparison_cards",
  "props": { ... }
}
```

## Component catalog
- mood_board: { "prompt": str, "options": [{"label": str, "image_url": str}], "max_select": int }
- this_or_that: { "pairs": [{"left": {"label": str, "image_url": str}, "right": {"label": str, "image_url": str}}] }
- vibe_slider: { "left_label": str, "right_label": str, "left_image": str, "right_image": str }
- vibe_slider_2d: { "x_left_label": str, "x_right_label": str, "y_top_label": str, "y_bottom_label": str }
- comparison_cards: { "prompt": str, "options": [{"title": str, "image_url": str, "subtitle": str, "vibe_tags": [str], "detail": str}], "expandable": bool }
- comparison_table: { "prompt": str, "options": [{"title": str, "image_url": str, "features": {str: str}}] }
- quick_confirm: { "prompt": str, "suggestion": str, "image_url": str }
- conflict_card: { "description": str, "options": [{"label": str, "detail": str}] }
- final_plan_card: { "title": str, "time": str, "description": str, "image_url": str, "highlights": [str], "vibe_color": str }

## NYC context
Generate plausible NYC restaurants and activities. Use real neighborhood names, transit details, and authentic vibe descriptions. For image_url fields, use descriptive placeholder strings (e.g. "chinatown_dumpling_shop") — the client will resolve these.
''';
}
