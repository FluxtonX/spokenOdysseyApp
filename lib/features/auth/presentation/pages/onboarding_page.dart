import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';

class OnboardingItem {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      imagePath: AssetConstants.onboarding1,
      title: 'Capture life as it unfolds.',
      description:
          'Voice recordings that reflect your truth — not performance.',
    ),
    OnboardingItem(
      imagePath: AssetConstants.onboarding2,
      title: 'Record at your pace.',
      description: 'Daily, weekly, monthly, or whenever you choose.',
    ),
    OnboardingItem(
      imagePath: AssetConstants.onboarding3,
      title: 'Private by design.',
      description: 'Control who hears your story.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/sign-in');
                },
                child: Text(
                  'Skip',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                item.imagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 80,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _items.length,
                            (dotIndex) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: _currentIndex == dotIndex ? 28 : 12,
                              decoration: BoxDecoration(
                                color: _currentIndex == dotIndex
                                    ? AppColors.primary
                                    : AppColors.indicatorInactive,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentIndex < _items.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, '/sign-in');
                  }
                },
                child: Text(
                  _currentIndex == _items.length - 1 ? 'Get Started' : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
