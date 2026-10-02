import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/disease_report.dart';
import 'package:nthaka_eco/models/item.dart';
import 'package:nthaka_eco/screens/sales/sales_screen.dart';
import 'package:nthaka_eco/widgets/stat_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<
          ({int itemCount, int saleCount, int reportCount, double salesTotal})>
      _statsFuture;
  late Future<List<DiseaseReport>> _followUpsFuture;
  late Future<List<Item>> _lowStockFuture;

  @override
  void initState() {
    super.initState();
    _reloadDashboard();
  }

  void _reloadDashboard() {
    _statsFuture = DatabaseHelper.instance.getDashboardStats();
    _followUpsFuture = DatabaseHelper.instance.getDueFollowUps();
    _lowStockFuture = DatabaseHelper.instance.getLowStockItems();
  }

  Future<void> _markFollowUpDone(DiseaseReport report) async {
    await DatabaseHelper.instance.markFollowUpDone(report.id);
    if (mounted) setState(_reloadDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nthaka.Eco')),
      body: FutureBuilder(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats = snapshot.data!;
          final setupComplete = stats.itemCount > 0 &&
              stats.saleCount > 0 &&
              stats.reportCount > 0;

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            children: [
              if (!setupComplete) ...[
                Text(
                  'Start by adding items, then open the register to record a sale.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesScreen()),
                  ).then((_) {
                    if (mounted) setState(_reloadDashboard);
                  });
                },
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Open register'),
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (!setupComplete) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get started',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        _ChecklistStep(
                          complete: stats.itemCount > 0,
                          text: 'Add the products you sell',
                        ),
                        _ChecklistStep(
                          complete: stats.saleCount > 0,
                          text: 'Record your first sale',
                        ),
                        _ChecklistStep(
                          complete: stats.reportCount > 0,
                          text: 'Scan a crop for plant health',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],
              FutureBuilder<List<DiseaseReport>>(
                future: _followUpsFuture,
                builder: (context, snapshot) {
                  final reports = snapshot.data ?? const <DiseaseReport>[];
                  if (reports.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event_note_outlined,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: AppTheme.spacing8),
                              Expanded(
                                child: Text('Crop follow-ups',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              Text('${reports.length} due'),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          ...reports.take(3).map(
                                (report) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(report.crop),
                                  subtitle: Text(
                                    '${report.disease} · Check scheduled now',
                                  ),
                                  trailing: TextButton(
                                    onPressed: () => _markFollowUpDone(report),
                                    child: const Text('Mark done'),
                                  ),
                                ),
                              ),
                          if (reports.length > 3)
                            Text('${reports.length - 3} more follow-ups due.'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              FutureBuilder<List<Item>>(
                future: _lowStockFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <Item>[];
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Low stock',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppTheme.spacing4),
                          ...items.take(3).map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading:
                                      const Icon(Icons.inventory_2_outlined),
                                  title: Text(item.itemName),
                                  trailing: Text(
                                    '${item.stockQuantity} left',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacing24),
              Text('Overview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacing12),
              StatTile(label: 'Items', value: '${stats.itemCount}'),
              StatTile(label: 'Sales', value: '${stats.saleCount}'),
              StatTile(
                label: 'Sales total',
                value: stats.salesTotal.toStringAsFixed(2),
              ),
              StatTile(label: 'Plant scans', value: '${stats.reportCount}'),
            ],
          );
        },
      ),
    );
  }
}

class _ChecklistStep extends StatelessWidget {
  const _ChecklistStep({required this.complete, required this.text});

  final bool complete;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
        child: Row(
          children: [
            Icon(
              complete ? Icons.check_circle : Icons.circle_outlined,
              color: complete
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
