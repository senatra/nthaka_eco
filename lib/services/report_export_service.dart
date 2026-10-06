import 'dart:io';
import 'package:intl/intl.dart';
import 'package:nthaka_eco/models/sales_report.dart';
import 'package:nthaka_eco/app/app_preferences.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/services/local_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  static Future<void> shareCashUpPdf({
    required DateTime day,
    required double expectedCash,
    required double countedCash,
    required double totalSales,
    required int saleCount,
  }) async {
    final doc = pw.Document()
      ..addPage(
        pw.Page(
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Nthaka.Eco Daily Cash-up',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(DateFormat.yMMMd().format(day)),
                pw.SizedBox(height: 20),
                pw.Text('Completed sales: $saleCount'),
                pw.Text('All sales: ${totalSales.toStringAsFixed(2)}'),
                pw.Text('Recorded cash: ${expectedCash.toStringAsFixed(2)}'),
                pw.Text('Cash counted: ${countedCash.toStringAsFixed(2)}'),
                pw.Divider(),
                pw.Text(
                    'Difference: ${(countedCash - expectedCash).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    final dir = await LocalStorageService.getDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
    final file = File(p.join(exportsDir.path,
        'cash_up_${DateTime.now().millisecondsSinceEpoch}.pdf'));
    await file.writeAsBytes(await doc.save());
    await _shareFile(file, 'Nthaka.Eco daily cash-up');
  }

  static Future<void> shareReceiptPdf(Sale sale,
      {String businessName = 'Nthaka.Eco'}) async {
    final file = await _writeReceiptPdf(sale, businessName: businessName);
    await _shareFile(file, 'Nthaka.Eco receipt #${sale.id}');
  }

  static Future<void> shareCsv({
    required SalesReportBundle report,
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final file = await _writeCsv(report, start, endExclusive);
    await _shareFile(file, 'Nthaka.Eco sales report');
  }

  static Future<void> sharePdf({
    required SalesReportBundle report,
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final file = await _writePdf(report, start, endExclusive);
    await _shareFile(file, 'Nthaka.Eco sales report');
  }

  static Future<void> _shareFile(File file, String text) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }

  static Future<File> _writeCsv(
    SalesReportBundle report,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final buffer = StringBuffer()
      ..writeln('Nthaka.Eco Sales Report')
      ..writeln(
          'Range,${start.toIso8601String()},${endExclusive.toIso8601String()}')
      ..writeln(
          'Total revenue,${report.summary.totalRevenue.toStringAsFixed(2)}')
      ..writeln('Sale count,${report.summary.saleCount}')
      ..writeln('Average sale,${report.summary.averageSale.toStringAsFixed(2)}')
      ..writeln()
      ..writeln('Day,Total')
      ..writeln(
        report.salesByDay
            .map(
              (day) => '${day.dayKey},${day.total.toStringAsFixed(2)}',
            )
            .join('\n'),
      )
      ..writeln()
      ..writeln('Top item,Quantity,Revenue')
      ..writeln(
        report.topItems
            .map(
              (item) =>
                  '${_csvEscape(item.name)},${item.quantity},${item.revenue.toStringAsFixed(2)}',
            )
            .join('\n'),
      )
      ..writeln()
      ..writeln(
          'Receipt ID,Date,Subtotal,Discount,Tax rate,Tax amount,Total,Customer,Notes')
      ..writeln(
        report.transactions
            .map(
              (sale) =>
                  '${sale.id},${sale.date.toIso8601String()},${(sale.totalAmount - sale.taxAmount + sale.discountAmount).toStringAsFixed(2)},${sale.discountAmount.toStringAsFixed(2)},${sale.taxRate.toStringAsFixed(2)},${sale.taxAmount.toStringAsFixed(2)},${sale.totalAmount.toStringAsFixed(2)},${_csvEscape(sale.customerName ?? '')},${_csvEscape(sale.notes ?? '')}',
            )
            .join('\n'),
      );

    final dir = await LocalStorageService.getDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File(
      p.join(
        exportsDir.path,
        'sales_report_${DateTime.now().millisecondsSinceEpoch}.csv',
      ),
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  static Future<File> _writePdf(
    SalesReportBundle report,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final dateFmt = DateFormat.yMMMd();
    final doc = pw.Document()
      ..addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text('Nthaka.Eco Sales Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.SizedBox(height: 8),
            pw.Text(
              '${dateFmt.format(start)} – ${dateFmt.format(endExclusive.subtract(const Duration(days: 1)))}',
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Revenue: ${report.summary.totalRevenue.toStringAsFixed(2)}',
            ),
            pw.Text('Sales: ${report.summary.saleCount}'),
            pw.Text(
              'Average: ${report.summary.averageSale.toStringAsFixed(2)}',
            ),
            pw.SizedBox(height: 16),
            pw.Text('Top items',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...report.topItems.map(
              (item) => pw.Text(
                '${item.name} · ${item.quantity} sold · ${item.revenue.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      );

    final dir = await LocalStorageService.getDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File(
      p.join(
        exportsDir.path,
        'sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<File> _writeReceiptPdf(Sale sale,
      {required String businessName}) async {
    final subtotal = sale.items.fold<double>(
      0,
      (sum, item) => sum + item.quantity * item.price,
    );
    final dateFmt = DateFormat.yMMMd().add_jm();
    final doc = pw.Document()
      ..addPage(
        pw.Page(
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Receipt #${sale.id}'),
                pw.Text(dateFmt.format(sale.date.toLocal())),
                if (sale.customerName?.isNotEmpty ?? false)
                  pw.Text('Customer: ${sale.customerName}'),
                pw.SizedBox(height: 16),
                ...sale.items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                            child:
                                pw.Text('${item.quantity} × ${item.itemName}')),
                        pw.Text(
                            (item.quantity * item.price).toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ),
                pw.Divider(),
                _receiptTotalRow('Subtotal', subtotal),
                if (sale.discountAmount > 0)
                  _receiptTotalRow('Discount', -sale.discountAmount),
                if (sale.taxAmount > 0)
                  _receiptTotalRow(
                    'Tax (${sale.taxRate.toStringAsFixed(1)}%)',
                    sale.taxAmount,
                  ),
                _receiptTotalRow('Total paid', sale.totalAmount,
                    emphasize: true),
                if (sale.notes?.isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('Notes: ${sale.notes}'),
                ],
                pw.Spacer(),
                pw.Center(child: pw.Text(AppPreferences.receiptFooter.value)),
                pw.SizedBox(height: 6),
                pw.Center(child: pw.Text('Powered by Nexa Circuit')),
              ],
            ),
          ),
        ),
      );

    final dir = await LocalStorageService.getDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File(p.join(exportsDir.path, 'receipt_${sale.id}.pdf'));
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static pw.Widget _receiptTotalRow(
    String label,
    double value, {
    bool emphasize = false,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: emphasize
                    ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                    : null),
            pw.Text(
              value.toStringAsFixed(2),
              style: emphasize
                  ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                  : null,
            ),
          ],
        ),
      );

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}