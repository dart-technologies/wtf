import 'block.dart';
import 'person.dart';

class Trip {
  final String tripId;
  final String destination;
  final Map<String, Person> people;
  final Map<String, ItineraryBlock> blocks;
  final List<Map<String, dynamic>> conflicts;
  final Map<String, dynamic>? finalPlan;

  const Trip({
    required this.tripId,
    required this.destination,
    required this.people,
    required this.blocks,
    this.conflicts = const [],
    this.finalPlan,
  });

  factory Trip.fromMap(String tripId, Map<String, dynamic> map) {
    final rawPeople = Map<String, dynamic>.from(map['people'] ?? {});
    final people = rawPeople.map(
      (id, data) => MapEntry(id, Person.fromMap(id, Map<String, dynamic>.from(data))),
    );

    final rawBlocks = Map<String, dynamic>.from(map['blocks'] ?? {});
    final blocks = rawBlocks.map(
      (id, data) => MapEntry(
        id,
        ItineraryBlock.fromMap(id, Map<String, dynamic>.from(data)),
      ),
    );

    return Trip(
      tripId: tripId,
      destination: map['destination'] as String? ?? 'NYC',
      people: people,
      blocks: blocks,
      conflicts: List<Map<String, dynamic>>.from(map['conflicts'] ?? []),
      finalPlan: map['final_plan'] != null
          ? Map<String, dynamic>.from(map['final_plan'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'destination': destination,
        'people': people.map((id, p) => MapEntry(id, p.toMap())),
        'blocks': blocks.map((id, b) => MapEntry(id, b.toMap())),
        'conflicts': conflicts,
        'final_plan': finalPlan,
      };

  /// Ordered list of blocks for display in the itinerary.
  List<ItineraryBlock> get orderedBlocks {
    const order = [
      'breakfast',
      'morning_activity',
      'lunch',
      'afternoon_activity',
      'dinner',
      'evening_activity',
    ];
    return order
        .where(blocks.containsKey)
        .map((id) => blocks[id]!)
        .toList();
  }

  List<ItineraryBlock> blocksFor(String personId) =>
      blocks.values.where((b) => b.owner == personId).toList();

  Trip copyWith({
    String? destination,
    Map<String, Person>? people,
    Map<String, ItineraryBlock>? blocks,
    List<Map<String, dynamic>>? conflicts,
    Map<String, dynamic>? finalPlan,
  }) {
    return Trip(
      tripId: tripId,
      destination: destination ?? this.destination,
      people: people ?? this.people,
      blocks: blocks ?? this.blocks,
      conflicts: conflicts ?? this.conflicts,
      finalPlan: finalPlan ?? this.finalPlan,
    );
  }
}
