/// Represents the structured JSON response from Claude.
///
/// Claude responds with exactly this shape for every step:
/// {
///   "target_user": "person_a",
///   "target_block": "lunch",
///   "component": "comparison_cards",
///   "props": { ... }
/// }
class ComponentResponse {
  final String targetUser;   // person_id or 'both'
  final String targetBlock;  // block id, e.g. 'lunch'
  final String component;    // component name from catalog
  final Map<String, dynamic> props;

  const ComponentResponse({
    required this.targetUser,
    required this.targetBlock,
    required this.component,
    required this.props,
  });

  factory ComponentResponse.fromJson(Map<String, dynamic> json) {
    return ComponentResponse(
      targetUser: json['target_user'] as String,
      targetBlock: json['target_block'] as String,
      component: json['component'] as String,
      props: Map<String, dynamic>.from(json['props'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'target_user': targetUser,
        'target_block': targetBlock,
        'component': component,
        'props': props,
      };
}
