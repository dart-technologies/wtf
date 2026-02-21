import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip.dart';
import '../../theme/app_theme.dart';
import '../../main.dart' show kDemoMode;
import '../../providers/demo_providers.dart';
import 'itinerary_panel.dart';
import 'sidebar_panel.dart';

class ThreePanelLayout extends StatelessWidget {
  final Trip trip;
  final String tripId;

  const ThreePanelLayout({super.key, required this.trip, required this.tripId});

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
              // Left sidebar — Person A (equal flex)
              Expanded(
                child: SidebarPanel(
                  personId: 'person_a',
                  personName: personA?.name ?? 'Person A',
                  color: AppColors.personA,
                  trip: trip,
                  tripId: tripId,
                  alignment: SidebarAlignment.left,
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
              // Center — Shared itinerary (equal flex)
              Expanded(
                child: ItineraryPanel(trip: trip, tripId: tripId),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
              // Right sidebar — Person B (equal flex)
              Expanded(
                child: SidebarPanel(
                  personId: 'person_b',
                  personName: personB?.name ?? 'Person B',
                  color: AppColors.personB,
                  trip: trip,
                  tripId: tripId,
                  alignment: SidebarAlignment.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  final Trip trip;
  const _Header({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(mockTripProvider.select((s) => s.phase));
    final isDone = phase == DemoPhase.done;

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.elevated,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
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
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(trip.destination, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 16),
          if (kDemoMode && phase != DemoPhase.idle)
            OutlinedButton.icon(
              onPressed: () => ref.read(mockTripProvider.notifier).reset(),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                isDone ? 'Reset Demo' : 'Reset',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          const Spacer(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _OnlineDot(),
          const SizedBox(width: 5),
          PersonAvatar(personId: personId, name: name, radius: 10),
          const SizedBox(width: 5),
          Text(name, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _OnlineDot extends StatefulWidget {
  const _OnlineDot();

  @override
  State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) => Opacity(
        opacity: _fade.value,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.5 * _fade.value),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
