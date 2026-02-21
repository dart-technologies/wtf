import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/block.dart';
import '../../models/trip.dart';
import '../../services/decision_flow_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/demo_providers.dart';
import '../components/component_renderer.dart';

enum SidebarAlignment { left, right }

class SidebarPanel extends ConsumerStatefulWidget {
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
  ConsumerState<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends ConsumerState<SidebarPanel> {
  DecisionFlowRunner? _runner;
  bool _submittedResult = false;

  @override
  void initState() {
    super.initState();
  }

  // ── Flow runner management (Abby's decision flow) ─────────────────────────

  void _startFlow(ItineraryBlock block) {
    _runner?.removeListener(_onFlowChange);
    _runner?.dispose();
    final apiKey = dotenv.maybeGet('CLAUDE_API_KEY');
    final hasKey = apiKey != null && apiKey.isNotEmpty;
    debugPrint('[WTF] Starting ${hasKey ? "LIVE" : "MOCK"} flow '
        'for ${block.label} (${widget.personName})');
    _runner = DecisionFlowRunner(
      personId: widget.personId,
      block: block,
      useMock: !hasKey,
      apiKey: apiKey,
    );
    _runner!.addListener(_onFlowChange);
    _runner!.start();
  }

  void _startFlowForBlockId(String blockId) {
    final block = widget.trip.blocks[blockId];
    if (block != null) _startFlow(block);
  }

  void _onFlowChange() {
    if (!mounted) return;
    setState(() {});

    // Auto-feed completed flow result back to the demo state machine.
    if (_runner?.state == FlowState.done && !_submittedResult) {
      _submittedResult = true;
      final result = _runner!.finalResult ?? {};
      final blockId = _runner!.block.id;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          ref.read(mockTripProvider.notifier).completeDecisionFlow(
                widget.personId, blockId, result);
          _resetFlow();
        }
      });
    }
  }

  void _onFlowSubmit(Map<String, dynamic> result) {
    _runner?.submit(result);
  }

  void _resetFlow() {
    _runner?.removeListener(_onFlowChange);
    _runner?.dispose();
    setState(() {
      _runner = null;
      _submittedResult = false;
    });
  }

  @override
  void dispose() {
    _runner?.removeListener(_onFlowChange);
    _runner?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeComponent = ref.watch(
      mockTripProvider.select((s) => s.activeComponents[widget.personId]),
    );

    // When the state machine sends 'claude_thinking', auto-start the decision
    // flow runner for that block (replaces Mike's placeholder with Abby's GenUI).
    ref.listen(
      mockTripProvider.select((s) => s.activeComponents[widget.personId]),
      (previous, next) {
        if (next != null &&
            next.component == 'claude_thinking' &&
            _runner == null) {
          _startFlowForBlockId(next.targetBlock);
        }
      },
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return !details.data.startsWith('person_');
      },
      onAcceptWithDetails: (details) {
        ref
            .read(mockTripProvider.notifier)
            .claimBlock(details.data, widget.personId);
      },
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          color: isHovered
              ? widget.color.withValues(alpha: 0.04)
              : AppColors.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarHeader(
                name: widget.personName,
                color: widget.color,
                personId: widget.personId,
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(child: _buildBody(activeComponent)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(dynamic activeComponent) {
    final runner = _runner;

    // Priority 1: Local flow runner is active
    if (runner != null && runner.state != FlowState.idle) {
      return switch (runner.state) {
        FlowState.loading => _buildLoading(),
        FlowState.active => _buildActiveFlow(runner),
        FlowState.done => _buildDone(runner),
        FlowState.error => _buildError(runner),
        FlowState.idle => _buildIdleState(), // shouldn't reach
      };
    }

    // Priority 2: State machine has a component for us (e.g., cross-approval)
    if (activeComponent != null && activeComponent.component != 'claude_thinking') {
      return SingleChildScrollView(
        key: ValueKey(activeComponent.component + activeComponent.targetBlock),
        padding: const EdgeInsets.all(16),
        child: ComponentRenderer(
          response: activeComponent,
          onSubmit: (value) {
            ref
                .read(mockTripProvider.notifier)
                .submitDecision(widget.personId, value);
          },
        ),
      );
    }

    // Priority 3: Block picker (idle state)
    return _buildIdleState();
  }

  // ── Idle state ───────────────────────────────────────────────────────────

  Widget _buildIdleState() {
    final phase = ref.watch(mockTripProvider.select((s) => s.phase));
    final flowResults = ref.watch(mockTripProvider.select((s) => s.flowResults));
    final myFlowDone = flowResults.containsKey(widget.personId);

    final String message;
    final IconData icon;

    if (phase == DemoPhase.done) {
      message = 'Your day is planned!';
      icon = Icons.celebration_rounded;
    } else if (phase == DemoPhase.turn1 && myFlowDone) {
      final otherName = widget.personId == 'person_a'
          ? (widget.trip.people['person_b']?.name ?? 'your partner')
          : (widget.trip.people['person_a']?.name ?? 'your partner');
      message = 'Waiting for $otherName to finish...';
      icon = Icons.hourglass_top_rounded;
    } else {
      message = 'Drag a block from the itinerary to start deciding';
      icon = Icons.touch_app_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: widget.color.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: widget.color),
          const SizedBox(height: 12),
          const Text(
            'Thinking...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Active flow ───────────────────────────────────────────────────────────

  Widget _buildActiveFlow(DecisionFlowRunner runner) {
    final component = runner.currentComponent;
    if (component == null) return _buildLoading();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: widget.color.withValues(alpha: 0.12),
          child: Row(
            children: [
              Icon(
                runner.block.category == BlockCategory.meal
                    ? Icons.restaurant
                    : Icons.directions_walk,
                size: 16,
                color: widget.color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${runner.block.label} \u00b7 Step ${runner.stepIndex + 1}'
                  '${runner.useMock ? ' of ${runner.totalMockSteps}' : ''}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  onPressed: _resetFlow,
                  tooltip: 'Cancel',
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ComponentRenderer(
              response: component,
              onSubmit: _onFlowSubmit,
            ),
          ),
        ),
      ],
    );
  }

  // ── Done ──────────────────────────────────────────────────────────────────

  Widget _buildDone(DecisionFlowRunner runner) {
    final result = runner.finalResult ?? {};
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: AppColors.decided),
            const SizedBox(height: 12),
            Text(
              result['venue'] as String? ?? 'Decided!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.decided,
                  ),
              textAlign: TextAlign.center,
            ),
            if (result['neighborhood'] != null &&
                (result['neighborhood'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result['neighborhood'] as String,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (result['one_liner'] != null) ...[
              const SizedBox(height: 8),
              Text(
                result['one_liner'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _resetFlow,
              child: const Text('Decide another block'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(DecisionFlowRunner runner) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              runner.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _resetFlow,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

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

