import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block.dart';
import '../models/person.dart';
import '../models/trip.dart';
import '../models/component_response.dart';

/// Which phase of the 3-turn demo we're in.
enum DemoPhase { idle, turn1, turn2, done }

class MockDemoState {
  final Trip trip;
  final Map<String, ComponentResponse?> activeComponents;
  final DemoPhase phase;
  final Set<String> turn2Approvals;
  final Map<String, Map<String, dynamic>> flowResults;

  const MockDemoState({
    required this.trip,
    this.activeComponents = const {'person_a': null, 'person_b': null},
    this.phase = DemoPhase.idle,
    this.turn2Approvals = const {},
    this.flowResults = const <String, Map<String, dynamic>>{},
  });

  MockDemoState copyWith({
    Trip? trip,
    Map<String, ComponentResponse?>? activeComponents,
    DemoPhase? phase,
    Set<String>? turn2Approvals,
    Map<String, Map<String, dynamic>>? flowResults,
  }) =>
      MockDemoState(
        trip: trip ?? this.trip,
        activeComponents: activeComponents ?? this.activeComponents,
        phase: phase ?? this.phase,
        turn2Approvals: turn2Approvals ?? this.turn2Approvals,
        flowResults: flowResults ?? this.flowResults,
      );
}

/// 3-turn demo autodrive:
///   Turn 1 — both sidebars show [claude_thinking] placeholder (Abby's GenUI goes here)
///   Turn 2 — cross-approval via quick_confirm on both sides
///   Turn 3 — both approve → finalize
class MockTripNotifier extends StateNotifier<MockDemoState> {
  MockTripNotifier() : super(MockDemoState(trip: initialDemoTrip));

  void claimBlock(String blockId, String personId) {
    final block = state.trip.blocks[blockId];
    if (block == null || block.status != BlockStatus.unclaimed) return;
    if (state.phase != DemoPhase.idle) return;

    final updatedBlocks = Map<String, ItineraryBlock>.from(state.trip.blocks);
    updatedBlocks[blockId] = block.copyWith(status: BlockStatus.claimed, owner: personId);

    state = state.copyWith(
      trip: state.trip.copyWith(blocks: updatedBlocks),
      phase: DemoPhase.turn1,
    );

    _startDemo();
  }

  void _startDemo() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (state.phase != DemoPhase.turn1) return;

    // Both undecided blocks → inProgress
    final updatedBlocks = Map<String, ItineraryBlock>.from(state.trip.blocks);
    for (final entry in {'morning_activity': 'person_b', 'lunch': 'person_a'}.entries) {
      final b = updatedBlocks[entry.key];
      if (b != null) {
        updatedBlocks[entry.key] = b.copyWith(status: BlockStatus.inProgress, owner: entry.value);
      }
    }

    // ── PLACEHOLDER for Abby's GenUI decision flow ──
    // When the real Claude service is wired up, replace 'claude_thinking' with
    // the actual ComponentResponse returned by ClaudeService.sendInput().
    state = state.copyWith(
      trip: state.trip.copyWith(blocks: updatedBlocks),
      activeComponents: {
        'person_a': const ComponentResponse(
          targetUser: 'person_a',
          targetBlock: 'lunch',
          component: 'claude_thinking',
          props: {'label': 'Claude is selecting a lunch component…'},
        ),
        'person_b': const ComponentResponse(
          targetUser: 'person_b',
          targetBlock: 'morning_activity',
          component: 'claude_thinking',
          props: {'label': 'Claude is selecting an activity component…'},
        ),
      },
    );

