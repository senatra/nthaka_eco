import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/item.dart';
import 'package:nthaka_eco/models/pos_cart_line.dart';
import 'package:nthaka_eco/models/pos_session_state.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/screens/sales/sale_detail_screen.dart';
import 'package:nthaka_eco/widgets/pos/cart_panel.dart';
import 'package:nthaka_eco/widgets/pos/product_grid.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

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
      _session = draft;
      _categories = ['All', ...categories.where((c) => c != 'All')];
    });
    await _loadCatalog();
  }

  void _onSearchChanged() {
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

  void _addProduct(Item item, {int quantity = 1}) {
    var price = item.unitPrice;
    if (price <= 0) {
      _promptUnitPrice(item).then((entered) {
        if (entered == null || entered <= 0 || !mounted) {
          return;
        }
        _setSession(
          _session.copyWith(
            lines: _mergeLine(
              PosCartLine(
                catalogItemId: item.itemId,
                name: item.itemName,
                unitPrice: entered,
                quantity: quantity,
              ),
            ),
          ),
        );
      });
      return;
    }

    _setSession(
      _session.copyWith(
        lines: _mergeLine(
          PosCartLine(
            catalogItemId: item.itemId,
            name: item.itemName,
            unitPrice: price,
            quantity: quantity,
          ),
        ),
      ),
    );
  }

  Future<double?> _promptUnitPrice(Item item) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price · ${item.itemName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(labelText: 'Unit price'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text.trim())),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  void _changeQty(PosCartLine line, int delta) {
    final updated = _session.lines.map((entry) {
      if (entry.cartKey != line.cartKey) {
        return entry;
      }
      final qty = entry.quantity + delta;
      return entry.copyWith(quantity: qty);
    }).where((entry) => entry.quantity > 0).toList();

    _setSession(_session.copyWith(lines: updated));
  }

  void _voidTicket() {
    _setSession(const PosSessionState());
  }

  Future<void> _holdTicket() async {
    if (_session.isEmpty) {
      return;
    }
    final labelController = TextEditingController(
      text: 'Ticket ${_session.itemCount} items',
    );
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hold ticket'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(labelText: 'Label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, labelController.text.trim()),
            child: const Text('Hold'),
          ),
        ],
      ),
    );
    labelController.dispose();
    if (label == null || label.isEmpty) {
      return;
    }

    await DatabaseHelper.instance.parkSale(label, _session);
    _setSession(const PosSessionState());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Held: $label')),
      );
    }
  }

  Future<void> _applyDiscount() async {
    final controller = TextEditingController(
      text: _session.discountAmount > 0
          ? _session.discountAmount.toStringAsFixed(2)
          : '',
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ticket discount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(labelText: 'Amount off'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0.0),
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text.trim())),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) {
      return;
    }
    _setSession(_session.copyWith(discountAmount: amount < 0 ? 0 : amount));
  }

  Future<void> _optionalDetails() async {
    final customerController =
        TextEditingController(text: _session.customerName ?? '');
    final notesController = TextEditingController(text: _session.notes ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
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
              controller: customerController,
              decoration: const InputDecoration(labelText: 'Customer (optional)'),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacing16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      _setSession(
        PosSessionState(
          lines: _session.lines,
          discountAmount: _session.discountAmount,
          customerName: customerController.text.trim().isEmpty
              ? null
              : customerController.text.trim(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        ),
      );
    }
    customerController.dispose();
    notesController.dispose();
  }

  Future<void> _completeSale() async {
    if (_session.isEmpty) {
      return;
    }

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
        items: saleItems,
      ),
    );

    await DatabaseHelper.instance.clearActivePosDraft();
    if (!mounted) {
      return;
    }

    setState(() => _session = const PosSessionState());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sale #${sale.id} complete · ${sale.totalAmount.toStringAsFixed(2)}'),
        action: SnackBarAction(
          label: 'Receipt',
          onPressed: () {
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

    if (selected == null) {
      return;
    }

    _setSession(selected.session);
    await DatabaseHelper.instance.deleteParkedSale(selected.id);
  }

  Widget _buildCatalogPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacing16,
            AppTheme.spacing8,
            AppTheme.spacing16,
            AppTheme.spacing8,
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search products',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            children: _categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacing8),
                child: FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                    _loadCatalog();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ProductGrid(
            products: _catalog,
            onTap: (item) => _addProduct(item),
            onLongPress: (item) => _addProduct(item, quantity: 5),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of sale'),
        actions: [
          IconButton(
            tooltip: 'Held tickets',
            onPressed: _openParkedSales,
            icon: const Icon(Icons.pause_circle_outline),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                Expanded(flex: 3, child: _buildCatalogPane()),
                Expanded(
                  flex: 2,
                  child: CartPanel(
                    session: _session,
                    onCharge: _completeSale,
                    onVoid: _voidTicket,
                    onHold: _holdTicket,
                    onDiscount: _applyDiscount,
                    onOptionalDetails: _optionalDetails,
                    onQtyChanged: _changeQty,
                    onLongPressLine: (line) => _changeQty(line, 4),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 6, child: _buildCatalogPane()),
                Expanded(
                  flex: 5,
                  child: CartPanel(
                    session: _session,
                    onCharge: _completeSale,
                    onVoid: _voidTicket,
                    onHold: _holdTicket,
                    onDiscount: _applyDiscount,
                    onOptionalDetails: _optionalDetails,
                    onQtyChanged: _changeQty,
                    onLongPressLine: (line) => _changeQty(line, 4),
                  ),
                ),
              ],
            ),
    );
  }
}
