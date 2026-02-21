import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../theme/app_theme.dart';
import 'itinerary_panel.dart';
import 'sidebar_panel.dart';

class ThreePanelLayout extends StatelessWidget {
  final Trip trip;
  final String tripId;

  const ThreePanelLayout({
    super.key,
    required this.trip,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final personA = trip.people['person_a'];
    final personB = trip.people['person_b'];

    return Column(
      children: [
        _Header(trip: trip),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left sidebar — Person A
              SidebarPanel(
                personId: 'person_a',
                personName: personA?.name ?? 'Person A',
                color: AppColors.personA,
                trip: trip,
                tripId: tripId,
                alignment: SidebarAlignment.left,
              ),
              // Center — Shared itinerary
              Expanded(
                flex: 3,
                child: ItineraryPanel(trip: trip, tripId: tripId),
              ),
              // Right sidebar — Person B
              SidebarPanel(
                personId: 'person_b',
                personName: personB?.name ?? 'Person B',
                color: AppColors.personB,
                trip: trip,
                tripId: tripId,
                alignment: SidebarAlignment.right,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Trip trip;
  const _Header({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(Icons.route, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Where To Flock',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              trip.destination,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Spacer(),
          // Person avatars
          for (final person in trip.people.values) ...[
            _PersonChip(name: person.name, personId: person.id),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  final String name;
  final String personId;
  const _PersonChip({required this.name, required this.personId});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forPersonId(personId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 10,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 4),
        Text(name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
