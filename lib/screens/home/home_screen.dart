import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nthaka_eco/global/widgets/app_styles.dart';
import 'package:nthaka_eco/screens/sales/view_sales_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Styles.bgcolor,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Nthaka.Eco',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  image: DecorationImage(
                    image: AssetImage('assets/images/app/nthakalogo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ViewSalesScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          
                        ),
                        child: const Text('Sales >', style: TextStyle( fontWeight: FontWeight.bold),),
                      ),
                    ),
                    const Gap(20.0),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: const Text('Purchases >', style: TextStyle( fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: const Text('PDD >', style: TextStyle( fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Gap(20.0),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: const Text('Record Activity >', style: TextStyle( fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                OverviewCard(
                  title: 'Sales Overview',
                  details: const {
                    'Total Sales': '900',
                    'Revenue': '20000',
                    'Profit': '15000',
                  },
                  onViewDetails: () {},
                ),
                const SizedBox(height: 16.0),
                OverviewCard(
                  title: 'Purchases Overview',
                  details: const {
                    'No. of Purchases': '20',
                    'Cost': '5000',
                    'Profit': '15000',
                  },
                  onViewDetails: () {},
                ),
                const SizedBox(height: 16.0),
                OverviewCard(
                  title: 'Inventory Overview',
                  details: const {
                    'Item Groups': '10',
                    'Low Stock': '5',
                    'Total Items': '10000',
                  },
                  onViewDetails: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class OverviewCard extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final VoidCallback onViewDetails;

  const OverviewCard({Key? key, required this.title, required this.details, required this.onViewDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4.0, spreadRadius: 0.0)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.entries.map((entry) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 5.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 1.0), // Add bottom padding
              child: TextButton(
                onPressed: onViewDetails,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.bottomRight,
                  
                ),
                child: Text(
                  'View Details >',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                        textAlign: TextAlign.right,

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
