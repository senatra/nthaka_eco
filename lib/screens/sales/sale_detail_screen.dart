import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/sale.dart';

class SaleDetailScreen extends StatelessWidget {
  final int saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Receipt #$saleId')),
      body: FutureBuilder<Sale?>(
        future: DatabaseHelper.instance.getSale(saleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sale = snapshot.data;
          if (sale == null) {
            return const Center(child: Text('Sale not found'));
          }

          final subtotal = sale.items.fold<double>(
            0,
            (sum, line) => sum + line.quantity * line.price,
          );

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                trailing: Text(sale.date.toLocal().toString().split('.').first),
              ),
              if (sale.customerName != null && sale.customerName!.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Customer'),
                  trailing: Text(sale.customerName!),
                ),
              if (sale.notes != null && sale.notes!.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notes'),
                  subtitle: Text(sale.notes!),
                ),
              const Divider(),
              ...sale.items.map(
                (line) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line.itemName),
                  subtitle: Text(
                    '${line.quantity} × ${line.price.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    (line.quantity * line.price).toStringAsFixed(2),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Subtotal'),
                trailing: Text(subtotal.toStringAsFixed(2)),
              ),
              if (sale.discountAmount > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Discount'),
                  trailing: Text('-${sale.discountAmount.toStringAsFixed(2)}'),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Text(
                  sale.totalAmount.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