    // Cross-approval is now triggered by completeDecisionFlow when both flows finish.
  }

  void _advanceToTurn2() {
    final aResult = state.flowResults['person_a'];
    final bResult = state.flowResults['person_b'];

    // Person A's name, Person B's name
    final aName = state.trip.people['person_a']?.name ?? 'Person A';
    final bName = state.trip.people['person_b']?.name ?? 'Person B';

    state = state.copyWith(
      phase: DemoPhase.turn2,
      turn2Approvals: {},
      activeComponents: {
        // Abby approves Mike's pick
        'person_a': ComponentResponse(
          targetUser: 'person_a',
          targetBlock: bResult?['blockId'] as String? ?? 'morning_activity',
          component: 'quick_confirm',
          props: {
            'title': '$bName picked ${bResult?['venue'] ?? 'something'}',
            'subtitle': bResult?['one_liner'] ?? 'Does this work for you?',
            'image_url': '',
          },
        ),
        // Mike approves Abby's pick
        'person_b': ComponentResponse(
          targetUser: 'person_b',
          targetBlock: aResult?['blockId'] as String? ?? 'lunch',
          component: 'quick_confirm',
          props: {
            'title': '$aName picked ${aResult?['venue'] ?? 'something'}',
            'subtitle': aResult?['one_liner'] ?? 'Does this work for you?',
            'image_url': '',
          },
        ),
      },
    );
  }

  /// Called by sidebar when a decision flow runner completes.
  /// Updates the block, stores the result, and triggers cross-approval
  /// once both people have finished their flows.
  void completeDecisionFlow(String personId, String blockId, Map<String, dynamic> result) {
    final updatedBlocks = Map<String, ItineraryBlock>.from(state.trip.blocks);
    final block = updatedBlocks[blockId];
    if (block != null) {
      updatedBlocks[blockId] = block.copyWith(
        status: BlockStatus.decided,
        owner: personId,
        result: {'name': result['venue'] ?? 'Decided', 'id': blockId, 'decidedBy': personId},
      );
    }

    final updatedResults = Map<String, Map<String, dynamic>>.from(state.flowResults);
    updatedResults[personId] = {'blockId': blockId, ...result};

    final updatedComponents = Map<String, ComponentResponse?>.from(state.activeComponents);
    updatedComponents[personId] = null;

    state = state.copyWith(
      trip: state.trip.copyWith(blocks: updatedBlocks),
      flowResults: updatedResults,
      activeComponents: updatedComponents,
    );

    if (updatedResults.length >= 2) {
      Future.delayed(const Duration(milliseconds: 800)).then((_) => _advanceToTurn2());
    }
  }

  void submitDecision(String personId, dynamic value) {
    if (state.phase != DemoPhase.turn2) return;

    final updatedComponents = Map<String, ComponentResponse?>.from(state.activeComponents);
    updatedComponents[personId] = null;
    final newApprovals = Set<String>.from(state.turn2Approvals)..add(personId);

    state = state.copyWith(activeComponents: updatedComponents, turn2Approvals: newApprovals);

    if (newApprovals.length >= 2) {
      Future.delayed(const Duration(milliseconds: 500)).then((_) => _finalizeTrip());
    }
  }

  void _finalizeTrip() {
    // Ensure all blocks are decided (flow results already set by completeDecisionFlow).
    final updatedBlocks = Map<String, ItineraryBlock>.from(state.trip.blocks);
    for (final id in updatedBlocks.keys) {
      final block = updatedBlocks[id]!;
      if (block.status != BlockStatus.decided) {
        updatedBlocks[id] = block.copyWith(
          status: BlockStatus.decided,
          owner: block.owner ?? 'person_a',
        );
      }
    }
    state = state.copyWith(
      trip: state.trip.copyWith(blocks: updatedBlocks),
      activeComponents: {'person_a': null, 'person_b': null},
      phase: DemoPhase.done,
    );
  }

  void reset() => state = MockDemoState(trip: initialDemoTrip, flowResults: const <String, Map<String, dynamic>>{});
}

final mockTripProvider = StateNotifierProvider<MockTripNotifier, MockDemoState>((ref) {
  return MockTripNotifier();
});

// ---------------------------------------------------------------------------
// Brooklyn day-trip seed data
// 3 pre-decided · 2 unclaimed (morning_activity + lunch)
// ---------------------------------------------------------------------------

final initialDemoTrip = Trip(
  tripId: 'demo-trip',
  destination: 'Brooklyn',
  people: {
    'person_a': const Person(id: 'person_a', name: 'Abby'),
    'person_b': const Person(id: 'person_b', name: 'Mike'),
  },
  blocks: {
    'breakfast': const ItineraryBlock(
      id: 'breakfast',
      label: 'Breakfast',
      timeRange: '9:00 – 10:00am',
      category: BlockCategory.meal,
      status: BlockStatus.decided,
      owner: 'person_a',
      result: {'name': 'Win Son', 'id': 'win_son'},
    ),
    'morning_activity': const ItineraryBlock(
      id: 'morning_activity',
      label: 'Morning Activity',
      timeRange: '10:00am – 12:00pm',
      category: BlockCategory.activity,
      status: BlockStatus.unclaimed,
    ),
    'lunch': const ItineraryBlock(
      id: 'lunch',
      label: 'Lunch',
      timeRange: '12:00 – 1:30pm',
      category: BlockCategory.meal,
      status: BlockStatus.unclaimed,
    ),
    'afternoon_activity': const ItineraryBlock(
      id: 'afternoon_activity',
      label: 'Afternoon Activity',
      timeRange: '1:30 – 4:30pm',
      category: BlockCategory.activity,
      status: BlockStatus.decided,
      owner: 'person_b',
      result: {'name': 'Brooklyn Museum', 'id': 'bk_museum'},
    ),
    'dinner': const ItineraryBlock(
      id: 'dinner',
      label: 'Dinner',
      timeRange: '6:00 – 8:00pm',
      category: BlockCategory.meal,
      status: BlockStatus.decided,
      owner: 'person_a',
      result: {'name': "Francie's", 'id': 'frances', 'decidedBy': 'person_a'},
    ),
    'evening_activity': const ItineraryBlock(
      id: 'evening_activity',
      label: 'Evening Activity',
      timeRange: '9:00 – 11:00pm',
      category: BlockCategory.activity,
      status: BlockStatus.decided,
      owner: 'person_b',
      result: {'name': 'Nitehawk Cinema', 'id': 'nitehawk', 'decidedBy': 'person_b'},
    ),
  },
);
