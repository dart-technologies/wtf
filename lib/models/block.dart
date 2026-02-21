enum BlockStatus { unclaimed, claimed, inProgress, decided }

enum BlockCategory { meal, activity }

class ItineraryBlock {
  final String id;
  final String label;
  final String timeRange;
  final BlockCategory category;
  final BlockStatus status;
  final String? owner; // person_id, 'ai', or null
  final List<Map<String, dynamic>> decisions;
  final Map<String, dynamic>? result;

  const ItineraryBlock({
    required this.id,
    required this.label,
    required this.timeRange,
    required this.category,
    this.status = BlockStatus.unclaimed,
    this.owner,
    this.decisions = const [],
    this.result,
  });

  factory ItineraryBlock.fromMap(String id, Map<String, dynamic> map) {
    return ItineraryBlock(
      id: id,
      label: map['label'] as String? ?? id,
      timeRange: map['time_range'] as String? ?? '',
      category: map['category'] == 'meal'
          ? BlockCategory.meal
          : BlockCategory.activity,
      status: _parseStatus(map['status'] as String?),
      owner: map['owner'] as String?,
      decisions: List<Map<String, dynamic>>.from(map['decisions'] ?? []),
      result: map['result'] != null
          ? Map<String, dynamic>.from(map['result'])
          : null,
    );
  }

  static BlockStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'claimed':
        return BlockStatus.claimed;
      case 'in_progress':
        return BlockStatus.inProgress;
      case 'decided':
        return BlockStatus.decided;
      default:
        return BlockStatus.unclaimed;
    }
  }

  String get statusString {
    switch (status) {
      case BlockStatus.unclaimed:
        return 'unclaimed';
      case BlockStatus.claimed:
        return 'claimed';
      case BlockStatus.inProgress:
        return 'in_progress';
      case BlockStatus.decided:
        return 'decided';
    }
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'time_range': timeRange,
        'category': category == BlockCategory.meal ? 'meal' : 'activity',
        'status': statusString,
        'owner': owner,
        'decisions': decisions,
        'result': result,
      };

  ItineraryBlock copyWith({
    BlockStatus? status,
    String? owner,
    List<Map<String, dynamic>>? decisions,
    Map<String, dynamic>? result,
  }) =>
      ItineraryBlock(
        id: id,
        label: label,
        timeRange: timeRange,
        category: category,
        status: status ?? this.status,
        owner: owner ?? this.owner,
        decisions: decisions ?? this.decisions,
        result: result ?? this.result,
      );
}

/// The canonical ordered list of itinerary blocks for a day trip.
final List<ItineraryBlock> defaultBlocks = [
  const ItineraryBlock(
    id: 'breakfast',
    label: 'Breakfast',
    timeRange: '9:00 – 10:00am',
    category: BlockCategory.meal,
  ),
  const ItineraryBlock(
    id: 'morning_activity',
    label: 'Morning Activity',
    timeRange: '10:00am – 12:00pm',
    category: BlockCategory.activity,
  ),
  const ItineraryBlock(
    id: 'lunch',
    label: 'Lunch',
    timeRange: '12:00 – 1:30pm',
    category: BlockCategory.meal,
  ),
  const ItineraryBlock(
    id: 'afternoon_activity',
    label: 'Afternoon Activity',
    timeRange: '1:30 – 4:30pm',
    category: BlockCategory.activity,
  ),
  const ItineraryBlock(
    id: 'dinner',
    label: 'Dinner',
    timeRange: '6:00 – 8:00pm',
    category: BlockCategory.meal,
  ),
];
