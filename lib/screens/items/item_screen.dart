import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/item.dart';
import 'item_form_screen.dart';
import 'inventory_tools_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const _pageSize = 30;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasMore &&
        !_loading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    if (reset) {
      _offset = 0;
      _items.clear();
      _hasMore = true;
    }
    final page = await DatabaseHelper.instance
        .getItemsPaged(limit: _pageSize, offset: _offset);
    if (!mounted) return;
    setState(() {
      _items.addAll(page.items);
      _offset += page.items.length;
      _hasMore = page.hasMore;
      _loading = false;
    });
  }

  Future<void> _openForm({int? itemId}) async {
    final changed = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => ItemFormScreen(itemId: itemId)));
    if (changed == true && mounted) await _loadPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible = _items
        .where((item) =>
            query.isEmpty ||
            item.itemName.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            (item.sku?.toLowerCase().contains(query) ?? false) ||
            (item.barcode?.contains(query) ?? false))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            tooltip: 'Inventory tools',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryToolsScreen()),
            ).then((_) => _loadPage(reset: true)),
            icon: const Icon(Icons.inventory_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          tooltip: 'Add an item',
          icon: const Icon(Icons.add),
          label: const Text('Add item')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.spacing16,
              AppTheme.spacing12, AppTheme.spacing16, AppTheme.spacing8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your catalogue',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacing4),
            Text('Add products once, then find them quickly in the register.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: 'Find an item',
                    hintText: 'Name, category, SKU, or barcode',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close)))),
          ]),
        ),
        Expanded(
            child: _items.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? _EmptyItems(
                        hasItems: _items.isNotEmpty, onAdd: () => _openForm())
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(AppTheme.spacing16,
                            AppTheme.spacing8, AppTheme.spacing16, 96),
                        itemCount: visible.length +
                            (_hasMore && query.isEmpty ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.spacing8),
                        itemBuilder: (context, index) {
                          if (index >= visible.length) {
                            return const Padding(
                                padding: EdgeInsets.all(AppTheme.spacing16),
                                child:
                                    Center(child: CircularProgressIndicator()));
                          }
                          return _ItemCard(
                              item: visible[index],
                              onTap: () =>
                                  _openForm(itemId: visible[index].itemId));
                        },
                      )),
      ]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});
  final Item item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: item.isFavorite
                            ? Theme.of(context).colorScheme.tertiaryContainer
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppTheme.controlRadius)),
                    child: Icon(
                        item.isFavorite
                            ? Icons.star_rounded
                            : Icons.inventory_2_outlined,
                        color: item.isFavorite
                            ? Theme.of(context).colorScheme.onTertiaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer)),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(item.itemName,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(item.category,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        item.isTaxable ? 'Taxable' : 'Tax exempt',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: item.isTaxable
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                      if (item.sku?.isNotEmpty ?? false)
                        Text('SKU: ${item.sku}',
                            style: Theme.of(context).textTheme.labelSmall)
                    ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                      item.unitPrice > 0
                          ? AppTheme.formatMoney(item.unitPrice)
                          : 'No price',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: item.unitPrice > 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right)
                ]),
              ]))));
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems({required this.hasItems, required this.onAdd});
  final bool hasItems;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                hasItems
                    ? Icons.search_off_outlined
                    : Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppTheme.spacing12),
            Text(hasItems ? 'No matching items' : 'Build your catalogue',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacing8),
            Text(
                hasItems
                    ? 'Try a different search term.'
                    : 'Add products, prices, categories, and optional barcode details.',
                textAlign: TextAlign.center),
            if (!hasItems) ...[
              const SizedBox(height: AppTheme.spacing16),
              FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add first item'))
            ],
          ])));
}
