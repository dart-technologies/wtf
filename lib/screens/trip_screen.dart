import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' show kDemoMode;
import '../models/block.dart';
import '../models/person.dart';
import '../models/trip.dart';
import '../services/firebase_service.dart';
import '../widgets/layout/three_panel_layout.dart';

final _firebaseService = FirebaseService();

final tripProvider = StreamProvider.family<Trip?, String>((ref, tripId) {
  if (kDemoMode) return Stream.value(_demoTrip);
  return _firebaseService.watchTrip(tripId);
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
              await _firebaseService.createTrip(
                tripId: 'demo-trip',
                destination: 'NYC',
                personAName: 'Abby',
                personBName: 'Mike',
              );
            },
            child: const Text('Create Demo Trip'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo data — used when kDemoMode = true
// ---------------------------------------------------------------------------

final _demoTrip = Trip(
  tripId: 'demo-trip',
  destination: 'NYC',
  people: {
    'person_a': const Person(id: 'person_a', name: 'Abby'),
    'person_b': const Person(id: 'person_b', name: 'Mike'),
  },
  blocks: {
    for (final b in defaultBlocks)
      b.id: b.copyWith(
        status: BlockStatus.claimed,
        owner: const {
          'breakfast': 'person_b',
          'morning_activity': 'person_a',
          'lunch': 'person_a',
          'afternoon_activity': 'person_b',
          'dinner': 'person_b',
        }[b.id],
      ),
  },
);
