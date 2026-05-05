import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../customWidgets/custom_text_field.dart';
import '../../services/profile_service.dart';
import '../../theme/theme.dart';
import '../../utils/image_picker_helper.dart';
import '../tabs/main_tab_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, this.initialProfile});

  final Map<String, dynamic>? initialProfile;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with TickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final AnimationController _animController;
  late final AnimationController _borderAnimController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  bool _isSaving = false;
  String _defaultPrivacy = 'Private - Only by you';
  File? _profileImageFile;
  String? _existingPhotoUrl;

  final List<Map<String, dynamic>> _privacyOptions = const [
    {
      'value': 'Private - Only by you',
      'icon': Icons.lock_outline_rounded,
      'label': 'Private',
      'desc': 'Only you',
    },
    {
      'value': 'Family - Your family circle',
      'icon': Icons.family_restroom_outlined,
      'label': 'Family',
      'desc': 'Your circle',
    },
    {
      'value': 'Public - Everyone',
      'icon': Icons.public_outlined,
      'label': 'Public',
      'desc': 'Everyone',
    },
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile ?? const <String, dynamic>{};

    _displayNameController = TextEditingController(
      text: profile['displayName']?.toString() ?? '',
    );
    _bioController = TextEditingController(
      text: profile['bio']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: profile['location']?.toString() ?? '',
    );
    _defaultPrivacy =
        profile['defaultEntryPrivacy']?.toString().trim().isNotEmpty == true
        ? profile['defaultEntryPrivacy'].toString()
        : _defaultPrivacy;
    _existingPhotoUrl = profile['photoURL']?.toString();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _borderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _animController.dispose();
    _borderAnimController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileImageFile == null &&
        !(_existingPhotoUrl?.trim().isNotEmpty ?? false)) {
      Get.snackbar(
        'Add a profile photo',
        'Choose a profile photo before you continue into the app.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _profileService.updateProfile({
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'defaultEntryPrivacy': _defaultPrivacy,
        'onboardingCompleted': true,
        'profileCompleted': true,
      }, profileImageFile: _profileImageFile);

      if (!mounted) return;
      Get.offAll(() => const MainTabScreen(initialIndex: 0));
      Get.snackbar(
        'Archive ready',
        'Your profile is saved. You can start recording your first memory now.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Could not save profile',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final file = await ImagePickerHelper.pickWithSourceSheet(context);
    if (file == null) return;

    setState(() {
      _profileImageFile = file;
      _existingPhotoUrl = null;
    });
  }

  bool get _hasPhoto =>
      _profileImageFile != null ||
      (_existingPhotoUrl?.trim().isNotEmpty ?? false);

  int get _completionSteps {
    int steps = 0;
    if (_hasPhoto) steps++;
    if (_displayNameController.text.trim().isNotEmpty) steps++;
    if (_bioController.text.trim().isNotEmpty) steps++;
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final accentColor = isDark ? const Color(0xFF8B7BFF) : AppTheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.adaptiveScaffoldBg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: CustomScrollView(
            slivers: [
              // ── Top header area ──
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress bar
                        _buildProgressBar(accentColor),
                        const SizedBox(height: 28),
                        // Title section
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppTheme.logoGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete your profile',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.adaptiveTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Step 3 of 3 · Almost there',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.adaptiveTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Set up your identity and privacy defaults before you start recording memories.',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            height: 1.55,
                            color: AppTheme.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Form content ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile Photo Section ──
                        _buildPhotoSection(accentColor, isDark),
                        const SizedBox(height: 28),

                        // ── Personal Details Section ──
                        _buildSectionHeader(
                          icon: Icons.badge_outlined,
                          title: 'Personal Details',
                          color: accentColor,
                        ),
                        const SizedBox(height: 16),
                        _buildFormCard(
                          isDark: isDark,
                          child: Column(
                            children: [
                              CustomTextField(
                                label: 'Display Name',
                                controller: _displayNameController,
                                prefixIcon: Icons.person_outline,
                                hintText:
                                    'How should your archive address you?',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your display name';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                label: 'Short Bio',
                                controller: _bioController,
                                prefixIcon: Icons.auto_stories_outlined,
                                hintText: 'A short line about who you are',
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please add a short bio';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                label: 'Location',
                                controller: _locationController,
                                prefixIcon: Icons.place_outlined,
                                hintText: 'City, country, or a place like home',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Privacy Section ──
                        _buildSectionHeader(
                          icon: Icons.shield_outlined,
                          title: 'Default Privacy',
                          color: accentColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'New memories will default to this setting. You can change it per entry.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.adaptiveTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildPrivacySelector(accentColor, isDark),
                        const SizedBox(height: 28),

                        // ── Family Invite Card ──
                        _buildFamilyCard(isDark),
                        const SizedBox(height: 32),

                        // ── Save Button ──
                        _buildSaveButton(accentColor),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progress Bar ──
  Widget _buildProgressBar(Color accentColor) {
    final progress = _completionSteps / 3.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$_completionSteps of 3 completed',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppTheme.adaptiveBorder,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      ],
    );
  }

  // ── Photo Section ──
  Widget _buildPhotoSection(Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _hasPhoto
              ? accentColor.withValues(alpha: 0.3)
              : AppTheme.adaptiveBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12).withValues(
              alpha: 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with animated gradient border
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _borderAnimController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _GradientBorderPainter(
                        rotation: _borderAnimController.value * 6.2832,
                        gradientColors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.4),
                          const Color(0xFFE2923A),
                          const Color(0xFF5ABA82),
                          accentColor,
                        ],
                        strokeWidth: 3.0,
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(3.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.adaptiveCardBg,
                        gradient: _hasPhoto
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor.withValues(alpha: 0.12),
                                  accentColor.withValues(alpha: 0.04),
                                ],
                              ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _profileImageFile != null
                          ? Image.file(_profileImageFile!, fit: BoxFit.cover)
                          : (_existingPhotoUrl?.trim().isNotEmpty ?? false)
                          ? Image.network(
                              _existingPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildInitialsAvatar(accentColor),
                            )
                          : _buildInitialsAvatar(accentColor),
                    ),
                  ),
                ),
                // Camera badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.adaptiveCardBg,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_hasPhoto)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      _hasPhoto ? 'Photo added' : 'Add a profile photo',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Give your archive a face. You can change it later from Settings.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Upload / Change button
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _hasPhoto ? 'Change' : 'Upload',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
      ],
    );
  }

  // ── Form Card Wrapper ──
  Widget _buildFormCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.adaptiveBorder),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12).withValues(
              alpha: 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Privacy Selector ──
  Widget _buildPrivacySelector(Color accentColor, bool isDark) {
    return Row(
      children: _privacyOptions.map((option) {
        final isSelected = _defaultPrivacy == option['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _defaultPrivacy = option['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(
                right: option != _privacyOptions.last ? 10 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.1)
                    : AppTheme.adaptiveCardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.5)
                      : AppTheme.adaptiveBorder,
                  width: isSelected ? 1.8 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.15)
                          : AppTheme.adaptiveSoftSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      size: 20,
                      color: isSelected
                          ? accentColor
                          : AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    option['label'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? accentColor
                          : AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option['desc'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Family Card ──
  Widget _buildFamilyCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.family_restroom_outlined,
              color: Color(0xFF22C55E),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite family later',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Skip family setup for now. You can invite contributors or custodians after your archive feels ready.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Later',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save Button ──
  Widget _buildSaveButton(Color accentColor) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Record Life',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Initials Avatar ──
  Widget _buildInitialsAvatar(Color accentColor) {
    return Center(
      child: Text(
        _initials,
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
      ),
    );
  }

  String get _initials {
    final text = _displayNameController.text.trim();
    if (text.isEmpty) return 'SO';

    final parts = text.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double rotation;
  final List<Color> gradientColors;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.rotation,
    required this.gradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        transform: GradientRotation(rotation),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
