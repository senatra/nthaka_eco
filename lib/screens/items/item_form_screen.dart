import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/item.dart';

class ItemFormScreen extends StatefulWidget {
  final int? itemId;

  const ItemFormScreen({super.key, this.itemId});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _lowStockController = TextEditingController(text: '0');
  bool _isFavorite = false;
  late bool _loading;
  bool _saving = false;

  bool get _isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _loading = _isEditing;
    if (_isEditing) {
      _loadItem();
    }
  }

  Future<void> _loadItem() async {
    final item = await DatabaseHelper.instance.getItem(widget.itemId!);
    if (!mounted || item == null) {
      return;
    }
    _nameController.text = item.itemName;
    _descriptionController.text = item.description ?? '';
    _priceController.text =
        item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(2) : '';
    _categoryController.text = item.category;
    _skuController.text = item.sku ?? '';
    _barcodeController.text = item.barcode ?? '';
    _isFavorite = item.isFavorite;
    _stockController.text = item.stockQuantity.toString();
    _lowStockController.text = item.lowStockThreshold.toString();
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final unitPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final category = _categoryController.text.trim().isEmpty
        ? 'General'
        : _categoryController.text.trim();

    if (_isEditing) {
      await DatabaseHelper.instance.updateItem(
        Item(
          itemId: widget.itemId!,
          itemName: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          unitPrice: unitPrice,
          category: category,
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          isFavorite: _isFavorite,
          stockQuantity: int.tryParse(_stockController.text) ?? 0,
          lowStockThreshold: int.tryParse(_lowStockController.text) ?? 0,
        ),
      );
    } else {
      await DatabaseHelper.instance.createItem(
        Item(
          itemId: 0,
          itemName: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          unitPrice: unitPrice,
          category: category,
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          isFavorite: _isFavorite,
          stockQuantity: int.tryParse(_stockController.text) ?? 0,
          lowStockThreshold: int.tryParse(_lowStockController.text) ?? 0,
        ),
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text(
          'This removes the item from your register. Past receipts will keep their existing item details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: AppTheme.destructiveButtonStyle,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete item'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper.instance.deleteItem(widget.itemId!);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit item' : 'New item'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _delete,
              style: AppTheme.destructiveIconButtonStyle,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacing16,
                  AppTheme.spacing16,
                  AppTheme.spacing16,
                  MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isEditing
                            ? 'Update product details'
                            : 'Add a product to your catalogue',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        _isEditing
                            ? 'Changes appear in the register straight away.'
                            : 'Start with a name and price. The remaining details are optional.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      const _FormSectionLabel(
                        icon: Icons.inventory_2_outlined,
                        title: 'Product details',
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          helperText: 'Use the name customers will recognise.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          helperText:
                              'Optional details shown when you edit the item.',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      const _FormSectionLabel(
                        icon: Icons.sell_outlined,
                        title: 'Register details',
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category (POS tab)',
                          hintText: 'General',
                          helperText:
                              'Use a category to group items in the register.',
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      const _FormSectionLabel(
                        icon: Icons.qr_code_2_outlined,
                        title: 'Optional identifiers',
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Unit price (for POS)',
                          hintText: '0.00',
                          helperText: 'Enter the price charged for one item.',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU (optional)',
                          helperText: 'Your internal product code.',
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      TextFormField(
                        controller: _barcodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (optional)',
                          helperText:
                              'Type or scan the barcode number to find it quickly in POS.',
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      const _FormSectionLabel(
                        icon: Icons.inventory_outlined,
                        title: 'Stock tracking',
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity in stock',
                                helperText: 'Updated when sold.',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: TextFormField(
                              controller: _lowStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Low-stock level',
                                helperText: '0 turns alerts off.',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.controlRadius),
                        ),
                        tileColor: Theme.of(context).colorScheme.surface,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Favourite item'),
                        subtitle:
                            const Text('Show this item first in the register.'),
                        value: _isFavorite,
                        onChanged: (value) =>
                            setState(() => _isFavorite = value),
                      ),
                      const SizedBox(height: AppTheme.spacing24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _isEditing ? 'Save changes' : 'Create item',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppTheme.spacing8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
}
