import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../cubits/followers_cubit.dart';
import '../cubits/followers_state.dart';
import '../cubits/profile_cubit.dart';
import '../widgets/share_profile_modal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  static const String _defaultCover =
      'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=80';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            final user = state.user;
            final avatar = MediaUrlFormatter.format(user.avatarUrl);
            final cover =
                MediaUrlFormatter.format(user.coverUrl) ?? _defaultCover;

            final profession = user.profession?.isNotEmpty == true
                ? user.profession!
                : 'Not provided';
            final location = user.location?.isNotEmpty == true
                ? user.location!
                : 'Not provided';
            final birthDate = user.birthDate?.isNotEmpty == true
                ? 'Born ${user.birthDate!}'
                : (user.dateOfBirth?.isNotEmpty == true
                      ? 'Born ${user.dateOfBirth!}'
                      : 'Birth date not provided');
            final bio = user.bio?.isNotEmpty == true
                ? user.bio!
                : 'Add a bio to help family members understand your story.';
            final expertiseList =
                (user.expertise != null && user.expertise!.isNotEmpty)
                ? user.expertise!
                : const <String>[];
            final lifeMotto = user.lifeMotto?.isNotEmpty == true
                ? user.lifeMotto!
                : 'Add a life motto to your profile.';

            return Stack(
              children: [
                // Organic background wave graphic
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.45,
                    child: Image.asset(AssetConstants.bgPic, fit: BoxFit.cover),
                  ),
                ),

                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Section: Cover Banner + Floating Settings + Overlapping Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // Cover Banner Image
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(cover),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Log Out Button on Top-Left of Cover Banner
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 16,
                            child: Semantics(
                              button: true,
                              label: 'Sign out',
                              child: InkWell(
                                onTap: () =>
                                    _showLogoutConfirmationDialog(context),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  constraints: const BoxConstraints.tightFor(
                                    width: 48,
                                    height: 48,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Settings Button on Top-Right of Cover
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            right: 16,
                            child: Semantics(
                              button: true,
                              label: 'Open settings',
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<ProfileCubit>(),
                                        child: const SettingsPage(
                                          initialTab: 0,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                customBorder: const CircleBorder(),
                                child: Container(
                                  constraints: const BoxConstraints.tightFor(
                                    width: 48,
                                    height: 48,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.settings_rounded,
                                    color: Color(0xFF5E4EE8),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Overlapping Centered Rounded-Square Avatar
                          Positioned(
                            top: 140,
                            child: Container(
                              width: 115,
                              height: 115,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: avatar != null
                                    ? Image.network(
                                        avatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildAvatarFallback(user.name),
                                      )
                                    : _buildAvatarFallback(user.name),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Space for avatar overlap
                      const SizedBox(height: 68),

                      // User Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          user.name ?? 'Unnamed member',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F2937),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3-Column Info Row: Profession, Location, Birth Date
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInfoColumn(
                                icon: Icons.business_center_outlined,
                                text: profession,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInfoColumn(
                                icon: Icons.location_on_outlined,
                                text: location,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInfoColumn(
                                icon: Icons.calendar_today_outlined,
                                text: birthDate,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bio / Statement Box with purple border
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF6366F1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            bio,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Areas of Expertise Header & Chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Areas of Expertise',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (expertiseList.isEmpty)
                              Text(
                                'Add areas of expertise in Settings.',
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: expertiseList
                                    .map((exp) => _buildExpertiseChip(exp))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons: Edit Profile & Share Legacy
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // Edit Profile Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<ProfileCubit>(),
                                        child: const SettingsPage(
                                          initialTab: 0,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  side: const BorderSide(
                                    color: Color(0xFF5E4EE8),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                child: Text(
                                  'Edit Profile',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF5E4EE8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Share Legacy Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ShareProfileModal.show(context, user);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  backgroundColor: const Color(0xFF5E4EE8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Share Legacy',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 2x2 Stats Grid: All Memories, Albums, Milestones, Followers
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // 1. All Memories
                                Expanded(
                                  child:
                                      BlocBuilder<MemoriesCubit, MemoriesState>(
                                        builder: (context, memState) {
                                          final count =
                                              memState is MemoriesLoaded
                                              ? '${memState.memories.length}'
                                              : '${user.memoriesCount}';
                                          return _buildStatCard(
                                            value: count,
                                            title: 'All Memories',
                                          );
                                        },
                                      ),
                                ),
                                const SizedBox(width: 12),

                                // 2. Albums
                                Expanded(
                                  child: BlocBuilder<AlbumsCubit, AlbumsState>(
                                    builder: (context, albumState) {
                                      final count = albumState is AlbumsLoaded
                                          ? '${albumState.albums.length}'
                                          : '${user.albumsCount}';
                                      return _buildStatCard(
                                        value: count,
                                        title: 'Albums',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // 3. Milestones
                                Expanded(
                                  child:
                                      BlocBuilder<MemoriesCubit, MemoriesState>(
                                        builder: (context, memState) {
                                          int count = 0;
                                          if (memState is MemoriesLoaded) {
                                            count = memState.memories.where((
                                              m,
                                            ) {
                                              final tags = m.tags
                                                  .map((t) => t.toLowerCase())
                                                  .toList();
                                              final title = m.title
                                                  .toLowerCase();
                                              return tags.contains(
                                                    'milestone',
                                                  ) ||
                                                  tags.contains(
                                                    'career & growth',
                                                  ) ||
                                                  tags.contains(
                                                    'turning point',
                                                  ) ||
                                                  tags.contains('proud') ||
                                                  title.contains('milestone');
                                            }).length;
                                          }
                                          return _buildStatCard(
                                            value: count > 0 ? '$count' : '0',
                                            title: 'Milestones',
                                          );
                                        },
                                      ),
                                ),
                                const SizedBox(width: 12),

                                // 4. Followers
                                Expanded(
                                  child:
                                      BlocBuilder<
                                        FollowersCubit,
                                        FollowersState
                                      >(
                                        builder: (context, followerState) {
                                          final count =
                                              followerState is FollowersLoaded
                                              ? '${followerState.followers.length}'
                                              : '${user.followersCount}';
                                          return _buildStatCard(
                                            value: count,
                                            title: 'Followers',
                                          );
                                        },
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Quote / Life Motto Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDE5FE),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Decorative Watermark Quote
                              Positioned(
                                top: -14,
                                left: -6,
                                child: Text(
                                  '“',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(
                                      0xFF5E4EE8,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '"$lifeMotto"',
                                  style: GoogleFonts.outfit(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1B4B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Bottom Brand Tagline Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '"Changing The Way We Preserve Our Legacy"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5E4EE8),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Log Out Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showLogoutConfirmationDialog(context),
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            label: Text(
                              'Log Out',
                              style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.05,
                              ),
                              side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is ProfileError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Retry',
                      expand: false,
                      onPressed: () =>
                          context.read<ProfileCubit>().loadProfile(),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // Info Column Helper (Icon inside light purple square + Text below)
  Widget _buildInfoColumn({required IconData icon, required String text}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF5E4EE8), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // Expertise Tag Chip
  Widget _buildExpertiseChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5E4EE8),
        ),
      ),
    );
  }

  // Stat Card (2x2 Grid)
  Widget _buildStatCard({required String value, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1E2D),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String? name) {
    return Container(
      color: const Color(0xFFEDE9FE),
      child: Center(
        child: Text(
          name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5E4EE8),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log Out',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out of Spoken Odyssey?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          side: const BorderSide(
                            color: Color(0xFFD1D5DB),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.read<AuthCubit>().signOut();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/sign-in',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: Colors.redAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
}
