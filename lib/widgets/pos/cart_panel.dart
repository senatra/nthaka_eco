import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/models/pos_cart_line.dart';
import 'package:nthaka_eco/models/pos_session_state.dart';

class CartPanel extends StatelessWidget {
  final PosSessionState session;
  final VoidCallback onCharge;
  final VoidCallback onVoid;
  final VoidCallback onHold;
  final VoidCallback onDiscount;
  final VoidCallback onOptionalDetails;
  final void Function(PosCartLine line, int delta) onQtyChanged;
  final void Function(PosCartLine line) onLongPressLine;

  const CartPanel({
    super.key,
    required this.session,
    required this.onCharge,
    required this.onVoid,
    required this.onHold,
    required this.onDiscount,
    required this.onOptionalDetails,
    required this.onQtyChanged,
    required this.onLongPressLine,
  });

  @override
  Widget build(BuildContext context) {
    final lines = session.lines;

    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing12,
              AppTheme.spacing16,
              AppTheme.spacing4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ticket (${session.itemCount})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: onOptionalDetails,
                  child: const Text('Customer / notes'),
                ),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Text(
                      'Tap products to build a ticket',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                    ),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacing4),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return InkWell(
                        onLongPress: () => onLongPressLine(line),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(line.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    Text(
                                      '@ ${line.unitPrice.toStringAsFixed(2)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                onPressed: () => onQtyChanged(line, -1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${line.quantity}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                onPressed: () => onQtyChanged(line, 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  line.lineTotal.toStringAsFixed(2),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TotalRow(label: 'Subtotal', value: session.subtotal),
                if (session.discountAmount > 0)
                  _TotalRow(
                    label: 'Discount',
                    value: -session.discountAmount,
                  ),
                _TotalRow(
                  label: 'Total',
                  value: session.total,
                  emphasize: true,
                ),
                const SizedBox(height: AppTheme.spacing12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: session.isEmpty ? null : onCharge,
                    child: const Text('Charge / complete sale'),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: session.isEmpty ? null : onHold,
                          child: const Text('Hold'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: onDiscount,
                          child: const Text('Discount'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onPressed: session.isEmpty ? null : onVoid,
                    child: const Text('Void ticket'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}
