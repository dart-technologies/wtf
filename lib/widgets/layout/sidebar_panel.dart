import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip.dart';
import '../../theme/app_theme.dart';
import '../../screens/trip_screen.dart';
import '../components/component_renderer.dart';

enum SidebarAlignment { left, right }

class SidebarPanel extends ConsumerWidget {
  final String personId;
  final String personName;
  final Color color;
  final Trip trip;
  final String tripId;
  final SidebarAlignment alignment;

  const SidebarPanel({
    super.key,
    required this.personId,
    required this.personName,
    required this.color,
    required this.trip,
    required this.tripId,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeComponent = ref.watch(
      mockTripProvider.select((s) => s.activeComponents[personId]),
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        // Only accept if it's a block ID (doesn't start with person_)
        return !details.data.startsWith('person_');
      },
      onAcceptWithDetails: (details) {
        ref.read(mockTripProvider.notifier).claimBlock(details.data, personId);
      },
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          color: isHovered ? color.withValues(alpha: 0.04) : AppColors.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarHeader(name: personName, color: color, personId: personId),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: activeComponent == null
                      ? _EmptyState(personName: personName, key: const ValueKey('empty'))
                      : SingleChildScrollView(
                          key: ValueKey(activeComponent.component + activeComponent.targetBlock),
                          padding: const EdgeInsets.all(16),
                          child: ComponentRenderer(
                            response: activeComponent,
                            onSubmit: (value) {
                              ref.read(mockTripProvider.notifier).submitDecision(personId, value);
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final String name;
  final Color color;
  final String personId;
  const _SidebarHeader({required this.name, required this.color, required this.personId});

  @override
  Widget build(BuildContext context) {
    final avatar = PersonAvatar(personId: personId, name: name, radius: 14);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Draggable<String>(
            data: personId,
            feedback: Material(
              color: Colors.transparent,
              child: PersonAvatar(personId: personId, name: name, radius: 18),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: avatar),
            child: Tooltip(
              message: 'Drag onto a block to claim it',
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: avatar,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String personName;
  const _EmptyState({super.key, required this.personName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_indicator, size: 36, color: AppColors.unclaimed),
            const SizedBox(height: 12),
            Text(
              'Drag your avatar onto a block to start planning',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
