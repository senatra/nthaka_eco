import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'package:nthaka_eco/main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userData;
  late Future<Map<String, dynamic>> _userDiseaseData;

  @override
  void initState() {
    super.initState();
    _userData = _getCurrentUser();
    _userDiseaseData = _getDiseaseData();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
    }
    throw 'User Data not found';
  }
  Future<Map<String, dynamic>> _getDiseaseData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('disease_reports')
              .where('userId', isEqualTo: user.uid)
              .get();

      int totalReports = querySnapshot.size;
      // double totalConfidence = 0.0;

      Map<String, int> diseaseCount = {};

      querySnapshot.docs.forEach((doc) {
        // totalConfidence += doc['confidence'] ?? 0.0;

        // Count occurrences of each disease
        String diseaseName = doc['disease'];
        if (diseaseCount.containsKey(diseaseName)) {
          diseaseCount[diseaseName] = diseaseCount[diseaseName]! + 1;
        } else {
          diseaseCount[diseaseName] = 1;
        }
      });

      // double averageConfidence = totalReports > 0
      //     ? totalConfidence / totalReports
      //     : 0.0;

      // Find the most common disease
      String mostCommonDisease = '';
      String mostCommonPlant = '';
      int maxOccurrences = 0;

      diseaseCount.forEach((disease, count) {
        if (count > maxOccurrences) {
          maxOccurrences = count;
          mostCommonDisease = disease;
        }
      });
       diseaseCount.forEach((plant, count) {
        if (count > maxOccurrences) {
          mostCommonPlant = plant;
        }
      });

      return {
        'totalReports': totalReports,
        // 'averageConfidence': averageConfidence,
        'mostCommonDisease': mostCommonDisease,
        'mostCommonPlant': mostCommonPlant,
      };
    }
    throw 'User not found';
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  
      body:
      
       Column(
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
                            'My Profile',
                            // style: Styles.headLineStyle3,
                          ),
                          const Gap(5),
                          Text(
                            "Nthaka",
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
                            onPressed: _signOut,
                            backgroundColor: Colors.red,
                          child: const Icon(Icons.logout),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
         FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _userData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Text('Error: Check Internet Connection');
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('User data not available');
            } else {
              
              Map<String, dynamic> userData = snapshot.data!.data()!;
              String firstName = userData['firstName'] ?? '';
              String lastName = userData['lastName'] ?? '';
              String email = FirebaseAuth.instance.currentUser?.email ?? '';
              return Column(
                
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text('$firstName $lastName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Email: $email'),
            
                ],
              );
            }
          },
        ),
          const SizedBox(height: 20),
FutureBuilder<Map<String, dynamic>>(
  future: _userDiseaseData,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text('Please Wait...'); // Placeholder while fetching data
    } else if (snapshot.hasError) {
      return const Text('Error: Check Internet Connection');
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Text('No data available'); // Handle case when no data is returned
    } else {
      Map<String, dynamic> analyticsData = snapshot.data!;

      // Function to build Total Reports Card
      Card buildTotalReportsCard(int totalReports) {
        return Card(
          margin: const EdgeInsets.all(10.0),
          elevation: 4.0,
          child: ListTile(
            title: const Text(
              'Total:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$totalReports',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        );
      }

      // Function to build Most Common Disease Card
      Card buildMostCommonDiseaseCard(String mostCommonDisease) {
        return Card(
          margin: const EdgeInsets.all(10.0),
          elevation: 4.0,
          child: ListTile(
            title: const Text(
              'Most Common:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$mostCommonDisease',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        );
      }

      // Create cards using the retrieved data
      Card totalReportsCard = buildTotalReportsCard(analyticsData['totalReports']);
      Card mostCommonDiseaseCard = buildMostCommonDiseaseCard(analyticsData['mostCommonDisease']);

      // Return a widget that uses these cards in your UI layout
      return Column(
        children: [
          totalReportsCard,
          mostCommonDiseaseCard,
          // Add more cards or widgets as needed
        ],
      );
    }
  },
),

        ],

      ),
    );
  }
}
