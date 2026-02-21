import 'package:flutter/material.dart';
import '../../../models/block.dart';
import '../../../theme/app_theme.dart';

/// Renders a single block in the shared center itinerary.
///
/// Displays: time range, label, status color, owner chip.
/// Supports unclaimed (tap to claim), in-progress, and decided states.
///
/// TODO(mike): add drag-to-claim, decided state with result details.
class ItineraryBlockWidget extends StatelessWidget {
  final ItineraryBlock block;
  final String tripId;
  final void Function(String personId) onClaim;

  const ItineraryBlockWidget({
    super.key,
    required this.block,
    required this.tripId,
    required this.onClaim,
  });

  Color get _statusColor {
    return switch (block.status) {
      BlockStatus.unclaimed => AppColors.unclaimed,
      BlockStatus.claimed || BlockStatus.inProgress =>
        AppColors.forPersonId(block.owner ?? ''),
      BlockStatus.decided => AppColors.decided,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withOpacity(0.5)),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          // Status bar
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        block.timeRange,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (block.owner != null)
                        _OwnerChip(owner: block.owner!),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    block.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (block.status == BlockStatus.decided &&
                      block.result?['name'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      block.result!['name'] as String,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.decided),
                    ),
                  ],
                  if (block.status == BlockStatus.unclaimed)
                    _ClaimButtons(onClaim: onClaim),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerChip extends StatelessWidget {
  final String owner;
  const _OwnerChip({required this.owner});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forPersonId(owner);
    final label = owner == 'ai' ? 'AI' : owner.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ClaimButtons extends StatelessWidget {
  final void Function(String) onClaim;
  const _ClaimButtons({required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => onClaim('person_a'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.personA,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Claim (A)', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => onClaim('person_b'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.personB,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Claim (B)', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => onClaim('ai'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ai,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.auto_awesome, size: 14),
          label: const Text('AI', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
