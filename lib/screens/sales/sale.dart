import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nthaka_eco/api/sale_api_service.dart';
import 'package:nthaka_eco/components/colors.dart';
import 'package:nthaka_eco/global/widgets/app_layout.dart';
import 'package:nthaka_eco/global/widgets/app_styles.dart';
import 'package:nthaka_eco/screens/home/profile_screen.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late Future<List<Sale>> _sales;

  @override
  void initState() {
    super.initState();
    _sales = SalesApiService().getSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Management'),
      ),
      body: FutureBuilder<List<Sale>>(
        future: _sales,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No sales available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Sale sale = snapshot.data![index];
                return ListTile(
                  title: Text('Sale ${sale.id}'),
                  subtitle: Text('Total Amount: \$${sale.totalAmount}'),
                  onTap: () {
                    // Navigate to detailed view or edit screen
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to a screen for creating a new sale
        },
        child: Icon(Icons.add),
      ),
    );
  }
}