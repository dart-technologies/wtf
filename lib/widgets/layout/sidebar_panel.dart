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
    if (mounted) setState(() {});
  }

  void _onFlowSubmit(Map<String, dynamic> result) {
    _runner?.submit(result);
  }

  void _resetFlow() {
    _runner?.removeListener(_onFlowChange);
    _runner?.dispose();
    setState(() => _runner = null);
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
        FlowState.idle => _buildBlockPicker(), // shouldn't reach
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
    return _buildBlockPicker();
  }

  // ── Block picker ──────────────────────────────────────────────────────────

  Widget _buildBlockPicker() {
    final blocks = widget.trip.orderedBlocks;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Pick a block to decide:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        for (final block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BlockButton(
              block: block,
              personId: widget.personId,
              color: widget.color,
              onTap: () => _startFlow(block),
            ),
          ),
      ],
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

class _BlockButton extends StatelessWidget {
  final ItineraryBlock block;
  final String personId;
  final Color color;
  final VoidCallback onTap;

  const _BlockButton({
    required this.block,
    required this.personId,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = block.owner == personId;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? color.withValues(alpha: 0.1) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isMine
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              block.category == BlockCategory.meal
                  ? Icons.restaurant
                  : Icons.directions_walk,
              size: 16,
              color: color.withValues(alpha: isMine ? 1.0 : 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.label,
                    style: TextStyle(
                      fontWeight: isMine ? FontWeight.w600 : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    block.timeRange,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            if (block.status == BlockStatus.decided)
              const Icon(Icons.check_circle, size: 16, color: AppColors.decided),
          ],
        ),
      ),
    );
  }
}
