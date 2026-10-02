import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/services/report_export_service.dart';

class CashUpScreen extends StatefulWidget {
  const CashUpScreen({super.key});

  @override
  State<CashUpScreen> createState() => _CashUpScreenState();
}

class _CashUpScreenState extends State<CashUpScreen> {
  final _countedController = TextEditingController();
  late Future<({double cashExpected, double totalSales, int saleCount})>
      _cashUp;

  @override
  void initState() {
    super.initState();
    _cashUp = DatabaseHelper.instance.getCashUp(DateTime.now());
  }

  @override
  void dispose() {
    _countedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Daily cash-up')),
        body: FutureBuilder(
          future: _cashUp,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final counted = double.tryParse(_countedController.text) ?? 0;
            final difference = counted - data.cashExpected;
            return ListView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              children: [
                Text('Today', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacing8),
                const Text(
                    'Count the cash in your drawer, then compare it with recorded cash sales.'),
                const SizedBox(height: AppTheme.spacing16),
                _ValueCard(label: 'Recorded cash', value: data.cashExpected),
                _ValueCard(label: 'All sales', value: data.totalSales),
                _ValueCard(
                    label: 'Completed sales',
                    value: data.saleCount.toDouble(),
                    money: false),
                const SizedBox(height: AppTheme.spacing16),
                TextField(
                  controller: _countedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Cash counted',
                    helperText: 'Enter the physical cash you counted.',
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Card(
                  child: ListTile(
                    title: const Text('Difference'),
                    subtitle: Text(difference == 0
                        ? 'Cash matches the register.'
                        : difference > 0
                            ? 'Over by this amount.'
                            : 'Short by this amount.'),
                    trailing: Text(
                      AppTheme.formatMoney(difference.abs()),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: difference == 0
                                ? AppTheme.green
                                : AppTheme.orange,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                FilledButton.icon(
                  onPressed: () => ReportExportService.shareCashUpPdf(
                    day: DateTime.now(),
                    expectedCash: data.cashExpected,
                    countedCash: counted,
                    totalSales: data.totalSales,
                    saleCount: data.saleCount,
                  ),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Share cash-up PDF'),
                ),
              ],
            );
          },
        ),
      );
}

class _ValueCard extends StatelessWidget {
  const _ValueCard(
      {required this.label, required this.value, this.money = true});
  final String label;
  final double value;
  final bool money;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
        child: Card(
            child: ListTile(
                title: Text(label),
                trailing: Text(money
                    ? AppTheme.formatMoney(value)
                    : value.toInt().toString()))),
      );
}
