import 'package:nthaka_eco/models/sale.dart';

class SalesReportSummary {
  final double totalRevenue;
  final int saleCount;
  final double averageSale;

  const SalesReportSummary({
    required this.totalRevenue,
    required this.saleCount,
    required this.averageSale,
  });
}

class SalesDayTotal {
  final String dayKey;
  final double total;

  const SalesDayTotal({required this.dayKey, required this.total});
}

class TopSellingItem {
  final String name;
  final int quantity;
  final double revenue;

  const TopSellingItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

class SalesReportBundle {
  final SalesReportSummary summary;
  final List<SalesDayTotal> salesByDay;
  final List<TopSellingItem> topItems;
  final List<Sale> transactions;

  const SalesReportBundle({
    required this.summary,
    required this.salesByDay,
    required this.topItems,
    required this.transactions,
  });
}
