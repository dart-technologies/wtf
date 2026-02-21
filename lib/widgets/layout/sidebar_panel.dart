import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/block.dart';
import '../../models/trip.dart';
import '../../services/decision_flow_service.dart';
import '../../theme/app_theme.dart';
import '../components/component_renderer.dart';

enum SidebarAlignment { left, right }

class SidebarPanel extends StatefulWidget {
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
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {
  DecisionFlowRunner? _runner;

  void _startFlow(ItineraryBlock block) {
    _runner?.removeListener(_onFlowChange);
    _runner?.dispose();
    final apiKey = dotenv.maybeGet('CLAUDE_API_KEY');
    final hasKey = apiKey != null && apiKey.isNotEmpty;
    debugPrint('[WTF] API key detected: $hasKey'
        '${hasKey ? " (${apiKey!.substring(0, 10)}...)" : ""}');
    debugPrint('[WTF] Starting ${hasKey ? "LIVE" : "MOCK"} flow for ${block.label}');
    _runner = DecisionFlowRunner(
      personId: widget.personId,
      block: block,
      useMock: !hasKey,
      apiKey: apiKey,
    );
    _runner!.addListener(_onFlowChange);
    _runner!.start();
  }

  void _onFlowChange() {
    if (mounted) setState(() {});
  }

  void _onSubmit(Map<String, dynamic> result) {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(name: widget.personName, color: widget.color),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final runner = _runner;
    if (runner == null) return _buildBlockPicker();

    return switch (runner.state) {
      FlowState.idle => _buildBlockPicker(),
      FlowState.loading => _buildLoading(),
      FlowState.active => _buildActiveFlow(runner),
      FlowState.done => _buildDone(runner),
      FlowState.error => _buildError(runner),
    };
  }

  // ---------- Block picker ----------

  Widget _buildBlockPicker() {
    final blocks = widget.trip.orderedBlocks;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Pick a block to decide:',
          style: Theme.of(context).textTheme.titleSmall,
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

  // ---------- Loading ----------

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

  // ---------- Active flow ----------

  Widget _buildActiveFlow(DecisionFlowRunner runner) {
    final component = runner.currentComponent;
    if (component == null) return _buildLoading();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Flow header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: widget.color.withOpacity(0.08),
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
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _resetFlow,
                  tooltip: 'Cancel',
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Component
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ComponentRenderer(
              response: component,
              onSubmit: _onSubmit,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Done ----------

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
              style: Theme.of(context).textTheme.titleMedium,
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

  // ---------- Error ----------

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

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

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

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(color: isMine ? color : AppColors.divider),
        backgroundColor: isMine ? color.withOpacity(0.06) : null,
      ),
      child: Row(
        children: [
          Icon(
            block.category == BlockCategory.meal
                ? Icons.restaurant
                : Icons.directions_walk,
            size: 16,
            color: color.withOpacity(isMine ? 1.0 : 0.4),
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
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
