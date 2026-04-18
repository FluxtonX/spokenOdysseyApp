import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';
import '../memories/memory_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTabIndex = 0;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isFromCalendarOpen = false;
  bool _isToCalendarOpen = false;

  final List<Map<String, dynamic>> _memories = [
    {
      'title': 'The Day I Started My Own Business',
      'description':
          'After years of working for others, I finally took the leap. The fear was real, but so was the excitement. I remember sitting in my...',
      'tags': ['Proud', 'Career & Growth'],
      'category': 'Turning Point',
      'date': 'March 15, 2020',
      'icon': Icons.public,
    },
    {
      'title': 'Morning Coffee with Dad',
      'description':
          'We sat on the porch as the sun rose. He told me stories about his grandfather I had never heard before. Simple moments like these...',
      'tags': ['Grateful', 'Family Moments'],
      'category': null,
      'date': 'July 22, 2023',
      'icon': Icons.park_outlined,
    },
    {
      'title': 'Conquering My First Marathon',
      'description':
          'Mile 20 hit me like a wall. My legs screamed to stop. But I thought of everyone who believed in me, and I kept going. Cross...',
      'tags': ['Joyful', 'Health & Wellness'],
      'category': 'Milestone',
      'date': 'November 5, 2022',
      'icon': Icons.public,
    },
    {
      'title': 'A Quiet Evening of Reflection',
      'description':
          'Sometimes the most profound moments are the quietest ones. Tonight, I sat by the window and realized how far I have co...',
      'tags': ['Peaceful', 'Personal Growth'],
      'category': null,
      'date': 'January 30, 2024',
      'icon': Icons.wb_sunny_outlined,
    },
  ];

  final List<Map<String, dynamic>> _albums = [
    {
      'title': 'Monal Tour',
      'subtitle': 'Memories from my mountain journey',
      'entries': 12,
      'image': 'assets/images/onboarding_2.png',
    },
    {
      'title': 'Family Reunion',
      'subtitle': 'The annual gathering in Portland',
      'entries': 24,
      'image': 'assets/images/onboarding_1.png',
    },
    {
      'title': 'Career Milestones',
      'subtitle': 'My professional growth journey',
      'entries': 8,
      'image': 'assets/images/onboarding_2.png',
    },
  ];

  void _showImagePicker(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload a new photo from your device or take a fresh picture.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take a Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  bool _isFilterApplied = false;
  List<String> _selectedMoods = [];
  String _selectedVisibility = 'All';

  final List<String> _moodOptions = [
    'Joyful',
    'Grateful',
    'Reflective',
    'Hopeful',
    'Challenging',
    'Loving',
    'Proud',
    'Peaceful',
  ];

  Widget _buildFilterAppliedBanner() {
    if (!_isFilterApplied) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4EE), // Light green from Figma
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF5ABA82),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'Filters applied',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E4D34),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _isFilterApplied = false;
                _selectedMoods = [];
                _selectedVisibility = 'All';
                _fromDate = null;
                _toDate = null;
              });
            },
            child: const Icon(Icons.close, size: 20, color: Color(0xFF1E4D34)),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildFilterHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateRangeSection(setModalState),
                          const SizedBox(height: 32),
                          _buildMoodSection(setModalState),
                          const SizedBox(height: 32),
                          _buildVisibilitySection(setModalState),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  _buildFilterActions(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Advanced Filters',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildDateInput(
                    'From',
                    _fromDate != null
                        ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                        : 'dd/mm/yy',
                    () {
                      setModalState(() {
                        _isFromCalendarOpen = !_isFromCalendarOpen;
                        _isToCalendarOpen = false;
                      });
                    },
                    _isFromCalendarOpen,
                  ),
                  if (_isFromCalendarOpen)
                    _buildInlineCalendar(_fromDate ?? DateTime.now(), (date) {
                      setModalState(() {
                        _fromDate = date;
                        _isFromCalendarOpen = false;
                      });
                    }),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildDateInput(
                    'To',
                    _toDate != null
                        ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                        : 'dd/mm/yy',
                    () {
                      setModalState(() {
                        _isToCalendarOpen = !_isToCalendarOpen;
                        _isFromCalendarOpen = false;
                      });
                    },
                    _isToCalendarOpen,
                  ),
                  if (_isToCalendarOpen)
                    _buildInlineCalendar(_toDate ?? DateTime.now(), (date) {
                      setModalState(() {
                        _toDate = date;
                        _isToCalendarOpen = false;
                      });
                    }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateInput(
    String label,
    String value,
    VoidCallback onTap,
    bool isOpen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOpen
                    ? const Color(0xFF5D5FEF)
                    : const Color(0xFFE5E7EB),
                width: isOpen ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: value == 'dd/mm/yy'
                        ? AppTheme.textHint
                        : AppTheme.textPrimary,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineCalendar(
    DateTime initialDate,
    Function(DateTime) onSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF5D5FEF),
            onPrimary: Colors.white,
            onSurface: AppTheme.textPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5D5FEF),
            ),
          ),
        ),
        child: CalendarDatePicker(
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          onDateChanged: onSelected,
        ),
      ),
    );
  }

  Widget _buildMoodSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _moodOptions.map((mood) {
            final isSelected = _selectedMoods.contains(mood);
            return GestureDetector(
              onTap: () {
                setModalState(() {
                  if (isSelected) {
                    _selectedMoods.remove(mood);
                  } else {
                    _selectedMoods.add(mood);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5D5FEF)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mood,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisibilitySection(StateSetter setModalState) {
    final options = ['All', 'Public', 'Family', 'Private'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: options.map((option) {
              final isSelected = _selectedVisibility == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setModalState(() {
                      _selectedVisibility = option;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedMoods = [];
                  _selectedVisibility = 'All';
                  _fromDate = null;
                  _toDate = null;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Reset',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isFilterApplied = true;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D5FEF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    const coverHeight = 200.0;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Container(
                height: coverHeight,
                width: double.infinity,
                color: const Color(0xFF9FB8D1),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/onboarding_2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () =>
                            _showImagePicker(context, 'Change Cover Photo'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Change Cover',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sarah Mitchell',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D5FEF),
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Edit Profile',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Entrepreneur & Author',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Portland, OR',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.cake_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Born March 1985',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Documenting my journey from small-town dreamer to business owner, mother, and lifelong learner. Every challenge taught me resilience, every joy reminded me to be grateful.',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        height: 1.6,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Life Motto',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '“Live intentionally, love deeply, leave a legacy of kindness.”',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Areas of Expertise',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChip('Entrepreneurship', const Color(0xFF5D5FEF)),
                        _buildChip('Parenting', const Color(0xFFE2923A)),
                        _buildChip('Wellness', const Color(0xFF5ABA82)),
                        _buildChip('Creative Writing', const Color(0xFF916CD3)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        _buildStatCard('127', 'Memories'),
                        const SizedBox(width: 12),
                        _buildStatCard('18', 'Milestones'),
                        const SizedBox(width: 12),
                        _buildStatCard('342', 'Followers'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D5FEF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF5D5FEF).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '“Changing The Way We Preserve Our Legacy”',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF5D5FEF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: coverHeight - 50,
          left: 20,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFFF3F4F6),
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800&auto=format&fit=crop',
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D5FEF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF5D5FEF)
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF5D5FEF) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.asset(
                  album['image'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Overlay for better icon visibility if needed
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Entries Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${album['entries']} entries',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Folder Icon Badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      size: 20,
                      color: Color(0xFF5D5FEF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Album Text Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album['title'],
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  album['subtitle'],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> memory) {
    return InkWell(
      onTap: () => Get.to(() => MemoryDetailScreen(memory: memory)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memory['category'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D5FEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  memory['category'],
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              memory['title']!,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              memory['description']!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (memory['tags'] as List<String>).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D5FEF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D5FEF),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    memory['date']!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    memory['icon'] as IconData,
                    size: 16,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'home_fab',
        backgroundColor: const Color(0xFF5D5FEF),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton('All Memories', 0),
                          const SizedBox(width: 32),
                          _buildTabButton('Albums', 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search memories...',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textHint,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: InkWell(
                        onTap: _showFilterBottomSheet,
                        borderRadius: BorderRadius.circular(28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.tune,
                              color: AppTheme.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Advanced Filters',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFilterAppliedBanner(),
                    if (_activeTabIndex == 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '4 memories',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5D5FEF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.grid_view_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.list_rounded,
                                size: 24,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.folder_open_rounded,
                                size: 22,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ..._memories.map(_buildMemoryCard),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '3 albums',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ..._albums.map(_buildAlbumCard),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
