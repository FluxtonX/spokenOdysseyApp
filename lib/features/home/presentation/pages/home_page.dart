import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Spoken Odyssey',
          style: GoogleFonts.outfit(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              context.read<AuthCubit>().signOut();
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to your Legacy',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record your voice memories and share them securely with your family circle.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Record Memory',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio Recording Studio Ready!'),
                      ),
                    );
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Tap to start recording',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Recent Audio Stories',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.indicatorInactive,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  index == 0
                                      ? 'My Childhood Memories'
                                      : 'Advice for Future Generations',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  index == 0
                                      ? 'Recorded 2 days ago • 3 min 45 sec'
                                      : 'Recorded last week • 5 min 12 sec',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none_rounded),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
