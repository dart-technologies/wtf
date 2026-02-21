import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' show kDemoMode;
import '../models/block.dart';
import '../models/person.dart';
import '../models/trip.dart';
import '../models/component_response.dart';
import '../services/firebase_service.dart';
import '../widgets/layout/three_panel_layout.dart';

final _firebaseService = FirebaseService();

final tripProvider = Provider.family<AsyncValue<Trip?>, String>((ref, tripId) {
  if (kDemoMode) {
    final state = ref.watch(mockTripProvider);
    return AsyncValue.data(state.trip);
  }
  return ref.watch(_firebaseStreamProvider(tripId));
});

final _firebaseStreamProvider = StreamProvider.family<Trip?, String>((ref, tripId) {
  return _firebaseService.watchTrip(tripId);
});

/// Which phase of the 3-turn demo we're in.
enum DemoPhase { idle, turn1, turn2, done }

class MockDemoState {
  final Trip trip;
  final Map<String, ComponentResponse?> activeComponents;
  final DemoPhase phase;
  final Set<String> turn2Approvals;

  const MockDemoState({
    required this.trip,
    this.activeComponents = const {'person_a': null, 'person_b': null},
    this.phase = DemoPhase.idle,
    this.turn2Approvals = const {},
  });

  MockDemoState copyWith({
    Trip? trip,
    Map<String, ComponentResponse?>? activeComponents,
    DemoPhase? phase,
    Set<String>? turn2Approvals,
  }) =>
      MockDemoState(
        trip: trip ?? this.trip,
        activeComponents: activeComponents ?? this.activeComponents,
        phase: phase ?? this.phase,
        turn2Approvals: turn2Approvals ?? this.turn2Approvals,
      );
}

/// 3-turn demo autodrive:
///   Turn 1 — both sidebars show [claude_thinking] placeholder (Abby's GenUI goes here)
///   Turn 2 — cross-approval via quick_confirm on both sides
///   Turn 3 — both approve → finalize
class MockTripNotifier extends StateNotifier<MockDemoState> {
  MockTripNotifier() : super(MockDemoState(trip: _initialDemoTrip));

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

    // Auto-advance to cross-approval after thinking pause
    await Future.delayed(const Duration(milliseconds: 2500));
    if (state.phase == DemoPhase.turn1) _advanceToTurn2();
  }

  void _advanceToTurn2() {
    state = state.copyWith(
      phase: DemoPhase.turn2,
      turn2Approvals: {},
      activeComponents: {
        // Abby approves Mike's morning activity
        'person_a': const ComponentResponse(
          targetUser: 'person_a',
          targetBlock: 'morning_activity',
          component: 'quick_confirm',
          props: {
            'title': 'Mike is heading to Brooklyn Bridge Park',
            'subtitle': 'Waterfront walk through DUMBO with Manhattan skyline views. Work for the morning?',
            'image_url': 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=600',
          },
        ),
        // Mike approves Abby's lunch pick
        'person_b': const ComponentResponse(
          targetUser: 'person_b',
          targetBlock: 'lunch',
          component: 'quick_confirm',
          props: {
            'title': "Abby's going to Lucali's",
            'subtitle': 'Carroll Gardens wood-fired pizza. BYOB and legendary. You in?',
            'image_url': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600',
          },
        ),
      },
    );
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
    final updatedBlocks = Map<String, ItineraryBlock>.from(state.trip.blocks);
    const results = {
      'breakfast': {'name': 'Win Son', 'id': 'win_son', 'decidedBy': 'person_a'},
      'morning_activity': {'name': 'Brooklyn Bridge Park', 'id': 'bb_park', 'decidedBy': 'person_b', 'approvedBy': 'person_a'},
      'lunch': {'name': "Lucali's", 'id': 'lucalis', 'decidedBy': 'person_a', 'approvedBy': 'person_b'},
      'afternoon_activity': {'name': 'Brooklyn Museum', 'id': 'bk_museum', 'decidedBy': 'person_b'},
      'dinner': {'name': "Francie's", 'id': 'frances', 'decidedBy': 'person_a'},
      'evening_activity': {'name': 'Nitehawk Cinema', 'id': 'nitehawk', 'decidedBy': 'person_b'},
    };
    const owners = {
      'breakfast': 'person_a',
      'morning_activity': 'person_b',
      'lunch': 'person_a',
      'afternoon_activity': 'person_b',
      'dinner': 'person_a',
      'evening_activity': 'person_b',
    };
    for (final id in updatedBlocks.keys) {
      updatedBlocks[id] = updatedBlocks[id]!.copyWith(
        status: BlockStatus.decided,
        owner: owners[id] ?? 'person_a',
        result: results[id],
      );
    }
    state = state.copyWith(
      trip: state.trip.copyWith(blocks: updatedBlocks),
      activeComponents: {'person_a': null, 'person_b': null},
      phase: DemoPhase.done,
    );
  }

  void reset() => state = MockDemoState(trip: _initialDemoTrip);
}

final mockTripProvider = StateNotifierProvider<MockTripNotifier, MockDemoState>((ref) {
  return MockTripNotifier();
});

class TripScreen extends ConsumerWidget {
  final String tripId;
  const TripScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider(tripId));
    return Scaffold(
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trip) {
          if (trip == null) return const _TripNotFound();
          return ThreePanelLayout(trip: trip, tripId: tripId);
        },
      ),
    );
  }
}

class _TripNotFound extends StatelessWidget {
  const _TripNotFound();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Trip not found.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (!kDemoMode) {
                await _firebaseService.createTrip(
                  tripId: 'demo-trip',
                  destination: 'Brooklyn',
                  personAName: 'Abby',
                  personBName: 'Mike',
                );
              }
            },
            child: const Text('Create Demo Trip'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brooklyn day-trip seed data
// 3 pre-decided · 2 unclaimed (morning_activity + lunch)
// ---------------------------------------------------------------------------

final _initialDemoTrip = Trip(
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
