import 'package:flutter/material.dart';
import '../../models/block.dart';
import '../../models/trip.dart';
import '../../theme/app_theme.dart';
import '../components/output/itinerary_block_widget.dart';
import '../components/output/conflict_card_widget.dart';

class ItineraryPanel extends StatelessWidget {
  final Trip trip;
  final String tripId;

  const ItineraryPanel({super.key, required this.trip, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final blocks = trip.orderedBlocks;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Today\'s Plan',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            for (final block in blocks) ...[
              ItineraryBlockWidget(
                block: block,
                tripId: tripId,
                onClaim: (personId) {
                  // TODO(mike): call firebase_service.claimBlock
                },
              ),
              const SizedBox(height: 8),
            ],
            // Active conflicts
            if (trip.conflicts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Conflicts to resolve',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              for (final conflict in trip.conflicts)
                ConflictCardWidget(
                  conflict: conflict,
                  onResolve: (option) {
                    // TODO(mike): call firebase_service.resolveConflict
                  },
                ),
            ],
            // Final plan view
            if (trip.finalPlan != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Your Day',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              // TODO(mike): render FinalPlanCard widgets from trip.finalPlan
            ],
          ],
        ),
      ),
    );
  }
}

/// Status indicator dot for a block.
class StatusDot extends StatelessWidget {
  final BlockStatus status;
  final String? owner;

  const StatusDot({super.key, required this.status, this.owner});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BlockStatus.unclaimed => AppColors.unclaimed,
      BlockStatus.claimed || BlockStatus.inProgress =>
        AppColors.forPersonId(owner ?? ''),
      BlockStatus.decided => AppColors.decided,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
