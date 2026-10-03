import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/app/app_preferences.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/item.dart';
import 'package:nthaka_eco/models/pos_cart_line.dart';
import 'package:nthaka_eco/models/pos_session_state.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/screens/sales/sale_detail_screen.dart';
import 'package:nthaka_eco/screens/sales/barcode_scanner_screen.dart';
import 'package:nthaka_eco/widgets/pos/cart_panel.dart';
import 'package:nthaka_eco/widgets/pos/product_grid.dart';

typedef PaymentResult = ({String method, double? amountPaid, double change});
typedef TicketDetails = ({String? customer, String? notes});

final _moneyInputFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, this.embedded = false});

  /// When true, omits [Scaffold] / app bar (used inside [SalesScreen] tabs).
  final bool embedded;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  PosSessionState _session = const PosSessionState();
  List<Item> _catalog = [];
  List<String> _categories = const ['All'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final draft = await DatabaseHelper.instance.loadActivePosDraft();
    final categories = await DatabaseHelper.instance.getItemCategories();
    if (!mounted) {
      return;
    }
    setState(() {
      _session = draft.isEmpty
          ? draft.copyWith(taxRate: AppPreferences.taxRate.value)
          : draft;
      _categories = ['All', ...categories.where((c) => c != 'All')];
    });
    await _loadCatalog();
  }

  void _onSearchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _loadCatalog);
  }

  Future<void> _loadCatalog() async {
    final items = await DatabaseHelper.instance.searchCatalogItems(
      query: _searchController.text,
      category: _selectedCategory,
    );
    if (!mounted) {
      return;
    }
    setState(() => _catalog = items);
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return;
    _searchController.text = barcode;
    await _loadCatalog();
  }

  void _persistDraft() {
    unawaited(DatabaseHelper.instance.saveActivePosDraft(_session));
  }

  void _setSession(PosSessionState session) {
    setState(() => _session = session);
    _persistDraft();
  }

  List<PosCartLine> _mergeLine(PosCartLine incoming) {
    final map = {for (final line in _session.lines) line.cartKey: line};
    if (map.containsKey(incoming.cartKey)) {
      map[incoming.cartKey]!.quantity += incoming.quantity;
    } else {
      map[incoming.cartKey] = incoming;
    }
    return map.values.toList();
  }

  Future<void> _addProduct(Item item, {int quantity = 1}) async {
    var price = item.unitPrice;
    if (price <= 0) {
      final entered = await _promptUnitPrice(item);
      if (entered == null || entered <= 0 || !mounted) {
        return;
      }
      price = entered;
    }

    _setSession(
      _session.copyWith(
        lines: _mergeLine(
          PosCartLine(
            catalogItemId: item.itemId,
            name: item.itemName,
            unitPrice: price,
            isTaxable: item.isTaxable,
            quantity: quantity,
          ),
        ),
      ),
    );
  }

  Future<double?> _promptUnitPrice(Item item) {
    return showDialog<double>(
      context: context,
      builder: (_) => _UnitPriceDialog(itemName: item.itemName),
    );
  }

  void _changeQty(PosCartLine line, int delta) {
    final updated = _session.lines
        .map((entry) {
          if (entry.cartKey != line.cartKey) {
            return entry;
          }
          final qty = entry.quantity + delta;
          return entry.copyWith(quantity: qty);
        })
        .where((entry) => entry.quantity > 0)
        .toList();

    _setSession(_session.copyWith(lines: updated));
  }

  Future<void> _removeLine(PosCartLine line) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text(
          '${line.name} will be removed from this ticket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: AppTheme.destructiveButtonStyle,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _setSession(
      _session.copyWith(
        lines: _session.lines
            .where((entry) => entry.cartKey != line.cartKey)
            .toList(),
      ),
    );
  }

  Future<void> _voidTicket() async {
    if (_session.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this ticket?'),
        content: const Text(
          'All items and ticket details currently in the register will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep ticket'),
          ),
          FilledButton(
            style: AppTheme.destructiveButtonStyle,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear ticket'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _setSession(PosSessionState(taxRate: AppPreferences.taxRate.value));
  }

  Future<void> _holdTicket() async {
    if (_session.isEmpty) {
      return;
    }
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _HoldTicketDialog(
        initialLabel: 'Ticket ${_session.itemCount} items',
      ),
    );
    if (label == null || label.isEmpty || !mounted) {
      return;
    }

    await DatabaseHelper.instance.parkSale(label, _session);
    if (!mounted) return;
    _setSession(PosSessionState(taxRate: AppPreferences.taxRate.value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Held: $label')),
    );
  }

  Future<void> _applyDiscount() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _DiscountDialog(initial: _session.discountAmount),
    );
    if (amount == null || !mounted) {
      return;
    }
    _setSession(_session.copyWith(discountAmount: amount < 0 ? 0 : amount));
  }

  Future<void> _optionalDetails() async {
    final details = await showModalBottomSheet<TicketDetails>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetailsSheet(
        customer: _session.customerName ?? '',
        notes: _session.notes ?? '',
      ),
    );
    if (details == null || !mounted) return;

    _setSession(
      PosSessionState(
        lines: _session.lines,
        discountAmount: _session.discountAmount,
        taxRate: _session.taxRate,
        customerName: details.customer,
        notes: details.notes,
      ),
    );
  }

  Future<void> _completeSale() async {
    if (_session.isEmpty) {
      return;
    }

    final payment = await _collectPayment();
    if (payment == null || !mounted) return;

    final saleItems = _session.lines
        .map(
          (line) => SaleItem(
            id: 0,
            saleId: 0,
            catalogItemId: line.catalogItemId,
            itemName: line.name,
            quantity: line.quantity,
            price: line.unitPrice,
          ),
        )
        .toList();

    final sale = await DatabaseHelper.instance.createSale(
      Sale(
        id: 0,
        date: DateTime.now(),
        totalAmount: _session.total,
        customerName: _session.customerName,
        notes: _session.notes,
        discountAmount: _session.discountAmount,
        taxRate: _session.taxRate,
        taxAmount: _session.taxAmount,
        paymentMethod: payment.method,
        amountPaid: payment.amountPaid,
        changeAmount: payment.change,
        items: saleItems,
      ),
    );

    await DatabaseHelper.instance.clearActivePosDraft();
    if (!mounted) {
      return;
    }

    setState(
      () => _session = PosSessionState(taxRate: AppPreferences.taxRate.value),
    );
    if (AppPreferences.saleFeedback.value) {
      SystemSound.play(SystemSoundType.click);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Sale #${sale.id} complete · ${sale.totalAmount.toStringAsFixed(2)}'),
        action: SnackBarAction(
          label: 'Receipt',
          onPressed: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleDetailScreen(saleId: sale.id),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<PaymentResult?> _collectPayment() {
    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PaymentSheet(
        total: _session.total,
        initialMethod: AppPreferences.defaultPaymentMethod.value,
      ),
    );
  }

  Future<void> _openParkedSales() async {
    final parked = await DatabaseHelper.instance.listParkedSales();
    if (!mounted) {
      return;
    }
    if (parked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No held tickets')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ParkedSale>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        children: parked
            .map(
              (ticket) => ListTile(
                title: Text(ticket.label),
                subtitle: Text(
                  '${ticket.session.itemCount} items · ${ticket.session.total.toStringAsFixed(2)}',
                ),
                onTap: () => Navigator.pop(context, ticket),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    _setSession(selected.session);
    await DatabaseHelper.instance.deleteParkedSale(selected.id);
  }

  Widget _buildCatalogPane({required bool wide}) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing12,
              AppTheme.spacing16,
              AppTheme.spacing8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search or scan products',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _loadCatalog();
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                IconButton.filledTonal(
                  tooltip: 'Scan barcode',
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
                if (!widget.embedded) ...[
                  const SizedBox(width: AppTheme.spacing8),
                  IconButton.filledTonal(
                    tooltip: 'Held tickets',
                    onPressed: _openParkedSales,
                    icon: const Icon(Icons.pause_circle_outline),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTheme.spacing8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                    _loadCatalog();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Expanded(
            child: ProductGrid(
              products: _catalog,
              onTap: (item) => _addProduct(item),
              onLongPress: (item) => _addProduct(item, quantity: 5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPanel({
    required bool darkPanel,
    VoidCallback? onCharge,
  }) =>
      CartPanel(
        session: _session,
        darkPanel: darkPanel,
        onCharge: onCharge ?? _completeSale,
        onVoid: _voidTicket,
        onHold: _holdTicket,
        onDiscount: _applyDiscount,
        onOptionalDetails: _optionalDetails,
        onQtyChanged: _changeQty,
        onRemoveLine: _removeLine,
        onLongPressLine: (line) => _changeQty(line, 4),
        onOpenHeld: widget.embedded ? _openParkedSales : null,
      );

  /// Opens the cart sheet. If the user taps Charge, the sheet closes with
  /// `true` and the payment flow starts only after it has fully closed, so
  /// two modal routes never overlap.
  Future<void> _openCartSheet() async {
    final charge = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.84,
          child: _buildCartPanel(
            darkPanel: false,
            onCharge: () => Navigator.of(sheetContext).pop(true),
          ),
        ),
      ),
    );
    if (charge == true && mounted) {
      await _completeSale();
    }
  }

  Widget _buildRegisterBody(bool wide) {
    final cart = _buildCartPanel(darkPanel: wide);

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildCatalogPane(wide: wide)),
          VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(flex: 2, child: cart),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: _buildCatalogPane(wide: wide)),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing8,
              AppTheme.spacing16,
              AppTheme.spacing12,
            ),
            child: FilledButton.icon(
              onPressed: _openCartSheet,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                _session.isEmpty
                    ? 'View cart'
                    : 'View cart · ${_session.itemCount} items · ${AppTheme.formatMoney(_session.total)}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final body = _buildRegisterBody(wide);

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        actions: [
          IconButton(
            tooltip: 'Held tickets',
            onPressed: _openParkedSales,
            icon: const Icon(Icons.pause_circle_outline),
          ),
        ],
      ),
      body: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs and sheets. Each owns (and disposes) its own controllers, so they
// are only disposed once the route has been fully removed from the tree.
// ---------------------------------------------------------------------------

class _UnitPriceDialog extends StatefulWidget {
  const _UnitPriceDialog({required this.itemName});
  final String itemName;

  @override
  State<_UnitPriceDialog> createState() => _UnitPriceDialogState();
}

class _UnitPriceDialogState extends State<_UnitPriceDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('Price · ${widget.itemName}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_moneyInputFormatter],
        decoration: const InputDecoration(labelText: 'Unit price'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, double.tryParse(_controller.text.trim())),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _HoldTicketDialog extends StatefulWidget {
  const _HoldTicketDialog({required this.initialLabel});
  final String initialLabel;

  @override
  State<_HoldTicketDialog> createState() => _HoldTicketDialogState();
}

class _HoldTicketDialogState extends State<_HoldTicketDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialLabel);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Hold ticket'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Label'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Hold'),
        ),
      ],
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({required this.initial});
  final double initial;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial > 0 ? widget.initial.toStringAsFixed(2) : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Ticket discount'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_moneyInputFormatter],
        decoration: const InputDecoration(labelText: 'Amount off'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0.0),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, double.tryParse(_controller.text.trim())),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet({required this.customer, required this.notes});
  final String customer;
  final String notes;

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  late final TextEditingController _customerController =
      TextEditingController(text: widget.customer);
  late final TextEditingController _notesController =
      TextEditingController(text: widget.notes);

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing16,
        top: AppTheme.spacing8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'Customer (optional)',
              helperText: 'Add a name to make this ticket easier to find.',
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              helperText: 'Add any helpful information for this sale.',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppTheme.spacing16),
          FilledButton(
            onPressed: () {
              final customer = _customerController.text.trim();
              final notes = _notesController.text.trim();
              Navigator.pop<TicketDetails>(context, (
                customer: customer.isEmpty ? null : customer,
                notes: notes.isEmpty ? null : notes,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.total, required this.initialMethod});
  final double total;
  final String initialMethod;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final TextEditingController _amountController =
      TextEditingController(text: widget.total.toStringAsFixed(2));
  late String _method = widget.initialMethod;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paidPreview = double.tryParse(_amountController.text) ?? 0;
    final change =
        (paidPreview - widget.total).clamp(0, double.infinity).toDouble();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing8,
        AppTheme.spacing16,
        MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Take payment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacing4),
          Text('Total due: ${AppTheme.formatMoney(widget.total)}'),
          const SizedBox(height: AppTheme.spacing16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Cash', label: Text('Cash')),
              ButtonSegment(value: 'Mobile money', label: Text('Mobile money')),
              ButtonSegment(value: 'Card', label: Text('Card')),
            ],
            selected: {_method},
            onSelectionChanged: (value) =>
                setState(() => _method = value.first),
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (_method == 'Cash') ...[
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_moneyInputFormatter],
              decoration: const InputDecoration(
                labelText: 'Amount paid',
                helperText: 'Enter cash received from the customer.',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Change: ${AppTheme.formatMoney(change)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: AppTheme.spacing16),
          FilledButton(
            onPressed: () {
              final paid = _method == 'Cash'
                  ? double.tryParse(_amountController.text.trim())
                  : widget.total;
              if (paid == null || paid < widget.total) return;
              Navigator.pop<PaymentResult>(context, (
                method: _method,
                amountPaid: paid,
                change: paid - widget.total,
              ));
            },
            child: const Text('Complete sale'),
          ),
        ],
      ),
    );
  }
}
