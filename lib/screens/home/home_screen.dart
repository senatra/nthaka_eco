import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nthaka_eco/components/colors.dart';
import 'package:nthaka_eco/global/widgets/app_layout.dart';
import 'package:nthaka_eco/global/widgets/app_styles.dart';
import 'package:nthaka_eco/screens/home/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String greeting = '';
  List<String> crops = ['Maize', 'Tomato', 'Cassava', 'Cashew'];
  List<String> displayedCrops = [];

  @override
  void initState() {
    super.initState();
    greeting = AppLayout.getGreeting();
    displayedCrops = crops;
  }

  void _filterCrops(String query) {
    query = query.toLowerCase();
    setState(() {
      displayedCrops = crops.where((crop) => crop.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Material(
        child: ListView(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Home",
                      style: Styles.headLineStyle,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const ProfilePage()),
                        );
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Image(
                          image: AssetImage('assets/images/app/nthakalogo.png'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOtherColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 50.0),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.thermostat,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                '36.7 °C',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Features:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(FluentSystemIcons.ic_fluent_leaf_two_filled, color: Colors.black, size: 30.0,),
                      
                          label: const Text('Plant Disease Detection', style: TextStyle(fontSize: 18, color: Colors.black,)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 45.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                     Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  FluentSystemIcons.ic_fluent_book_number_filled,
                  color: Colors.black,
                  size: 30.0,
                ),
                label: const Text(
                  'Inventory',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30.0),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  FluentSystemIcons.ic_fluent_pen_settings_filled,
                  color: Colors.black,
                  size: 30.0,
                ),
                label: const Text(
                  'Management',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  FluentSystemIcons.ic_fluent_bank_filled,
                  color: Colors.black,
                  size: 30.0,
                ),
                label: const Text(
                  'Sales & Purchases',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30.0),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  FluentSystemIcons.ic_fluent_location_filled,
                  color: Colors.black,
                  size: 30.0,
                ),
                label: const Text(
                  'Statistics',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30.0),
                ),
              ),
            ),
          ],
        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
