import 'package:flutter/material.dart';
import 'package:nthaka_eco/screens/sales/pos_screen.dart';
import 'package:nthaka_eco/screens/sales/sales_reports_screen.dart';
import 'package:nthaka_eco/screens/sales/view_sales_screen.dart';
import 'package:nthaka_eco/screens/sales/cash_up_screen.dart';

/// Sales hub: register-first POS with receipts in a second tab.
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales'),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                height: 48,
                icon: Icon(Icons.point_of_sale_outlined, size: 20),
                text: 'Register',
              ),
              Tab(
                height: 48,
                icon: Icon(Icons.receipt_long_outlined, size: 20),
                text: 'Receipts',
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Reports',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SalesReportsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.insights_outlined),
            ),
            IconButton(
              tooltip: 'Daily cash-up',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashUpScreen()),
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            PosScreen(embedded: true),
            ViewSalesScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
