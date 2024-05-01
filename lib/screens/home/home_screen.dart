import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nthaka_eco/global/widgets/app_layout.dart';
import 'package:nthaka_eco/screens/home/profile_screen.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String greeting = '';
  final TextEditingController _searchController = TextEditingController();
  List<String> crops = ['Maize', 'Tomato', 'Cassava', 'Cashew'];
  List<String> displayedCrops = [];

  @override
  void initState() {
    displayedCrops = crops;
    super.initState();
    greeting = AppLayout.getGreeting();
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
      child: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                const Gap(25),

          Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            // style: Styles.headLineStyle3,
                          ),
                          const Gap(5),
                          Text(
                            "My Home",
                            // style: Styles.headLineStyle,
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: FloatingActionButton(
                            onPressed: () {
                               Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                                );
                            },
                            backgroundColor: Colors.green,
                            child: const Image(
                              image: AssetImage('assets/images/logo.png'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          TextFormField(
            controller: _searchController,
            onChanged: _filterCrops,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search Plants',
              contentPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1,
              vertical: 15, 
            ),
            ),
          ),
        ],
      ),
    ),

        const SizedBox(height: 15),
        const Padding(
        padding: EdgeInsets.all(15.0), 
        child: Row(
          children: [
            Text(
              'Select Your Crop:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
          ),
      ),
    ListView.builder(
      shrinkWrap: true,
      itemCount: displayedCrops.length,
      itemBuilder: (context, index) {
      return Column(
      children: [
      //   Padding(
      //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      //     child: ElevatedButton(
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => Pdd(plant: displayedCrops[index])),
      //         );
      //       },
      //       style: ElevatedButton.styleFrom(
      //         backgroundColor: Styles.primaryColor, // Change color as needed
      //         padding:  const EdgeInsets.all(15.0),
      //       ),
      //       child: Row(
      //         children: [
      //           Padding(
      //             padding: const EdgeInsets.all(8.0),
      //             child: Image.asset(
      //               'assets/images/${displayedCrops[index].toLowerCase()}.png',
      //               width: 40,
      //               height: 40,
      //             ),
      //           ),
      //           Text(displayedCrops[index],  
      //           style: const TextStyle(
      //           color: Colors.black, // Set the text color here
      //           fontSize: 16, // Adjust the font size as needed
      //           fontWeight: FontWeight.bold, // Set the font weight as needed
      //         ),
      //         ),
      //         ],
      //       ),
      //     ),
      //   ),
      ],
    );
  },
),
],
),
),
);
}
}