import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' show kDemoMode;
import '../models/trip.dart';
import '../providers/demo_providers.dart';
import '../services/firebase_service.dart';
import '../widgets/layout/three_panel_layout.dart';

final _firebaseService = FirebaseService();

final _firebaseStreamProvider = StreamProvider.family<Trip?, String>((ref, tripId) {
  return _firebaseService.watchTrip(tripId);
});

class TripScreen extends ConsumerWidget {
  final String tripId;
  const TripScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDemoMode) {
      final state = ref.watch(mockTripProvider);
      return Scaffold(
        body: ThreePanelLayout(trip: state.trip, tripId: tripId),
      );
    }

    final tripAsync = ref.watch(_firebaseStreamProvider(tripId));
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
