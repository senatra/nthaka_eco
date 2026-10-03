import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/inventory_batch.dart';
import 'package:nthaka_eco/models/item.dart';

class InventoryBatchesScreen extends StatefulWidget {
  const InventoryBatchesScreen({super.key});

  @override
  State<InventoryBatchesScreen> createState() => _InventoryBatchesScreenState();
}

class _InventoryBatchesScreenState extends State<InventoryBatchesScreen> {
  late Future<List<Item>> _itemsFuture;
  late Future<List<InventoryBatch>> _batchesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _itemsFuture = DatabaseHelper.instance.searchCatalogItems(limit: 1000);
    _batchesFuture = DatabaseHelper.instance.getInventoryBatches();
  }

  Future<void> _addBatch() async {
    final items = await _itemsFuture;
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an item to your catalog first.')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BatchEntrySheet(items: items),
    );
    if (saved == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Batches'),
          actions: [
            IconButton(
              tooltip: 'Receive a batch',
              onPressed: _addBatch,
              icon: const Icon(Icons.add_box_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addBatch,
          icon: const Icon(Icons.add),
          label: const Text('Receive batch'),
        ),
        body: FutureBuilder<List<InventoryBatch>>(
          future: _batchesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final batches = snapshot.data!;
            if (batches.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  children: const [
                    SizedBox(height: 120),
                    Text(
                      'No active batches yet. Receive a batch to track quantities, cost, and expiry dates.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacing16,
                  AppTheme.spacing16,
                  AppTheme.spacing16,
                  96,
                ),
                itemCount: batches.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.spacing8),
                itemBuilder: (context, index) =>
                    _BatchCard(batch: batches[index]),
              ),
            );
          },
        ),
      );

  Future<void> _refresh() async {
    setState(_reload);
    await _batchesFuture;
  }
}

class _BatchEntrySheet extends StatefulWidget {
  const _BatchEntrySheet({required this.items});
  final List<Item> items;

  @override
  State<_BatchEntrySheet> createState() => _BatchEntrySheetState();
}

class _BatchEntrySheetState extends State<_BatchEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  late Item _item = widget.items.first;
  DateTime? _expiresAt;
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 20),
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 90)),
    );
    if (value != null) setState(() => _expiresAt = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.createInventoryBatch(
        itemId: _item.itemId,
        batchCode: _codeController.text.trim(),
        quantity: int.parse(_quantityController.text),
        unitCost: double.tryParse(_costController.text),
        receivedAt: DateTime.now(),
        expiresAt: _expiresAt,
        notes: _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the batch. Try again.')),
      );
    }
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
              Text('Receive a batch',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacing4),
              const Text('Receiving a batch adds its quantity to stock.'),
              const SizedBox(height: AppTheme.spacing16),
              DropdownButtonFormField<Item>(
                value: _item,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Item'),
                items: widget.items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.itemName),
                        ))
                    .toList(),
                onChanged: (item) => setState(() => _item = item!),
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Batch / lot code',
                  helperText: 'Use a supplier or package batch number.',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a batch code'
                    : null,
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(labelText: 'Quantity received'),
                validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                    ? 'Enter a quantity'
                    : null,
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost per item (optional)',
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(_expiresAt == null
                    ? 'No expiry date'
                    : 'Expires ${_expiresAt!.toLocal().toString().split(' ').first}'),
                trailing: TextButton(
                  onPressed: _pickExpiry,
                  child: Text(_expiresAt == null ? 'Add date' : 'Change'),
                ),
              ),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: AppTheme.spacing20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Receive batch'),
              ),
            ],
          ),
        ),
      );
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});
  final InventoryBatch batch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expiryText = batch.expiresAt == null
        ? 'No expiry date'
        : batch.isExpired
            ? 'Expired'
            : batch.expiresSoon
                ? 'Expires soon'
                : 'Expires ${batch.expiresAt!.toLocal().toString().split(' ').first}';
    final expiryColor = batch.isExpired
        ? scheme.error
        : batch.expiresSoon
            ? scheme.tertiary
            : scheme.onSurfaceVariant;
    return Card(
      child: ListTile(
        leading: Icon(Icons.layers_outlined, color: scheme.primary),
        title: Text(batch.itemName),
        subtitle: Text(
          'Batch ${batch.batchCode} · $expiryText${batch.unitCost == null ? '' : ' · Cost ${AppTheme.formatMoney(batch.unitCost!)}'}',
          style: TextStyle(color: expiryColor),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${batch.quantityRemaining} left',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('of ${batch.quantityReceived}',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
