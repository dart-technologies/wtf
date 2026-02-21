import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/block.dart';
import '../../models/trip.dart';
import '../../theme/app_theme.dart';
import '../../screens/trip_screen.dart';
import '../components/output/itinerary_block_widget.dart';
import '../components/output/conflict_card_widget.dart';
import '../components/output/transition_block_widget.dart';
import '../components/output/final_plan_card.dart';

class ItineraryPanel extends ConsumerStatefulWidget {
  final Trip trip;
  final String tripId;
  const ItineraryPanel({super.key, required this.trip, required this.tripId});

  @override
  ConsumerState<ItineraryPanel> createState() => _ItineraryPanelState();
}

class _ItineraryPanelState extends ConsumerState<ItineraryPanel> {
  bool _showFinalPlan = false;
  bool _autoTransitioned = false;

  @override
  Widget build(BuildContext context) {
    // Side-effect: auto-crossfade when demo completes; reset on demo restart.
    ref.listen(
      mockTripProvider.select((s) => s.phase),
      (previous, next) {
        if (next == DemoPhase.done && !_autoTransitioned) {
          _autoTransitioned = true;
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _showFinalPlan = true);
          });
        }
        if (next == DemoPhase.idle) {
          setState(() {
            _showFinalPlan = false;
            _autoTransitioned = false;
          });
        }
      },
    );

    final blocks = widget.trip.orderedBlocks;
    final isFinalized = blocks.every((b) => b.status == BlockStatus.decided);

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      key: ValueKey(_showFinalPlan),
                      child: Text(
                        _showFinalPlan
                            ? 'Your Brooklyn Day 🗺'
                            : isFinalized
                                ? "Today's Plan · Decided ✓"
                                : "Today's Plan",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
                // Toggle only visible once finalized
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: isFinalized
                      ? _ViewToggle(
                          key: const ValueKey('toggle'),
                          showFinalPlan: _showFinalPlan,
                          onToggle: (v) => setState(() => _showFinalPlan = v),
                        )
                      : const SizedBox.shrink(key: ValueKey('notoggle')),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              widget.trip.destination,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),

          // ── Crossfading content ────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: _showFinalPlan
                  ? const _FinalPlanView(key: ValueKey('final'))
                  : _CoordView(
                      key: const ValueKey('coord'),
                      trip: widget.trip,
                      tripId: widget.tripId,
                      blocks: blocks,
                      onClaim: (blockId, personId) =>
                          ref.read(mockTripProvider.notifier).claimBlock(blockId, personId),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented view toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final bool showFinalPlan;
  final void Function(bool) onToggle;
  const _ViewToggle({super.key, required this.showFinalPlan, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleTab(
            label: 'Coordination',
            icon: Icons.grid_view_rounded,
            selected: !showFinalPlan,
            onTap: () => onToggle(false),
          ),
          _ToggleTab(
            label: 'Your Day',
            icon: Icons.auto_awesome_rounded,
            selected: showFinalPlan,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.personA.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: AppColors.personA.withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: selected ? AppColors.personA : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.personA : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coordination view — itinerary blocks + transitions
// ─────────────────────────────────────────────────────────────────────────────

class _CoordView extends StatelessWidget {
  final Trip trip;
  final String tripId;
  final List<ItineraryBlock> blocks;
  final void Function(String blockId, String personId) onClaim;

  const _CoordView({
    super.key,
    required this.trip,
    required this.tripId,
    required this.blocks,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < blocks.length; i++) ...[
            ItineraryBlockWidget(
              block: blocks[i],
              tripId: tripId,
              onClaim: (personId) => onClaim(blocks[i].id, personId),
            ),
            if (i < blocks.length - 1)
              TransitionBlockWidget(
                  props: _getTransitionProps(blocks[i], blocks[i + 1])),
          ],
          if (trip.conflicts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Conflicts to resolve',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.orange.shade700)),
            const SizedBox(height: 8),
            for (final conflict in trip.conflicts)
              ConflictCardWidget(conflict: conflict, onResolve: (_) {}),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getTransitionProps(ItineraryBlock a, ItineraryBlock b) {
    if (a.id == 'breakfast' && b.id == 'morning_activity') {
      return {'from': 'Williamsburg', 'to': 'DUMBO', 'duration': '18m', 'method': 'subway'};
    }
    if (a.id == 'morning_activity' && b.id == 'lunch') {
      return {'from': 'DUMBO', 'to': 'Carroll Gardens', 'duration': '12m', 'method': 'walk'};
    }
    if (a.id == 'lunch' && b.id == 'afternoon_activity') {
      return {'from': 'Carroll Gardens', 'to': 'Crown Heights', 'duration': '20m', 'method': 'subway'};
    }
    if (a.id == 'afternoon_activity' && b.id == 'dinner') {
      return {'from': 'Crown Heights', 'to': 'Williamsburg', 'duration': '22m', 'method': 'subway'};
    }
    if (a.id == 'dinner' && b.id == 'evening_activity') {
      return {'from': "Francie's", 'to': 'Nitehawk Cinema', 'duration': '5m', 'method': 'walk'};
    }
    return {'from': 'Here', 'to': 'There', 'duration': '15m', 'method': 'walk'};
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Final plan view — styled Brooklyn day FinalPlanCards
// ─────────────────────────────────────────────────────────────────────────────

class _FinalPlanView extends StatelessWidget {
  const _FinalPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          FinalPlanCard(props: {
            'title': 'Win Son',
            'time': '9:00am',
            'description':
                'Taiwanese-Vietnamese breakfast in Williamsburg. Cult classic — bing sandwiches, scallion pancakes, Vietnamese coffee.',
            'highlights': ['Pork chop bing', 'Fried egg on scallion pancake', 'Vietnamese iced coffee'],
            'vibe_color': '#E53935',
            'image_url': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=600',
          }),
          FinalPlanCard(props: {
            'title': 'Brooklyn Bridge Park',
            'time': '10:15am',
            'description':
                'Waterfront park beneath the bridges with sweeping skyline views from DUMBO. Best morning walk in the city.',
            'highlights': ['Pier 1 lawn', "Jane's Carousel by the water", 'View of both bridges from Main St'],
            'vibe_color': '#43A047',
            'image_url': 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=600',
          }),
          FinalPlanCard(props: {
            'title': "Lucali's",
            'time': '12:30pm',
            'description':
                'Carroll Gardens wood-fired pizza in a candlelit former bodega. BYOB. Cash only. Legendary.',
            'highlights': [
              "Plain pie or calzone — that's the whole menu",
              'Arrive early, line forms fast',
              'Bring a bottle of red'
            ],
            'vibe_color': '#FB8C00',
            'image_url': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600',
          }),
          FinalPlanCard(props: {
            'title': 'Brooklyn Museum',
            'time': '2:30pm',
            'description':
                "World-class art museum in Crown Heights. Egyptian wing, feminist art collection, and a rooftop you'll want to stay on.",
            'highlights': [
              'Egyptian Art — mummies, reliefs, sarcophagi',
              'Elizabeth A. Sackler Center for Feminist Art',
              'First Saturdays — free and packed'
            ],
            'vibe_color': '#1E88E5',
            'image_url': 'https://images.unsplash.com/photo-1565060169194-19fabf63012c?w=600',
          }),
          FinalPlanCard(props: {
            'title': "Francie's",
            'time': '7:00pm',
            'description':
                "Williamsburg tasting menu in a candlelit rowhouse. The most romantic restaurant nobody's told you about yet.",
            'highlights': [
              'Beef tartare with cured egg yolk',
              'Rotating seasonal tasting menu',
              'Book 2+ weeks ahead — worth it'
            ],
            'vibe_color': '#8E24AA',
            'image_url': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600',
          }),
          FinalPlanCard(props: {
            'title': 'Nitehawk Cinema',
            'time': '9:00pm',
            'description':
                "Williamsburg's dine-in cinema. Order cocktails and small plates during the film — the only theater in NYC where you're encouraged to eat loudly.",
            'highlights': [
              'Drafthouse-style food service during the movie',
              'Rotating indie and classic film program',
              'Bar opens an hour before showtime'
            ],
            'vibe_color': '#37474F',
            'image_url': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600',
          }),
        ],
      ),
    );
  }
}

/// Status indicator dot (used externally if needed).
class StatusDot extends StatelessWidget {
  final BlockStatus status;
  final String? owner;
  const StatusDot({super.key, required this.status, this.owner});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BlockStatus.unclaimed => AppColors.unclaimed,
      BlockStatus.claimed || BlockStatus.inProgress => AppColors.forPersonId(owner ?? ''),
      BlockStatus.decided => AppColors.decided,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
