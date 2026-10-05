import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/item.dart';
import 'package:nthaka_eco/models/stock_adjustment.dart';
import 'package:nthaka_eco/screens/items/inventory_batches_screen.dart';
import 'package:nthaka_eco/screens/sales/barcode_scanner_screen.dart';

class InventoryToolsScreen extends StatefulWidget {
  const InventoryToolsScreen({super.key});

  @override
  State<InventoryToolsScreen> createState() => _InventoryToolsScreenState();
}

class _InventoryToolsScreenState extends State<InventoryToolsScreen> {
  late Future<List<Item>> _itemsFuture;
  late Future<List<StockAdjustment>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _itemsFuture = DatabaseHelper.instance.searchCatalogItems(limit: 1000);
    _historyFuture = DatabaseHelper.instance.getStockAdjustments();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_itemsFuture, _historyFuture]);
  }

  Future<void> _showAdjustment({required bool isCount}) async {
    final items = await _itemsFuture;
    if (!mounted || items.isEmpty) return;
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StockEntrySheet(items: items, isCount: isCount),
    );
    if (completed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Inventory tools'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.tune_outlined), text: 'Adjust stock'),
                Tab(icon: Icon(Icons.history_outlined), text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              FutureBuilder<List<Item>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    children: [
                      Text('Keep inventory accurate',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.spacing4),
                      const Text(
                        'Record restocks, damaged goods, expiry losses, and physical stock counts. Every change stays in the local history.',
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      FilledButton.icon(
                        onPressed: items.isEmpty
                            ? null
                            : () => _showAdjustment(isCount: true),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Record stock count'),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      OutlinedButton.icon(
                        onPressed: items.isEmpty
                            ? null
                            : () => _showAdjustment(isCount: false),
                        icon: const Icon(Icons.add_chart_outlined),
                        label: const Text('Adjust stock manually'),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoryBatchesScreen(),
                          ),
                        ).then((_) => _refresh()),
                        icon: const Icon(Icons.layers_outlined),
                        label: const Text('Manage batches and expiry dates'),
                      ),
                      if (items.isEmpty) ...[
                        const SizedBox(height: AppTheme.spacing16),
                        const Text('Add an item before recording inventory.'),
                      ],
                      const SizedBox(height: AppTheme.spacing24),
                      Text('Current stock',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppTheme.spacing8),
                      ...items.take(8).map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(item.itemName),
                              subtitle: Text(item.category),
                              trailing: Text('${item.stockQuantity}'),
                            ),
                          ),
                      if (items.length > 8)
                        Text(
                            '${items.length - 8} more items in your catalogue.'),
                    ],
                  );
                },
              ),
              FutureBuilder<List<StockAdjustment>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing24),
                        child: Text('No manual stock changes yet.'),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spacing8),
                      itemBuilder: (context, index) =>
                          _AdjustmentCard(entry: entries[index]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class _StockEntrySheet extends StatefulWidget {
  const _StockEntrySheet({required this.items, required this.isCount});

  final List<Item> items;
  final bool isCount;

  @override
  State<_StockEntrySheet> createState() => _StockEntrySheetState();
}

class _StockEntrySheetState extends State<_StockEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  late Item _selectedItem = widget.items.first;
  String _reason = 'Restock';
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final quantity = int.parse(_quantityController.text.trim());
    if (widget.isCount) {
      await DatabaseHelper.instance.setItemStockCount(
        itemId: _selectedItem.itemId,
        actualQuantity: quantity,
        notes: _notesController.text,
      );
    } else {
      await DatabaseHelper.instance.adjustItemStock(
        itemId: _selectedItem.itemId,
        changeQuantity: quantity,
        reason: _reason,
        notes: _notesController.text,
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _scanItem() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return;
    final match =
        widget.items.where((item) => item.barcode == barcode).firstOrNull;
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No catalogue item uses that barcode.')),
      );
      return;
    }
    setState(() => _selectedItem = match);
  }

  String _countVarianceLabel() {
    final counted = int.tryParse(_quantityController.text.trim()) ?? 0;
    final difference = counted - _selectedItem.stockQuantity;
    if (difference == 0) {
      return 'No variance — stock matches the saved quantity.';
    }
    return 'Variance: ${difference > 0 ? '+' : ''}$difference item${difference.abs() == 1 ? '' : 's'}.';
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          AppTheme.spacing8,
          AppTheme.spacing16,
          MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.isCount ? 'Record stock count' : 'Adjust stock',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacing4),
              Text(widget.isCount
                  ? 'Enter the number physically counted. The app records the difference.'
                  : 'Use a positive or negative number, then give the reason.'),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Item>(
                      key: ValueKey(_selectedItem.itemId),
                      initialValue: _selectedItem,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Item'),
                      items: widget.items
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.itemName),
                              ))
                          .toList(),
                      onChanged: (item) =>
                          setState(() => _selectedItem = item!),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  IconButton.filledTonal(
                    tooltip: 'Scan item barcode',
                    onPressed: _scanItem,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text('Saved quantity: ${_selectedItem.stockQuantity}'),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: widget.isCount
                      ? 'Actual quantity counted'
                      : 'Change in quantity',
                  helperText: widget.isCount
                      ? 'For example: 24'
                      : 'For example: 12 to add, -2 to remove',
                ),
                validator: (value) {
                  if (int.tryParse(value?.trim() ?? '') == null) {
                    return 'Enter a whole number';
                  }
                  if (widget.isCount && int.parse(value!.trim()) < 0) {
                    return 'A stock count cannot be negative';
                  }
                  return null;
                },
                onChanged: widget.isCount ? (_) => setState(() {}) : null,
              ),
              if (widget.isCount &&
                  int.tryParse(_quantityController.text.trim()) != null) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  _countVarianceLabel(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
              if (!widget.isCount) ...[
                const SizedBox(height: AppTheme.spacing12),
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: const [
                    'Restock',
                    'Damage',
                    'Expired',
                    'Return',
                    'Correction',
                  ]
                      .map((reason) =>
                          DropdownMenuItem(value: reason, child: Text(reason)))
                      .toList(),
                  onChanged: (reason) => setState(() => _reason = reason!),
                ),
              ],
              const SizedBox(height: AppTheme.spacing12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  helperText:
                      'For example, delivery reference or damaged package.',
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(
                    widget.isCount ? 'Save stock count' : 'Save adjustment'),
              ),
            ],
          ),
        ),
      );
}

class _AdjustmentCard extends StatelessWidget {
  const _AdjustmentCard({required this.entry});

  final StockAdjustment entry;

  @override
  Widget build(BuildContext context) {
    final positive = entry.changeQuantity > 0;
    final color = positive
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.error;
    final stamp = entry.createdAt.toLocal().toString().split('.').first;
    return Card(
      child: ListTile(
        leading: Icon(
            positive ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: color),
        title: Text(entry.itemName),
        subtitle: Text(
          '${entry.reason} · ${entry.previousQuantity} → ${entry.newQuantity}\n$stamp${entry.notes?.isNotEmpty == true ? ' · ${entry.notes}' : ''}',
        ),
        isThreeLine: true,
        trailing: Text(
          '${positive ? '+' : ''}${entry.changeQuantity}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
