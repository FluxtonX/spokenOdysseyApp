import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../customWidgets/custom_search_field.dart';
import '../../customWidgets/custom_tab_selector.dart';
import '../../customWidgets/person_card.dart';
import '../../theme/theme.dart';
import 'person_detail_screen.dart';
import 'package:get/get.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final List<Map<String, dynamic>> _mockPeople = [
    {
      'name': 'Admiral Grace Hopper',
      'role': 'Computer Scientist & Naval Officer',
      'description':
          'Pioneer of computer programming who developed the first compiler',
      'followers': '45,200',
      'bgImage':
          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop',
    },
    {
      'name': 'Nelson Mandela',
      'role': 'Revolutionary & President',
      'description':
          '27 years imprisoned, emerged to lead a nation toward reconciliation',
      'followers': '128,000',
      'bgImage':
          'https://images.unsplash.com/photo-1542204165-65bf26472b9b?q=80&w=2574&auto=format&fit=crop',
      'avatar':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=800&auto=format&fit=crop',
    },
    {
      'name': 'Maya Angelou',
      'role': 'Poet & Activist',
      'description': 'Her words lifted generations, turning pain into poetry',
      'followers': '97,500',
      'bgImage':
          'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2670&auto=format&fit=crop',
      'avatar':
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Typography
              Text(
                'Extraordinary\nLives',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Step into the archives of those who shaped our world, one story at a time',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Search Bar
              const CustomSearchField(hintText: 'Search by name, profes...'),
              const SizedBox(height: 32),

              // Segmented Tab
              CustomTabSelector(
                tabs: const ['Featured People', 'Latest Stories'],
                onTabChanged: (index) {
                  // handle tab switch
                },
              ),
              const SizedBox(height: 32),

              // List of People Cards
              ..._mockPeople.map((person) {
                return PersonCard(
                  bgImageUrl: person['bgImage'],
                  avatarUrl: person['avatar'],
                  name: person['name'],
                  role: person['role'],
                  description: person['description'],
                  followersCount: person['followers'],
                  onFollowTrigger: () {},
                  onTap: () => Get.to(() => PersonDetailScreen(person: person)),
                );
              }),
            ],
          ),
        ),
      ),

      // Floating Plus Button Overlay
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'discover_fab',
        backgroundColor: AppTheme.floatingActionButton,
        foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 4,
        child: const Icon(Icons.add, color: AppTheme.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
