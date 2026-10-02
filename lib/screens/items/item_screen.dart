import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/item.dart';
import 'item_form_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const _pageSize = 30;

  final _scrollController = ScrollController();
  final List<Item> _items = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPage(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);

    if (reset) {
      _offset = 0;
      _items.clear();
      _hasMore = true;
    }

    final page = await DatabaseHelper.instance.getItemsPaged(
      limit: _pageSize,
      offset: _offset,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _items.addAll(page.items);
      _offset += page.items.length;
      _hasMore = page.hasMore;
      _loading = false;
    });
  }

  Future<void> _openForm({int? itemId}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemFormScreen(itemId: itemId),
      ),
    );
    if (changed == true) {
      await _loadPage(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: _items.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No items yet'))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacing4),
                  itemBuilder: (context, index) {
                    if (index >= _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppTheme.spacing16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = _items[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      title: Text(item.itemName),
                      subtitle: Text(
                        [
                          if (item.description != null &&
                              item.description!.trim().isNotEmpty)
                            item.description!.trim(),
                          if (item.unitPrice > 0)
                            item.unitPrice.toStringAsFixed(2)
                          else
                            'No price set',
                        ].join('\n'),
                      ),
                      onTap: () => _openForm(itemId: item.itemId),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
