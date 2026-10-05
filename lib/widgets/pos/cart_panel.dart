import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/models/pos_cart_line.dart';
import 'package:nthaka_eco/models/pos_session_state.dart';

class CartPanel extends StatelessWidget {
  final PosSessionState session;
  final bool darkPanel;
  final VoidCallback onCharge;
  final VoidCallback onVoid;
  final VoidCallback onHold;
  final VoidCallback onDiscount;
  final VoidCallback onOptionalDetails;
  final void Function(PosCartLine line, int delta) onQtyChanged;
  final void Function(PosCartLine line) onRemoveLine;
  final void Function(PosCartLine line) onLongPressLine;
  final VoidCallback? onOpenHeld;

  const CartPanel({
    super.key,
    required this.session,
    this.darkPanel = false,
    required this.onCharge,
    required this.onVoid,
    required this.onHold,
    required this.onDiscount,
    required this.onOptionalDetails,
    required this.onQtyChanged,
    required this.onRemoveLine,
    required this.onLongPressLine,
    this.onOpenHeld,
  });

  @override
  Widget build(BuildContext context) {
    final lines = session.lines;
    final theme = Theme.of(context);
    final onPanel = darkPanel ? Colors.white : theme.colorScheme.onSurface;
    final muted = darkPanel
        ? Colors.white.withValues(alpha: 0.65)
        : theme.colorScheme.onSurfaceVariant;
    final panelBg =
        darkPanel ? AppTheme.posPanelDark : theme.colorScheme.surface;
    final lineBg = darkPanel
        ? AppTheme.posPanelDarkElevated
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    return Material(
      color: panelBg,
      elevation: darkPanel ? 0 : 4,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing12,
              AppTheme.spacing8,
              AppTheme.spacing4,
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_outlined, color: muted, size: 22),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Current sale · ${session.itemCount} items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onPanel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onOpenHeld != null)
                  IconButton(
                    tooltip: 'Held tickets',
                    onPressed: onOpenHeld,
                    color: muted,
                    icon: const Icon(Icons.pause_circle_outline),
                  ),
                TextButton.icon(
                  onPressed: onOptionalDetails,
                  icon: Icon(Icons.person_outline, size: 18, color: muted),
                  label: Text(
                    'Customer',
                    style: TextStyle(color: muted),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 40,
                          color: muted.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'Tap products to add to the sale',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing4,
                    ),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacing8),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return Material(
                        color: lineBg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onLongPress: () => onLongPressLine(line),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing12,
                              vertical: AppTheme.spacing8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          color: onPanel,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${AppTheme.formatMoney(line.unitPrice)} each',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _QtyStepper(
                                  quantity: line.quantity,
                                  onDecrement: () => onQtyChanged(line, -1),
                                  onIncrement: () => onQtyChanged(line, 1),
                                  foreground: onPanel,
                                  background: darkPanel
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : theme.colorScheme.surface,
                                ),
                                IconButton(
                                  tooltip: 'Remove ${line.name}',
                                  onPressed: () => onRemoveLine(line),
                                  color: theme.colorScheme.error,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    AppTheme.formatMoney(line.lineTotal),
                                    textAlign: TextAlign.end,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: onPanel,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: darkPanel
                  ? AppTheme.posPanelDarkElevated
                  : theme.colorScheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: darkPanel
                      ? Colors.white.withValues(alpha: 0.08)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TotalRow(
                  label: 'Subtotal',
                  value: session.subtotal,
                  foreground: onPanel,
                  muted: muted,
                ),
                if (session.discountAmount > 0)
                  _TotalRow(
                    label: 'Discount',
                    value: -session.discountAmount,
                    foreground: AppTheme.posAccent,
                    muted: muted,
                  ),
                if (session.taxAmount > 0)
                  _TotalRow(
                    label: 'Tax (${session.taxRate.toStringAsFixed(1)}%)',
                    value: session.taxAmount,
                    foreground: onPanel,
                    muted: muted,
                  ),
                const SizedBox(height: AppTheme.spacing4),
                _TotalRow(
                  label: 'Total due',
                  value: session.total,
                  emphasize: true,
                  foreground: onPanel,
                  muted: muted,
                ),
                const SizedBox(height: AppTheme.spacing16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.posAccent,
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor: (darkPanel
                              ? Colors.white
                              : theme.colorScheme.onSurface)
                          .withValues(alpha: 0.12),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: session.isEmpty ? null : onCharge,
                    child: Text(
                      session.isEmpty
                          ? 'Add items to charge'
                          : 'Charge ${AppTheme.formatMoney(session.total)}',
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.pause_outlined,
                        label: 'Hold',
                        enabled: !session.isEmpty,
                        onTap: onHold,
                        foreground: onPanel,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.percent,
                        label: 'Discount',
                        enabled: true,
                        onTap: onDiscount,
                        foreground: onPanel,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.delete_outline,
                        label: 'Void',
                        enabled: !session.isEmpty,
                        onTap: onVoid,
                        foreground: theme.colorScheme.error,
                        destructive: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color foreground;
  final Color background;

  const _QtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, onPressed: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepButton(icon: Icons.add, onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color foreground;
  final bool destructive;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.foreground,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? foreground : foreground.withValues(alpha: 0.35);

    return Material(
      color: destructive
          ? foreground.withValues(alpha: 0.08)
          : foreground.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;
  final Color foreground;
  final Color muted;

  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    required this.foreground,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(color: muted);
    final valueStyle = emphasize
        ? style
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(AppTheme.formatMoney(value), style: valueStyle),
        ],
      ),
    );
  }
}
