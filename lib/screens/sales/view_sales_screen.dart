import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/screens/sales/pos_screen.dart';
import 'package:nthaka_eco/screens/sales/sale_detail_screen.dart';
import 'package:nthaka_eco/screens/sales/sales_reports_screen.dart';

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({super.key});

  @override
  State<ViewSalesScreen> createState() => _ViewSalesScreenState();
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  static const _pageSize = 25;

  final _scrollController = ScrollController();
  String _searchQuery = '';
  String _dateFilter = 'All';

  final List<Sale> _sales = [];
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

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'Today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return !date.isBefore(
          DateTime(weekStart.year, weekStart.month, weekStart.day),
        );
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  bool _matchesSearch(Sale sale) {
    if (_searchQuery.isEmpty) {
      return true;
    }
    final q = _searchQuery.toLowerCase();
    return sale.items.any(
      (item) => item.itemName.toLowerCase().contains(q),
    );
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);

    if (reset) {
      _offset = 0;
      _sales.clear();
      _hasMore = true;
    }

    final page = await DatabaseHelper.instance.getSalesPaged(
      limit: _pageSize,
      offset: _offset,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _sales.addAll(page.items);
      _offset += page.items.length;
      _hasMore = page.hasMore;
      _loading = false;
    });
  }

  Future<void> _openPos() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PosScreen()),
    );
    if (saved == true) {
      await _loadPage(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleSales = _sales
        .where((sale) => _matchesSearch(sale) && _matchesDateFilter(sale.date))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SalesReportsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPos,
        icon: const Icon(Icons.point_of_sale),
        label: const Text('New sale'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search receipts',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: AppTheme.spacing8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Today', label: Text('Today')),
                    ButtonSegment(value: 'This Week', label: Text('Week')),
                    ButtonSegment(value: 'This Month', label: Text('Month')),
                  ],
                  selected: {_dateFilter},
                  onSelectionChanged: (value) {
                    setState(() => _dateFilter = value.first);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleSales.isEmpty && !_loading
                ? const Center(child: Text('No sales yet. Tap New sale to start.'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: visibleSales.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= visibleSales.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppTheme.spacing16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final sale = visibleSales[index];
                      final qty = sale.items.fold<int>(
                        0,
                        (sum, item) => sum + item.quantity,
                      );
                      return ListTile(
                        title: Text('Receipt #${sale.id}'),
                        subtitle: Text(
                          '${sale.date.toLocal().toString().split(' ').first} · $qty items',
                        ),
                        trailing: Text(sale.totalAmount.toStringAsFixed(2)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SaleDetailScreen(saleId: sale.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
