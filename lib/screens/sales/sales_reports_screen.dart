import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/database/database_helper.dart';
import 'package:nthaka_eco/models/sales_report.dart';
import 'package:nthaka_eco/services/report_export_service.dart';
import 'package:nthaka_eco/widgets/simple_bar_chart.dart';
import 'package:nthaka_eco/widgets/stat_tile.dart';

enum _ReportRange { today, week, month, custom }

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  _ReportRange _range = _ReportRange.today;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _showRaw = false;
  SalesReportBundle? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  (DateTime start, DateTime endExclusive) _resolveRange() {
    final now = DateTime.now();
    switch (_range) {
      case _ReportRange.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start.add(const Duration(days: 1)));
      case _ReportRange.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return (start, start.add(const Duration(days: 7)));
      case _ReportRange.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return (start, end);
      case _ReportRange.custom:
        final start = _customStart ?? DateTime(now.year, now.month, now.day);
        final end = (_customEnd ?? start).add(const Duration(days: 1));
        return (start, end);
    }
  }

  Future<void> _loadReport() async {
    final (start, end) = _resolveRange();
    final report = await DatabaseHelper.instance.getSalesReport(
      start: start,
      endExclusive: end,
    );
    if (mounted) {
      setState(() => _report = report);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _range = _ReportRange.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
    await _loadReport();
  }

  Future<void> _exportCsv() async {
    final report = _report;
    if (report == null) {
      return;
    }
    final range = _resolveRange();
    await ReportExportService.shareCsv(
      report: report,
      start: range.$1,
      endExclusive: range.$2,
    );
  }

  Future<void> _exportPdf() async {
    final report = _report;
    if (report == null) {
      return;
    }
    final range = _resolveRange();
    await ReportExportService.sharePdf(
      report: report,
      start: range.$1,
      endExclusive: range.$2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final dateFmt = DateFormat.MMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales reports'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: report == null ? null : _exportCsv,
            icon: const Icon(Icons.table_chart_outlined),
          ),
          IconButton(
            tooltip: 'Export PDF',
            onPressed: report == null ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              children: [
                SegmentedButton<_ReportRange>(
                  segments: const [
                    ButtonSegment(
                      value: _ReportRange.today,
                      label: Text('Today'),
                    ),
                    ButtonSegment(
                      value: _ReportRange.week,
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: _ReportRange.month,
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: _ReportRange.custom,
                      label: Text('Custom'),
                    ),
                  ],
                  selected: {_range},
                  onSelectionChanged: (value) async {
                    final selected = value.first;
                    if (selected == _ReportRange.custom) {
                      await _pickCustomRange();
                      return;
                    }
                    setState(() => _range = selected);
                    await _loadReport();
                  },
                ),
                if (_range == _ReportRange.custom &&
                    _customStart != null &&
                    _customEnd != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing8),
                    child: Text(
                      '${dateFmt.format(_customStart!)} – ${dateFmt.format(_customEnd!)}',
                    ),
                  ),
                const SizedBox(height: AppTheme.spacing16),
                StatTile(
                  label: 'Total revenue',
                  value: report.summary.totalRevenue.toStringAsFixed(2),
                ),
                StatTile(
                  label: 'Sales count',
                  value: '${report.summary.saleCount}',
                ),
                StatTile(
                  label: 'Average sale',
                  value: report.summary.averageSale.toStringAsFixed(2),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text('Sales by day',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacing8),
                SimpleBarChart(data: report.salesByDay),
                const SizedBox(height: AppTheme.spacing16),
                Text('Top items',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacing8),
                if (report.topItems.isEmpty)
                  const Text('No item sales in this range')
                else
                  ...report.topItems.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      subtitle: Text('${item.quantity} sold'),
                      trailing: Text(item.revenue.toStringAsFixed(2)),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacing16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show raw transactions'),
                  value: _showRaw,
                  onChanged: (value) => setState(() => _showRaw = value),
                ),
                if (_showRaw)
                  ...report.transactions.map(
                    (sale) => ListTile(
                      title: Text('Receipt #${sale.id}'),
                      subtitle: Text(sale.date.toLocal().toString()),
                      trailing: Text(sale.totalAmount.toStringAsFixed(2)),
                    ),
                  ),
              ],
            ),
    );
  }
}
