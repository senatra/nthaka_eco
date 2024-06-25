import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nthaka_eco/components/colors.dart';
import 'package:nthaka_eco/screens/authentication/login_screen.dart';
import 'package:nthaka_eco/screens/authentication/register_screen.dart';

// OnBoarding content Model
class OnboardingScreen {
  final String image, title, description;

  OnboardingScreen({
    required this.image,
    required this.title,
    required this.description,
  });
}

// OnBoarding content list
final List<OnboardingScreen> demoData = [
  OnboardingScreen(
    image: "assets/images/onboarding/slider1.png",
    title: "Title 01",
    description:"Welcome to Nthaka.Eco!",
  ),
  OnboardingScreen(
    image: "assets/images/onboarding/slider2.png",
    title: "Title 02",
    description:
        "Intuitive tools for time management, you'll effortlessly organize your tasks, schedules, and activities",
  ),
  // OnboardingScreen(
  //   image: "assets/images/onboarding/slider3.png",
  //   title: "Title 03",
  //   description:
  //       "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  // ),
];

// OnBoardingScreen
class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  // Variables
  late PageController _pageController;
  int _pageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize page controller
    _pageController = PageController(initialPage: 0);
    // Automatic scroll behaviour
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageIndex < 3) {
        _pageIndex++;
      } else {
        _pageIndex = 0;
      }

      _pageController.animateToPage(
        _pageIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    // Dispose everything
    _pageController.dispose();
    _timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        // Background gradient
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF)
        ),
        child: Column(
          children: [
            // Carousel area
            Expanded(
              child: PageView.builder(
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                itemCount: demoData.length,
                controller: _pageController,
                itemBuilder: (context, index) => OnBoardContent(
                  title: demoData[index].title,
                  description: demoData[index].description,
                  image: demoData[index].image,
                ),
              ),
            ),
            // Indicator area
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    demoData.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: DotIndicator(
                        isActive: index == _pageIndex,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Privacy policy area
            const Text("Revolutionizing Plant Health",
             style: TextStyle(
             color: Colors.black,
             fontSize: 15,
                    ),),

            // White space
            const SizedBox(
              height: 10,
            ),
            // Button area
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: Get.height * 0.06,
                width: Get.width,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    "Register",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
                       
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 48),
                height: Get.height * 0.06,
                width: Get.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kPrimaryColor), // Assuming kPrimary is a Color
            ),
                child: const Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
                   

          ],
        ),
      ),
    );
  }
}

// OnBoarding area widget
// ignore: must_be_immutable
class OnBoardContent extends StatelessWidget {
  OnBoardContent({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  String image;
  String title;
  String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),

        const Spacer(),
        Image.asset(image),
        const Spacer(),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// Dot indicator widget
class DotIndicator extends StatelessWidget {
  const DotIndicator({
    this.isActive = false,
    super.key,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? kPrimaryColor : Colors.white,
        border: isActive ? null : Border.all(color: kPrimaryColor),
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
    );
  }
}