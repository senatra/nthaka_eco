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
        ),
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit item' : 'New item'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
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
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (POS tab)',
                        hintText: 'General',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit price (for POS)',
                        hintText: '0.00',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_isEditing ? 'Save changes' : 'Create item'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
