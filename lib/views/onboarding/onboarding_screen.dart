import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../authScreen/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Capture life as it\nunfolds.',
      'description':
          'Voice recordings that reflect your\ntruth — not performance.',
      'image': 'assets/images/onboarding_1.png',
    },
    {
      'title': 'Record at your pace.',
      'description': 'Daily, weekly, monthly, or whenever\nyou choose.',
      'image': 'assets/images/onboarding_2.png',
    },
    {
      'title': 'Private by design.',
      'description': 'Control who hears your story.',
      'image': 'assets/images/onboarding_3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Skip button)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Get.offAll(() => const LoginScreen());
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 0.0;
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                      } else {
                        // Fallback before PageController gets dimensions
                        value = (_currentIndex == index) ? 0.0 : 1.0;
                      }

                      // Calculate scale for the active item vs inactive items
                      double scale = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
                      // Calculate opacity for the text content so it fades out as it slides away
                      double opacity = (1 - (value.abs() * 2.0)).clamp(
                        0.0,
                        1.0,
                      );

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Oval Image
                            Expanded(
                              flex: 5,
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  width: double.infinity,
                                  child: ClipOval(
                                    child: Image.asset(
                                      onboardingData[index]['image']!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Page Indicator (Dashes)
                            Opacity(
                              opacity: opacity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  onboardingData.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    height: 3,
                                    width: index == i ? 24 : 16,
                                    decoration: BoxDecoration(
                                      color: index == i
                                          ? Colors.black
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Title
                            Opacity(
                              opacity: opacity,
                              child: Text(
                                onboardingData[index]['title']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Subtitle
                            Opacity(
                              opacity: opacity,
                              child: Text(
                                onboardingData[index]['description']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                            ),

                            const Spacer(flex: 1),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Floating Next Button
            Padding(
              padding: const EdgeInsets.only(right: 32, bottom: 32),
              child: Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton(
                  backgroundColor: Colors.black,
                  heroTag: 'onboarding_fab',
                  elevation: 0,
                  onPressed: () {
                    if (_currentIndex < onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Get.offAll(() => const LoginScreen());
                    }
                  },
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
