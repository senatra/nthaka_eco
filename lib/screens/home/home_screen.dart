import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/screens/sales/pos_screen.dart';
import 'package:nthaka_eco/screens/sales/sales_reports_screen.dart';
import 'package:nthaka_eco/screens/sales/view_sales_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _statsFuture = DatabaseHelper.instance.getDashboardStats();
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
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PosScreen()),
                  ).then((_) {
                    setState(() {
                      _statsFuture =
                          DatabaseHelper.instance.getDashboardStats();
                    });
                  });
                },
                icon: const Icon(Icons.point_of_sale),
                label: const Text('New sale'),
              ),
              const SizedBox(height: AppTheme.spacing8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewSalesScreen(),
                    ),
                  );
                },
                child: const Text('Sales history'),
              ),
              const SizedBox(height: AppTheme.spacing8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesReportsScreen(),
                    ),
                  );
                },
                child: const Text('Sales reports'),
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
