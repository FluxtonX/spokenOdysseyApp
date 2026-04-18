import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';
import '../albums/album_detail_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final List<Map<String, dynamic>> _albums = [
    {
      'title': 'Monal Tour',
      'subtitle': 'Memories from my mountain journey',
      'entries': 12,
      'image': 'assets/images/onboarding_2.png',
      'memories': [
        {
          'title': 'Sunrise at the Summit',
          'description':
              'Woke up at 4AM, climbed for two hours to the peak. When the first light came — there are no words to describe it. Only silence, and awe.',
          'date': 'August 14, 2023',
          'tags': ['Awestruck'],
          'category': 'Public',
          'likes': 67,
          'comments': 3,
        },
        {
          'title': 'The Village Tea House',
          'description':
              'A remote shack at 3000 meters, run by a 70-year-old woman who smiled and communicated everything through warmth.',
          'date': 'August 15, 2023',
          'tags': ['Grateful'],
          'category': null,
          'likes': 34,
          'comments': 1,
        },
        {
          'title': 'Losing the Trail',
          'description':
              'Thick fog, a missing trail, a winding sightpath, and two wrong turns. Out getting lost revealed the valley that wasn\'t on any map.',
          'date': 'August 16, 2023',
          'tags': ['Adventurous'],
          'category': null,
          'likes': 52,
          'comments': 8,
        },
      ],
    },
    {
      'title': 'Career Milestones',
      'subtitle': 'Key moments in my professional journey',
      'entries': 8,
      'image': 'assets/images/onboarding_1.png',
      'memories': [
        {
          'title': 'The Day I Got My First Client',
          'description':
              'A single email that changed everything. "We\'d like to hire you!" I read it several times before I could believe it was real.',
          'date': 'March 15, 2020',
          'tags': ['Proud'],
          'category': 'Dramatic',
          'likes': 78,
          'comments': 5,
        },
        {
          'title': 'Featured in Forbes',
          'description':
              'The article narrative of an adult, by hope, felt sincere and honest. I couldn\'t believe I was the final piece.',
          'date': 'July 22, 2022',
          'tags': ['Heartfelt'],
          'category': null,
          'likes': 110,
          'comments': 2,
        },
        {
          'title': 'The Pitch That Almost Broke Me',
          'description':
              'My heart felt like exploding, way back in months later, we looked back and said, "absolutely a lesson."',
          'date': 'October 5, 2021',
          'tags': ['Resilient'],
          'category': null,
          'likes': 45,
          'comments': 7,
        },
      ],
    },
    {
      'title': 'Family Gatherings',
      'subtitle': 'Precious moments with loved ones',
      'entries': 24,
      'image': 'assets/images/onboarding_3.png',
      'memories': [
        {
          'title': 'The Last Morning with Grandma',
          'description':
              'The sun lit the living room and we sat there. We didn\'t know it would be the last, but she hugged me as she hugged me the first time and whispered.',
          'date': 'November 30, 2021',
          'tags': ['Bittersweet'],
          'category': 'Family',
          'likes': 93,
          'comments': 21,
        },
        {
          'title': 'Sophie\'s First Steps',
          'description':
              'Two extra tot steps before she sat down and laughed. A small moment to many, but to us, it felt like she had started walking. In that moment, she had.',
          'date': 'March 8, 2021',
          'tags': ['Joyful'],
          'category': 'Family',
          'likes': 110,
          'comments': 8,
        },
        {
          'title': 'Family Reunion 2023',
          'description':
              'Three generations under one roof. Laughter echoing through the halls like music. Everyone older, everyone wiser, everyone still us.',
          'date': 'December 6, 2023',
          'tags': ['Cherished'],
          'category': null,
          'likes': 89,
          'comments': 12,
        },
        {
          'title': 'Hiring My First Employee',
          'description':
              'I was terrified. She was brilliant. I trained her anyway. Watching her grow because as importantly, me grow, too.',
          'date': 'October 7, 2021',
          'tags': ['Reflective'],
          'category': null,
          'likes': 41,
          'comments': 3,
        },
      ],
    },
  ];

  void _showCreateAlbumDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create New Album',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Album Name field
                Text(
                  'Album Name',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., Summer 2024',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppTheme.textHint,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF5D5FEF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description field
                Text(
                  'Description (optional)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'What is this album about?',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppTheme.textHint,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF5D5FEF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: const Color(0xFF5D5FEF),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            if (nameController.text.trim().isNotEmpty) {
                              setState(() {
                                _albums.add({
                                  'title': nameController.text.trim(),
                                  'subtitle': descController.text.trim().isEmpty
                                      ? 'A collection of memories'
                                      : descController.text.trim(),
                                  'entries': 0,
                                  'image': 'assets/images/onboarding_1.png',
                                  'memories': <Map<String, dynamic>>[],
                                });
                              });
                              Navigator.pop(context);
                              // Show success snackbar
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Color(0xFF5ABA82),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Album created successfully',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF5ABA82),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: Text(
                              'Create Album',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Albums',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Curated collections of your memories',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showCreateAlbumDialog,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D5FEF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Albums List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _albums
                      .map((album) => _buildAlbumCard(album))
                      .toList(),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => AlbumDetailScreen(album: album),
          transition: Transition.cupertino,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  Image.asset(
                    album['image'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Dark gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Entries badge
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
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
                  // Folder icon
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
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
            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
      ),
    );
  }
}
