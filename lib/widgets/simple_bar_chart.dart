import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/models/sales_report.dart';

class SimpleBarChart extends StatelessWidget {
  final List<SalesDayTotal> data;

  const SimpleBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('No sales in this range');
    }

    final maxValue = data.map((d) => d.total).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: data.map((entry) {
        final fraction = maxValue == 0 ? 0.0 : entry.total / maxValue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  entry.dayKey.substring(5),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 20,
                    value: fraction,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              SizedBox(
                width: 64,
                child: Text(
                  entry.total.toStringAsFixed(0),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
