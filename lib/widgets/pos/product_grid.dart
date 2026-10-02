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
    if (products.isEmpty) {
      return Center(
        child: Text(
          'No products in this category.\nAdd items under the Items tab.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
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
            childAspectRatio: 0.95,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final item = products[index];
            return Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onTap(item),
                onLongPress: () => onLongPress(item),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 36,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        item.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        item.unitPrice > 0
                            ? item.unitPrice.toStringAsFixed(2)
                            : 'Set price',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
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
