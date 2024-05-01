  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:nthaka_eco/screens/authentication/login_screen.dart';
  import 'package:nthaka_eco/screens/onboarding/onboarding_screen.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    Platform.isAndroid ?
    await Firebase.initializeApp(
      options: const FirebaseOptions(
      apiKey: 'AIzaSyB11TJAZtMDSIgBL3Q1_81svd_rx8SUWkg',
      appId: '1:977014501663:android:073abe2a9cb856d495c02a',
      messagingSenderId: '977014501663', 
      projectId: 'nthaka-eco',)
    )
    :
    await Firebase.initializeApp()
    ;
    runApp(MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Nthaka.Eco',
        debugShowCheckedModeBanner: false,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final User? user = snapshot.data;
              return user != null ? const LoginScreen() : const OnBoardingScreen();
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      );
    }
  }
