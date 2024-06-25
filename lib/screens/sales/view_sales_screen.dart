import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nthaka_eco/global/widgets/app_styles.dart';

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({Key? key}) : super(key: key);

  @override
  _ViewSalesScreenState createState() => _ViewSalesScreenState();
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  String searchQuery = '';
  String selectedDateFilter = 'All';
  String selectedSalesperson = 'All';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Styles.bgcolor,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sales',
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
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: const Text(
                          'New Sales >',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
      
                const SizedBox(height: 20.0),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    // Remove the border property entirely
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: selectedDateFilter,
                      onChanged: (value) {
                        setState(() {
                          selectedDateFilter = value!;
                        });
                      },
                      items: <String>['All', 'Today', 'This Week', 'This Month']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    DropdownButton<String>(
                      value: selectedSalesperson,
                      onChanged: (value) {
                        setState(() {
                          selectedSalesperson = value!;
                        });
                      },
                      items: <String>['All', 'Isaac Manganda', 'John Doe', 'Jane Smith']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                OverviewCard(
                  title: 'Sale tit',
                  details: const {
                    'Sale By': 'Isaac Manganda',
                    'Qty.': '10',
                    'Total Amount': '2000',
                    'Sale Date': '02 May 2024',
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4.0,
            spreadRadius: 0.0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              padding: const EdgeInsets.only(bottom: 1.0),
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
