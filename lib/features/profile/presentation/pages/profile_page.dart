import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../albums/presentation/pages/albums_page.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../memories/presentation/widgets/memory_card.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../cubits/profile_cubit.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            final user = state.user;
            final avatar = MediaUrlFormatter.format(user.avatarUrl);

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(
                                  user.name?.isNotEmpty == true ? user.name![0] : 'U',
                                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name ?? 'Odyssey Storyteller',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            user.bio!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Stats Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('Memories', '${user.memoriesCount}'),
                            _statItem('Albums', '${user.albumsCount}'),
                            _statItem('Followers', '${user.followersCount}'),
                            _statItem('Family', '${user.familyCount}'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (_) => BlocProvider.value(
                                value: context.read<ProfileCubit>(),
                                child: EditProfileDialog(user: user),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                          label: Text('Edit Profile', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'My Memories'),
                      Tab(text: 'My Albums'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Memories
                  BlocProvider.value(
                    value: sl<MemoriesCubit>()..loadUserMemories(user.id),
                    child: BlocBuilder<MemoriesCubit, MemoriesState>(
                      builder: (context, memState) {
                        if (memState is MemoriesLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (memState is MemoriesLoaded) {
                          if (memState.memories.isEmpty) {
                            return Center(child: Text('No memories recorded yet.', style: GoogleFonts.outfit(color: AppColors.textSecondary)));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: memState.memories.length,
                            itemBuilder: (context, index) {
                              return MemoryCard(
                                memory: memState.memories[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MemoryDetailPage(
                                        memoryId: memState.memories[index].id,
                                      ),
                                    ),
                                  );
                                },
                                onReact: (type) {
                                  context
                                      .read<MemoriesCubit>()
                                      .reactToMemory(memState.memories[index].id, type);
                                },
                                onDelete: () {
                                  context
                                      .read<MemoriesCubit>()
                                      .deleteMemory(memState.memories[index].id);
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),

                  // Tab 2: My Albums
                  BlocProvider.value(
                    value: sl<AlbumsCubit>(),
                    child: const AlbumsPage(),
                  ),
                ],
              ),
            );
          } else if (state is ProfileError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
