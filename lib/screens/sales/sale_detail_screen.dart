import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/services/report_export_service.dart';

class SaleDetailScreen extends StatelessWidget {
  final int saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  Future<void> _correctSale(BuildContext context, Sale sale) async {
    final notesController = TextEditingController(text: sale.notes ?? '');
    final reasonController = TextEditingController();
    var paymentMethod = sale.paymentMethod;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing8,
              AppTheme.spacing16,
              MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Correct sale details',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacing12),
                DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration:
                        const InputDecoration(labelText: 'Payment method'),
                    items: const ['Cash', 'Mobile money', 'Card']
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => paymentMethod = value!)),
                const SizedBox(height: AppTheme.spacing12),
                TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Sale notes')),
                const SizedBox(height: AppTheme.spacing12),
                TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Correction reason',
                        helperText:
                            'Saved with this receipt for accountability.')),
                const SizedBox(height: AppTheme.spacing16),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save correction')),
              ]),
        ),
      ),
    );
    if (saved == true && reasonController.text.trim().isNotEmpty) {
      await DatabaseHelper.instance.updateSale(Sale(
        id: sale.id,
        date: sale.date,
        totalAmount: sale.totalAmount,
        customerName: sale.customerName,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        discountAmount: sale.discountAmount,
        paymentMethod: paymentMethod,
        amountPaid: sale.amountPaid,
        changeAmount: sale.changeAmount,
        status: sale.status,
        correctionNote: reasonController.text.trim(),
        items: sale.items,
      ));
      if (context.mounted) Navigator.pop(context, true);
    }
    notesController.dispose();
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #$saleId'),
        actions: [
          IconButton(
            tooltip: 'Correct sale details',
            onPressed: () async {
              final sale = await DatabaseHelper.instance.getSale(saleId);
              if (sale != null && context.mounted) _correctSale(context, sale);
            },
            icon: const Icon(Icons.edit_note_outlined),
          ),
          IconButton(
            tooltip: 'Share receipt as PDF',
            onPressed: () async {
              final sale = await DatabaseHelper.instance.getSale(saleId);
              if (sale == null) return;
              final businessName =
                  await DatabaseHelper.instance.getBusinessName();
              await ReportExportService.shareReceiptPdf(
                sale,
                businessName: businessName,
              );
            },
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Refund sale',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Refund this sale?'),
                  content: const Text(
                      'This marks the receipt as refunded. The original receipt remains in your sales history.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      style: AppTheme.destructiveButtonStyle,
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Refund'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              await DatabaseHelper.instance.refundSale(saleId);
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.undo_outlined),
          ),
        ],
      ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.calendar_today_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Date'),
                        trailing: Text(
                          sale.date.toLocal().toString().split('.').first,
                        ),
                      ),
                      ListTile(
                        title: const Text('Payment method'),
                        trailing: Text(sale.paymentMethod),
                      ),
                      if (sale.amountPaid != null)
                        ListTile(
                          title: const Text('Amount paid'),
                          trailing:
                              Text(AppTheme.formatMoney(sale.amountPaid!)),
                        ),
                      if (sale.changeAmount > 0)
                        ListTile(
                          title: const Text('Change given'),
                          trailing:
                              Text(AppTheme.formatMoney(sale.changeAmount)),
                        ),
                      if (sale.status == 'refunded')
                        const ListTile(
                          leading: Icon(Icons.undo, color: AppTheme.red),
                          title: Text('Refunded'),
                        ),
                      if (sale.correctionNote?.isNotEmpty ?? false)
                        ListTile(
                          title: const Text('Correction reason'),
                          subtitle: Text(sale.correctionNote!),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Card(
                child: Column(
                  children: [
                    if (sale.customerName != null &&
                        sale.customerName!.isNotEmpty)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                        ),
                        title: const Text('Customer'),
                        trailing: Text(sale.customerName!),
                      ),
                    if (sale.notes != null && sale.notes!.isNotEmpty)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                        ),
                        title: const Text('Notes'),
                        subtitle: Text(sale.notes!),
                      ),
                    ...sale.items.map(
                      (line) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                        ),
                        title: Text(line.itemName),
                        subtitle: Text(
                          '${line.quantity} × ${AppTheme.formatMoney(line.price)}',
                        ),
                        trailing: Text(
                          AppTheme.formatMoney(line.quantity * line.price),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Subtotal'),
                        trailing: Text(AppTheme.formatMoney(subtotal)),
                      ),
                      if (sale.discountAmount > 0)
                        ListTile(
                          title: const Text('Discount'),
                          trailing: Text(
                            '-${AppTheme.formatMoney(sale.discountAmount)}',
                          ),
                        ),
                      ListTile(
                        title: Text(
                          'Total paid',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: Text(
                          AppTheme.formatMoney(sale.totalAmount),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
