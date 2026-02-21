import 'package:flutter/material.dart';
import '../../../models/block.dart';
import '../../../theme/app_theme.dart';

/// Maps person_id to display name.
String _name(String? id) => switch (id) {
      'person_a' => 'Abby',
      'person_b' => 'Mike',
      'ai' => 'AI',
      _ => 'Someone',
    };

/// Renders a single block in the shared center itinerary.
/// Supports drag-to-claim: any [Draggable<String>] carrying a person_id
/// can be dropped onto an unclaimed block to trigger [onClaim].
class ItineraryBlockWidget extends StatefulWidget {
  final ItineraryBlock block;
  final String tripId;
  final void Function(String personId) onClaim;

  const ItineraryBlockWidget({
    super.key,
    required this.block,
    required this.tripId,
    required this.onClaim,
  });

  @override
  State<ItineraryBlockWidget> createState() => _ItineraryBlockWidgetState();
}

class _ItineraryBlockWidgetState extends State<ItineraryBlockWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.block.status == BlockStatus.inProgress) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ItineraryBlockWidget old) {
    super.didUpdateWidget(old);
    if (widget.block.status == BlockStatus.inProgress) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl
        ..stop()
        ..value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor => switch (widget.block.status) {
        BlockStatus.unclaimed => AppColors.unclaimed,
        BlockStatus.claimed || BlockStatus.inProgress =>
          AppColors.forPersonId(widget.block.owner ?? ''),
        BlockStatus.decided => AppColors.decided,
      };

  @override
  Widget build(BuildContext context) {
    final isUnclaimed = widget.block.status == BlockStatus.unclaimed;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => isUnclaimed,
      onAcceptWithDetails: (details) => widget.onClaim(details.data),
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;

        Widget content = AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovered
                  ? AppColors.personA
                  : _statusColor.withValues(alpha: 0.5),
              width: isHovered ? 2.5 : 1,
            ),
            color: isHovered
                ? AppColors.personA.withValues(alpha: 0.08)
                : widget.block.status == BlockStatus.decided
                    ? AppColors.elevated
                    : AppColors.elevated,
            boxShadow: isHovered
                ? [BoxShadow(color: AppColors.personA.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)]
                : widget.block.status == BlockStatus.inProgress
                    ? [BoxShadow(color: _statusColor.withValues(alpha: 0.15), blurRadius: 10, spreadRadius: 1)]
                    : null,
          ),
          child: Row(
            children: [
              // Pulsing status bar
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 4,
                  height: widget.block.status == BlockStatus.decided ? 80 : 72,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 
                      widget.block.status == BlockStatus.inProgress ? _pulse.value : 1.0,
                    ),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.block.timeRange, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              widget.block.label,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: widget.block.status == BlockStatus.decided
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                            if (widget.block.status == BlockStatus.inProgress) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_name(widget.block.owner)} is planning…',
                                    style: TextStyle(fontSize: 11, color: _statusColor),
                                  ),
                                ],
                              ),
                            ],
                            if (widget.block.status == BlockStatus.decided &&
                                widget.block.result?['name'] != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 14, color: AppColors.decided),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.block.result!['name'] as String,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.decided,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: widget.block.owner != null
                                ? _OwnerChip(
                                    key: ValueKey(widget.block.owner),
                                    owner: widget.block.owner!)
                                : isUnclaimed
                                    ? _DropHint(key: const ValueKey('hint'))
                                    : const SizedBox.shrink(),
                          ),
                          if (widget.block.status == BlockStatus.decided)
                            _DecisionBadges(result: widget.block.result ?? {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (widget.block.status != BlockStatus.decided) {
          content = Draggable<String>(
            data: widget.block.id,
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.9,
                child: SizedBox(
                   width: 320,
                   child: IgnorePointer(child: content),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.4, child: content),
            child: content,
          );
        }

        return content;
      },
    );
  }
}

class _OwnerChip extends StatelessWidget {
  final String owner;
  const _OwnerChip({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forPersonId(owner);
    final label = _name(owner);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Subtle hint shown on unclaimed blocks to invite drag.
class _DropHint extends StatelessWidget {
  const _DropHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.drag_indicator, size: 12, color: AppColors.unclaimed),
        const SizedBox(width: 2),
        Text('drag to claim',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.unclaimed, fontSize: 10)),
      ],
    );
  }
}

/// Shows who approved a block in the decided state.
/// The owner chip already shows who decided, so we only display the approver here.
class _DecisionBadges extends StatelessWidget {
  final Map<String, dynamic> result;
  const _DecisionBadges({required this.result});

  @override
  Widget build(BuildContext context) {
    final approvedBy = result['approvedBy'] as String?;
    if (approvedBy == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: _MiniChip(
        label: '${_name(approvedBy)} ✓',
        color: AppColors.decided,
        icon: Icons.check_circle_outline,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _MiniChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
