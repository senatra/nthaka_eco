import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/screens/sales/pos_screen.dart';
import 'package:nthaka_eco/screens/sales/sale_detail_screen.dart';
import 'package:nthaka_eco/screens/sales/sales_reports_screen.dart';

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ViewSalesScreen> createState() => _ViewSalesScreenState();
}

class _AuditBadge extends StatelessWidget {
  const _AuditBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRefund = label == 'Refunded';
    final isCorrected = label == 'Corrected';
    final color = isRefund
        ? scheme.error
        : isCorrected
            ? scheme.tertiary
            : scheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  static const _pageSize = 25;

  final _scrollController = ScrollController();
  String _searchQuery = '';
  String _dateFilter = 'All';
  String _auditFilter = 'All';

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

  bool _matchesAuditFilter(Sale sale) {
    switch (_auditFilter) {
      case 'Completed':
        return sale.status != 'refunded' && sale.correctionNote == null;
      case 'Corrected':
        return sale.status != 'refunded' && sale.correctionNote != null;
      case 'Refunded':
        return sale.status == 'refunded';
      default:
        return true;
    }
  }

  String _auditStatus(Sale sale) {
    if (sale.status == 'refunded') return 'Refunded';
    if (sale.correctionNote != null && sale.correctionNote!.isNotEmpty) {
      return 'Corrected';
    }
    return 'Completed';
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PosScreen()),
    );
    if (!mounted) return;
    await _loadPage(reset: true);
  }

  String _formatReceiptDate(DateTime date) {
    final local = date.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} · $time';
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final visibleSales = _sales
        .where((sale) =>
            _matchesSearch(sale) &&
            _matchesDateFilter(sale.date) &&
            _matchesAuditFilter(sale))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacing16,
            AppTheme.spacing12,
            AppTheme.spacing16,
            AppTheme.spacing8,
          ),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search receipts',
                  hintText: 'Search by product on receipt',
                  helperText: 'Use the date filter to narrow the list.',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: AppTheme.spacing12),
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
              const SizedBox(height: AppTheme.spacing8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All statuses')),
                    ButtonSegment(value: 'Completed', label: Text('Completed')),
                    ButtonSegment(value: 'Corrected', label: Text('Corrected')),
                    ButtonSegment(value: 'Refunded', label: Text('Refunded')),
                  ],
                  selected: {_auditFilter},
                  onSelectionChanged: (value) {
                    setState(() => _auditFilter = value.first);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visibleSales.isEmpty && !_loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        Text(
                          'No receipts yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          widget.embedded
                              ? 'Complete a sale on the Register tab.'
                              : 'Start a new sale from the register.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!widget.embedded) ...[
                          const SizedBox(height: AppTheme.spacing16),
                          FilledButton.icon(
                            onPressed: _openPos,
                            icon: const Icon(Icons.point_of_sale),
                            label: const Text('Open register'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadPage(reset: true),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacing16,
                      0,
                      AppTheme.spacing16,
                      AppTheme.spacing24,
                    ),
                    itemCount: visibleSales.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacing8),
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
                      final preview =
                          sale.items.take(2).map((i) => i.itemName).join(', ');

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SaleDetailScreen(saleId: sale.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.receipt,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Receipt #${sale.id}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _AuditBadge(label: _auditStatus(sale)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatReceiptDate(sale.date),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (preview.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '$qty items · $preview${sale.items.length > 2 ? '…' : ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppTheme.formatMoney(sale.totalAmount),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
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
        label: const Text('Register'),
      ),
      body: _buildBody(context),
    );
  }
}
