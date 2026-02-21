import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// domain_claim — drag blocks between people and AI.
///
/// Props: { blocks: [{id, label, time}], columns: [person_ids + "ai"] }
///
/// TODO(mike): implement actual drag-and-drop (DragTarget/Draggable).
class DomainClaim extends StatefulWidget {
  final Map<String, dynamic> props;
  final void Function(Map<String, dynamic>) onSubmit;

  const DomainClaim({super.key, required this.props, required this.onSubmit});

  @override
  State<DomainClaim> createState() => _DomainClaimState();
}

class _DomainClaimState extends State<DomainClaim> {
  late Map<String, String> _blockOwners; // blockId → columnId

  List<dynamic> get _blocks => widget.props['blocks'] as List? ?? [];
  List<dynamic> get _columns => widget.props['columns'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    // Default: all blocks unclaimed
    _blockOwners = {
      for (final b in _blocks) (b as Map<String, dynamic>)['id'] as String: 'unclaimed'
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Claim your blocks', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final b in _blocks) _BlockRow(
          block: b as Map<String, dynamic>,
          columns: List<String>.from(_columns),
          owner: _blockOwners[(b)['id'] as String] ?? 'unclaimed',
          onAssign: (columnId) => setState(
            () => _blockOwners[(b)['id'] as String] = columnId,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => widget.onSubmit({'assignments': _blockOwners}),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _BlockRow extends StatelessWidget {
  final Map<String, dynamic> block;
  final List<String> columns;
  final String owner;
  final void Function(String) onAssign;

  const _BlockRow({
    required this.block,
    required this.columns,
    required this.owner,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block['label'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  block['time'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: columns.contains(owner) ? owner : null,
            hint: const Text('Assign'),
            items: columns
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.forPersonId(c),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(c),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onAssign(v);
            },
          ),
        ],
      ),
    );
  }
}
