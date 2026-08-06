import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/media_url_formatter.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/pages/memory_detail_page.dart';
import '../../../memories/presentation/widgets/memory_card.dart';
import '../cubits/discover_cubit.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _searchController = TextEditingController();
  static const List<String> categories = [
    'All',
    'Life Stories',
    'Advice',
    'Family History',
    'Traditions',
    'Milestones',
    'Philosophy',
  ];

  @override
  void initState() {
    super.initState();
    context.read<DiscoverCubit>().loadDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Discover Odysseys',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      context.read<DiscoverCubit>().search(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search memories, themes, or people...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context.read<DiscoverCubit>().loadDiscovery();
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                  ),
                ),
              ),

              // Category Pills
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = state is DiscoverLoaded && state.selectedCategory == cat;

                      return GestureDetector(
                        onTap: () {
                          context.read<DiscoverCubit>().loadDiscovery(category: cat);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderLight),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Suggested People Carousel
              if (state is DiscoverLoaded && state.suggestedPeople.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 10),
                    child: Text(
                      'Suggested Odysseys to Follow',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.suggestedPeople.length,
                      itemBuilder: (context, index) {
                        final person = state.suggestedPeople[index];
                        final avatar = MediaUrlFormatter.format(person.avatarUrl);

                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                child: avatar == null
                                    ? Text(
                                        person.name?.isNotEmpty == true ? person.name![0] : 'U',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                person.name ?? 'User',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                               ElevatedButton(
                                onPressed: () {
                                  context.read<DiscoverCubit>().toggleFollow(person.id, person.isFollowing);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: person.isFollowing ? AppColors.borderLight : AppColors.primary,
                                  minimumSize: const Size(80, 26),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  person.isFollowing ? 'Following' : 'Follow',
                                  style: GoogleFonts.outfit(fontSize: 11, color: person.isFollowing ? AppColors.textPrimary : Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Discovered Memories List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Explore Public Stories',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (state is DiscoverLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (state is DiscoverLoaded)
                state.memories.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text('No memories found for this search/filter.', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: BlocProvider<MemoriesCubit>.value(
                          value: sl<MemoriesCubit>(),
                          child: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final memory = state.memories[index];
                                return MemoryCard(
                                  memory: memory,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MemoryDetailPage(memoryId: memory.id),
                                      ),
                                    );
                                  },
                                  onReact: (type) {
                                    context.read<MemoriesCubit>().reactToMemory(memory.id, type);
                                  },
                                );
                              },
                              childCount: state.memories.length,
                            ),
                          ),
                        ),
                      )
              else if (state is DiscoverError)
                SliverFillRemaining(child: Center(child: Text(state.message, style: const TextStyle(color: Colors.red)))),
            ],
          );
        },
      ),
    );
  }
}
