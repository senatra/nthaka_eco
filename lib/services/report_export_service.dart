import 'dart:io';
import 'package:intl/intl.dart';
import 'package:nthaka_eco/models/sales_report.dart';
import 'package:nthaka_eco/services/local_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  static Future<void> shareCsv({
    required SalesReportBundle report,
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final file = await _writeCsv(report, start, endExclusive);
    await Share.shareXFiles([XFile(file.path)], text: 'Nthaka.Eco sales report');
  }

  static Future<void> sharePdf({
    required SalesReportBundle report,
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final file = await _writePdf(report, start, endExclusive);
    await Share.shareXFiles([XFile(file.path)], text: 'Nthaka.Eco sales report');
  }

  static Future<File> _writeCsv(
    SalesReportBundle report,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final buffer = StringBuffer()
      ..writeln('Nthaka.Eco Sales Report')
      ..writeln('Range,${start.toIso8601String()},${endExclusive.toIso8601String()}')
      ..writeln('Total revenue,${report.summary.totalRevenue.toStringAsFixed(2)}')
      ..writeln('Sale count,${report.summary.saleCount}')
      ..writeln('Average sale,${report.summary.averageSale.toStringAsFixed(2)}')
      ..writeln()
      ..writeln('Day,Total')
      ..writeln(
        report.salesByDay.map(
          (day) => '${day.dayKey},${day.total.toStringAsFixed(2)}',
        ).join('\n'),
      )
      ..writeln()
      ..writeln('Top item,Quantity,Revenue')
      ..writeln(
        report.topItems.map(
          (item) =>
              '${_csvEscape(item.name)},${item.quantity},${item.revenue.toStringAsFixed(2)}',
        ).join('\n'),
      )
      ..writeln()
      ..writeln('Receipt ID,Date,Total,Customer,Notes')
      ..writeln(
        report.transactions.map(
          (sale) =>
              '${sale.id},${sale.date.toIso8601String()},${sale.totalAmount.toStringAsFixed(2)},${_csvEscape(sale.customerName ?? '')},${_csvEscape(sale.notes ?? '')}',
        ).join('\n'),
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

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
