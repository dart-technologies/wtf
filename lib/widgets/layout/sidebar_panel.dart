import 'package:flutter/material.dart';
import '../../models/component_response.dart';
import '../../models/trip.dart';
import '../../theme/app_theme.dart';
import '../components/component_renderer.dart';

enum SidebarAlignment { left, right }

class SidebarPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // TODO(abby): replace with live ComponentResponse stream from ClaudeService
    final ComponentResponse? activeComponent = null;

    return SizedBox(
      width: 280,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(name: personName, color: color),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: activeComponent == null
                  ? _EmptyState(personName: personName)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ComponentRenderer(
                        response: activeComponent,
                        onSubmit: (value) {
                          // TODO(abby): send to ClaudeService.sendInput
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final String name;
  final Color color;
  const _SidebarHeader({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 12,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String personName;
  const _EmptyState({required this.personName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_outlined, size: 40, color: AppColors.unclaimed),
            const SizedBox(height: 12),
            Text(
              'Claim a block to start planning',
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
