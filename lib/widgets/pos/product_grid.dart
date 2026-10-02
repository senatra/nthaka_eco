import 'package:flutter/material.dart';
import 'package:nthaka_eco/app/app_theme.dart';
import 'package:nthaka_eco/models/item.dart';

class ProductGrid extends StatelessWidget {
  final List<Item> products;
  final void Function(Item item) onTap;
  final void Function(Item item) onLongPress;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'No products here',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                'Try another category or add items under the Items tab.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppTheme.spacing12,
            crossAxisSpacing: AppTheme.spacing12,
            childAspectRatio: 0.92,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final item = products[index];
            final hasPrice = item.unitPrice > 0;

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onTap(item),
                onLongPress: () => onLongPress(item),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_florist_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Spacer(),
                          if (item.category != 'General')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        item.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              hasPrice
                                  ? AppTheme.formatMoney(item.unitPrice)
                                  : 'Set price',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: hasPrice
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.add_circle,
                            color: theme.colorScheme.primary.withOpacity(0.85),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
