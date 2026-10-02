import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;

  const StatTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacing4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
