class Person {
  final String id;
  final String name;
  final List<String> claimedBlocks;
  final Map<String, dynamic> browsePreferences;

  const Person({
    required this.id,
    required this.name,
    this.claimedBlocks = const [],
    this.browsePreferences = const {},
  });

  factory Person.fromMap(String id, Map<String, dynamic> map) {
    return Person(
      id: id,
      name: map['name'] as String? ?? id,
      claimedBlocks: List<String>.from(map['claimed_blocks'] ?? []),
      browsePreferences: Map<String, dynamic>.from(
        map['browse_preferences'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'claimed_blocks': claimedBlocks,
        'browse_preferences': browsePreferences,
      };

  Person copyWith({
    String? name,
    List<String>? claimedBlocks,
    Map<String, dynamic>? browsePreferences,
  }) =>
      Person(
        id: id,
        name: name ?? this.name,
        claimedBlocks: claimedBlocks ?? this.claimedBlocks,
        browsePreferences: browsePreferences ?? this.browsePreferences,
      );
}
