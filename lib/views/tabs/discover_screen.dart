import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../customWidgets/person_card.dart';
import '../../theme/theme.dart';
import 'person_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedTabIndex = 0;
  String _selectedTheme = 'All';
  String _selectedEra = 'All';
  String _selectedSort = 'Recommended';
  final Set<String> _followedPeople = <String>{};

  final List<Map<String, dynamic>> _people = [
    {
      'name': 'Admiral Grace Hopper',
      'role': 'Computer Scientist & Naval Officer',
      'description':
          'Pioneer of computer programming who turned abstract machine logic into practical software language for the world.',
      'featuredReason': 'A mind that taught computers to speak more humanly.',
      'quote':
          'The most dangerous phrase in the language is: we have always done it this way.',
      'followersCount': 45200,
      'country': 'United States',
      'era': '1900s',
      'themes': ['Innovation', 'Leadership', 'Legacy'],
      'bgImage':
          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop',
      'stories': [
        {
          'title': 'The Night COBOL Found Its Voice',
          'excerpt':
              'Grace Hopper kept pushing for programming languages ordinary people could understand, changing software from code for specialists into tools for society.',
          'theme': 'Innovation',
          'era': '1900s',
          'tag': 'Breakthrough',
          'readTime': '6 min read',
          'likes': 2400,
          'publishedAt': DateTime(2026, 4, 12),
          'publishedLabel': 'April 12, 2026',
        },
        {
          'title': 'The Day I Wrote the First Compiler',
          'excerpt':
              'Everyone said computers would only speak numbers. Hopper believed language could bridge people and machines, even when the industry resisted.',
          'theme': 'Leadership',
          'era': '1900s',
          'tag': 'Career',
          'readTime': '5 min read',
          'likes': 1820,
          'publishedAt': DateTime(2026, 4, 5),
          'publishedLabel': 'April 5, 2026',
        },
      ],
      'milestones': [
        {
          'year': '1952',
          'title': 'Built one of the first compilers',
          'desc':
              'She proved software could be translated into machine instructions through language, not just raw numbers.',
          'tag': 'Breakthrough',
          'icon': Icons.memory_outlined,
        },
        {
          'year': '1985',
          'title': 'Promoted to Rear Admiral',
          'desc':
              'Her military and technical leadership made her one of the most influential figures in modern computing history.',
          'tag': 'Leadership',
          'icon': Icons.workspace_premium_outlined,
        },
      ],
      'albums': [
        {
          'title': 'Navy Years',
          'subtitle':
              'Service, systems, and the discipline behind her breakthroughs.',
          'entryCount': 14,
          'coverImage':
              'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?q=80&w=2574&auto=format&fit=crop',
        },
        {
          'title': 'Computing Breakthroughs',
          'subtitle':
              'Compiler milestones, language design, and early software culture.',
          'entryCount': 12,
          'coverImage':
              'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=2670&auto=format&fit=crop',
        },
      ],
    },
    {
      'name': 'Nelson Mandela',
      'role': 'Revolutionary & President',
      'description':
          'A life shaped by sacrifice, reconciliation, and the kind of courage that transforms the future of a nation.',
      'featuredReason': 'Proof that dignity can outlast oppression.',
      'quote':
          'Resentment is like drinking poison and then hoping it will kill your enemies.',
      'followersCount': 128000,
      'country': 'South Africa',
      'era': '1900s',
      'themes': ['Freedom', 'Leadership', 'Resilience'],
      'bgImage':
          'https://images.unsplash.com/photo-1542204165-65bf26472b9b?q=80&w=2574&auto=format&fit=crop',
      'avatar':
          'https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=800&auto=format&fit=crop',
      'stories': [
        {
          'title': 'A Prison Cell That Could Not Shrink a Vision',
          'excerpt':
              'Mandela’s years in confinement did not erase his imagination for justice; they sharpened it into a disciplined, moral force.',
          'theme': 'Freedom',
          'era': '1900s',
          'tag': 'Resilience',
          'readTime': '8 min read',
          'likes': 4200,
          'publishedAt': DateTime(2026, 4, 18),
          'publishedLabel': 'April 18, 2026',
        },
        {
          'title': 'The Politics of Reconciliation',
          'excerpt':
              'His leadership showed that healing a nation requires imagination as much as power.',
          'theme': 'Leadership',
          'era': '1900s',
          'tag': 'Nation Building',
          'readTime': '7 min read',
          'likes': 3110,
          'publishedAt': DateTime(2026, 4, 8),
          'publishedLabel': 'April 8, 2026',
        },
      ],
      'milestones': [
        {
          'year': '1990',
          'title': 'Released after 27 years of imprisonment',
          'desc':
              'His emergence from prison marked a turning point in South Africa’s democratic future.',
          'tag': 'Freedom',
          'icon': Icons.lock_open_outlined,
        },
        {
          'year': '1994',
          'title': 'Elected President of South Africa',
          'desc':
              'He led the country’s first democratic government with reconciliation at its center.',
          'tag': 'Leadership',
          'icon': Icons.public_outlined,
        },
      ],
      'albums': [
        {
          'title': 'Long Walk',
          'subtitle':
              'Moments that defined conviction, sacrifice, and strategy.',
          'entryCount': 19,
          'coverImage':
              'https://images.unsplash.com/photo-1489493887464-892be6d1daae?q=80&w=2669&auto=format&fit=crop',
        },
        {
          'title': 'Rebuilding a Nation',
          'subtitle':
              'Stories of transition, negotiation, and moral authority.',
          'entryCount': 15,
          'coverImage':
              'https://images.unsplash.com/photo-1497366754035-f200968a6e72?q=80&w=2574&auto=format&fit=crop',
        },
      ],
    },
    {
      'name': 'Maya Angelou',
      'role': 'Poet & Activist',
      'description':
          'Her archive reads like bravery turned into language, lifting private pain into collective hope.',
      'featuredReason': 'Words that still feel alive in the room.',
      'quote':
          'There is no greater agony than bearing an untold story inside you.',
      'followersCount': 97500,
      'country': 'United States',
      'era': '1900s',
      'themes': ['Poetry', 'Identity', 'Legacy'],
      'bgImage':
          'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2670&auto=format&fit=crop',
      'avatar':
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800&auto=format&fit=crop',
      'stories': [
        {
          'title': 'How Maya Angelou Turned Memory into Music',
          'excerpt':
              'Her storytelling made room for tenderness, rage, and dignity all at once, showing how a personal archive can heal others too.',
          'theme': 'Poetry',
          'era': '1900s',
          'tag': 'Writing',
          'readTime': '5 min read',
          'likes': 3150,
          'publishedAt': DateTime(2026, 4, 22),
          'publishedLabel': 'April 22, 2026',
        },
        {
          'title': 'Private Pain, Public Grace',
          'excerpt':
              'Angelou’s memoirs made vulnerability feel like a disciplined art, not a confession of weakness.',
          'theme': 'Identity',
          'era': '1900s',
          'tag': 'Memoir',
          'readTime': '6 min read',
          'likes': 2660,
          'publishedAt': DateTime(2026, 4, 10),
          'publishedLabel': 'April 10, 2026',
        },
      ],
      'milestones': [
        {
          'year': '1969',
          'title': 'Published I Know Why the Caged Bird Sings',
          'desc':
              'She transformed memoir into a cultural and emotional landmark for generations of readers.',
          'tag': 'Literature',
          'icon': Icons.menu_book_outlined,
        },
        {
          'year': '1993',
          'title': 'Read poetry at a U.S. presidential inauguration',
          'desc':
              'Her voice entered public ritual with grace, gravity, and national significance.',
          'tag': 'Legacy',
          'icon': Icons.mic_none_outlined,
        },
      ],
      'albums': [
        {
          'title': 'Poems & Performances',
          'subtitle':
              'Language that stayed close to breath, movement, and memory.',
          'entryCount': 11,
          'coverImage':
              'https://images.unsplash.com/photo-1455390582262-044cdead277a?q=80&w=2673&auto=format&fit=crop',
        },
        {
          'title': 'Memoirs of Becoming',
          'subtitle':
              'Stories of identity, dignity, and the work of self-making.',
          'entryCount': 16,
          'coverImage':
              'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=2674&auto=format&fit=crop',
        },
      ],
    },
    {
      'name': 'Malala Yousafzai',
      'role': 'Education Activist',
      'description':
          'A modern voice of conviction whose journey shows how testimony can become global action.',
      'featuredReason': 'A story that reminds younger voices they matter.',
      'quote':
          'One child, one teacher, one book, and one pen can change the world.',
      'followersCount': 61800,
      'country': 'Pakistan',
      'era': '2000s',
      'themes': ['Education', 'Courage', 'Hope'],
      'bgImage':
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=2574&auto=format&fit=crop',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop',
      'stories': [
        {
          'title': 'Why Young Testimony Can Move the World',
          'excerpt':
              'Malala’s archive proves that clarity, even in youth, can carry global moral weight when it is rooted in lived truth.',
          'theme': 'Courage',
          'era': '2000s',
          'tag': 'Youth Voice',
          'readTime': '4 min read',
          'likes': 1980,
          'publishedAt': DateTime(2026, 4, 24),
          'publishedLabel': 'April 24, 2026',
        },
        {
          'title': 'Education as a Public Right',
          'excerpt':
              'Her work reframed girls’ education as a moral and civic issue, not a side conversation.',
          'theme': 'Education',
          'era': '2000s',
          'tag': 'Advocacy',
          'readTime': '5 min read',
          'likes': 1730,
          'publishedAt': DateTime(2026, 4, 15),
          'publishedLabel': 'April 15, 2026',
        },
      ],
      'milestones': [
        {
          'year': '2014',
          'title': 'Became the youngest Nobel Peace Prize laureate',
          'desc':
              'Her advocacy for education became one of the defining moral stories of her generation.',
          'tag': 'Honor',
          'icon': Icons.workspace_premium_outlined,
        },
        {
          'year': '2013',
          'title': 'Addressed the United Nations',
          'desc':
              'She turned a personal survival story into a global call for education access.',
          'tag': 'Education',
          'icon': Icons.campaign_outlined,
        },
      ],
      'albums': [
        {
          'title': 'Voices for Education',
          'subtitle':
              'Campaigns, speeches, and field moments centered on access.',
          'entryCount': 9,
          'coverImage':
              'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?q=80&w=2622&auto=format&fit=crop',
        },
        {
          'title': 'Courage in Public',
          'subtitle':
              'Moments where witness became action and action became change.',
          'entryCount': 13,
          'coverImage':
              'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=2574&auto=format&fit=crop',
        },
      ],
    },
  ];

  List<String> get _themes {
    final values = <String>{'All'};
    for (final person in _people) {
      values.addAll((person['themes'] as List<dynamic>).cast<String>());
    }
    return values.toList();
  }

  List<Map<String, dynamic>> get _allStories {
    final stories = <Map<String, dynamic>>[];
    for (final person in _people) {
      final personStories = (person['stories'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final story in personStories) {
        stories.add({
          ...story,
          'personName': person['name'],
          'personRole': person['role'],
          'personAvatar': person['avatar'],
        });
      }
    }
    return stories;
  }

  List<Map<String, dynamic>> get _filteredPeople {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _people.where((person) {
      final themes = (person['themes'] as List<dynamic>).cast<String>();
      final matchesQuery =
          query.isEmpty ||
          person['name'].toString().toLowerCase().contains(query) ||
          person['role'].toString().toLowerCase().contains(query) ||
          person['description'].toString().toLowerCase().contains(query) ||
          person['country'].toString().toLowerCase().contains(query) ||
          person['quote'].toString().toLowerCase().contains(query) ||
          themes.join(' ').toLowerCase().contains(query);

      final matchesTheme =
          _selectedTheme == 'All' || themes.contains(_selectedTheme);

      final matchesEra = _selectedEra == 'All' || person['era'] == _selectedEra;

      return matchesQuery && matchesTheme && matchesEra;
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Most Followed':
          return (b['followersCount'] as int).compareTo(
            a['followersCount'] as int,
          );
        case 'Most Stories':
          return _storyCountOf(b).compareTo(_storyCountOf(a));
        default:
          final aThemeScore =
              _selectedTheme != 'All' &&
                  (a['themes'] as List<dynamic>).contains(_selectedTheme)
              ? 1
              : 0;
          final bThemeScore =
              _selectedTheme != 'All' &&
                  (b['themes'] as List<dynamic>).contains(_selectedTheme)
              ? 1
              : 0;
          final byTheme = bThemeScore.compareTo(aThemeScore);
          if (byTheme != 0) {
            return byTheme;
          }
          return (b['followersCount'] as int).compareTo(
            a['followersCount'] as int,
          );
      }
    });

    return filtered;
  }

  List<Map<String, dynamic>> get _filteredStories {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allStories.where((story) {
      final matchesQuery =
          query.isEmpty ||
          story['title'].toString().toLowerCase().contains(query) ||
          story['excerpt'].toString().toLowerCase().contains(query) ||
          story['theme'].toString().toLowerCase().contains(query) ||
          story['personName'].toString().toLowerCase().contains(query) ||
          story['personRole'].toString().toLowerCase().contains(query);

      final matchesTheme =
          _selectedTheme == 'All' || story['theme'] == _selectedTheme;
      final matchesEra = _selectedEra == 'All' || story['era'] == _selectedEra;

      return matchesQuery && matchesTheme && matchesEra;
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Most Followed':
          final personA = _personByName(a['personName'] as String);
          final personB = _personByName(b['personName'] as String);
          return ((personB?['followersCount'] as int?) ?? 0).compareTo(
            (personA?['followersCount'] as int?) ?? 0,
          );
        case 'Most Stories':
          final personA = _personByName(a['personName'] as String);
          final personB = _personByName(b['personName'] as String);
          return _storyCountOf(personB).compareTo(_storyCountOf(personA));
        default:
          return (b['publishedAt'] as DateTime).compareTo(
            a['publishedAt'] as DateTime,
          );
      }
    });

    return filtered;
  }

  int get _totalStories => _allStories.length;

  Map<String, dynamic>? _personByName(String name) {
    try {
      return _people.firstWhere((person) => person['name'] == name);
    } catch (_) {
      return null;
    }
  }

  int _storyCountOf(Map<String, dynamic>? person) {
    if (person == null) {
      return 0;
    }
    return (person['stories'] as List<dynamic>).length;
  }

  int _milestoneCountOf(Map<String, dynamic>? person) {
    if (person == null) {
      return 0;
    }
    return (person['milestones'] as List<dynamic>).length;
  }

  String _formatFollowers(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  void _toggleFollow(Map<String, dynamic> person) {
    final name = person['name'] as String;
    final isFollowing = _followedPeople.contains(name);

    setState(() {
      if (isFollowing) {
        _followedPeople.remove(name);
        person['followersCount'] = (person['followersCount'] as int) - 1;
      } else {
        _followedPeople.add(name);
        person['followersCount'] = (person['followersCount'] as int) + 1;
      }
    });
  }

  void _updateFollowFromDetail(Map<String, dynamic> person, bool isFollowing) {
    final name = person['name'] as String;
    final alreadyFollowing = _followedPeople.contains(name);

    if (alreadyFollowing == isFollowing) {
      return;
    }

    setState(() {
      if (isFollowing) {
        _followedPeople.add(name);
        person['followersCount'] = (person['followersCount'] as int) + 1;
      } else {
        _followedPeople.remove(name);
        person['followersCount'] = (person['followersCount'] as int) - 1;
      }
    });
  }

  Future<void> _openPersonDetail(Map<String, dynamic> person) async {
    await Get.to(
      () => PersonDetailScreen(
        person: {
          ...person,
          'followers': _formatFollowers(person['followersCount'] as int),
          'storiesCount': _storyCountOf(person),
          'milestonesCount': _milestoneCountOf(person),
        },
        initialIsFollowing: _followedPeople.contains(person['name']),
        onFollowChanged: (isFollowing) =>
            _updateFollowFromDetail(person, isFollowing),
      ),
    );
  }

  void _openFilterSheet() {
    String draftEra = _selectedEra;
    String draftSort = _selectedSort;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.adaptiveBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Refine discovery',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tune the archive by era and ranking style so discovery feels intentional instead of noisy.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.adaptiveTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildFilterSectionTitle('Era'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['All', '1900s', '2000s'].map((era) {
                        final selected = draftEra == era;
                        return _buildSelectableChip(
                          label: era,
                          selected: selected,
                          onTap: () => setModalState(() => draftEra = era),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    _buildFilterSectionTitle('Sort by'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['Recommended', 'Most Followed', 'Most Stories']
                          .map((sort) {
                            final selected = draftSort == sort;
                            return _buildSelectableChip(
                              label: sort,
                              selected: selected,
                              onTap: () =>
                                  setModalState(() => draftSort = sort),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedEra = 'All';
                                _selectedSort = 'Recommended';
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedEra = draftEra;
                                _selectedSort = draftSort;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.floatingActionButton,
                            ),
                            child: const Text('Apply'),
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
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = _selectedTabIndex == 0
        ? _filteredPeople
        : _filteredStories;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 350));
            if (!mounted) {
              return;
            }
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              if (canPop) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.adaptiveCardBg,
                      foregroundColor: AppTheme.adaptiveTextPrimary,
                      side: BorderSide(color: AppTheme.adaptiveBorder),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildHeroPanel(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildActiveFilterSummary(),
              const SizedBox(height: 20),
              _buildTabSelector(),
              const SizedBox(height: 20),
              _buildThemeRail(),
              const SizedBox(height: 22),
              _buildResultsHeader(activeItems.length),
              const SizedBox(height: 14),
              if (activeItems.isEmpty)
                _buildEmptyState()
              else if (_selectedTabIndex == 0)
                ..._filteredPeople.map(_buildFeaturedPersonCard)
              else
                ..._filteredStories.map(_buildLatestStoryCard),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFilterSheet,
        heroTag: 'discover_fab',
        backgroundColor: AppTheme.floatingActionButton,
        foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 4,
        child: const Icon(Icons.tune, color: AppTheme.white, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202938), Color(0xFF485066), Color(0xFF7A6858)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Public archive discovery',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Discover voices worth learning from.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Explore remarkable lives, move from people into their stories, and keep a lightweight follow list for the archives you want to revisit.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroStat('${_people.length}', 'Featured voices'),
              _buildHeroStat('$_totalStories', 'Stories in archive'),
              _buildHeroStat('${_followedPeople.length}', 'You follow'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.adaptiveTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name, role, theme, country...',
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.adaptiveTextHint,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.adaptiveTextSecondary,
                size: 20,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide(color: AppTheme.adaptiveBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(
                  color: AppTheme.floatingActionButton,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCardBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.adaptiveBorder),
          ),
          child: IconButton(
            onPressed: _openFilterSheet,
            icon: Icon(
              Icons.filter_alt_outlined,
              color: AppTheme.adaptiveTextPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterSummary() {
    final filters = <Map<String, dynamic>>[
      if (_selectedTheme != 'All')
        {
          'label': _selectedTheme,
          'onClear': () => setState(() => _selectedTheme = 'All'),
        },
      if (_selectedEra != 'All')
        {
          'label': _selectedEra,
          'onClear': () => setState(() => _selectedEra = 'All'),
        },
      if (_selectedSort != 'Recommended')
        {
          'label': _selectedSort,
          'onClear': () => setState(() => _selectedSort = 'Recommended'),
        },
    ];

    if (_searchController.text.trim().isNotEmpty) {
      filters.insert(0, {
        'label': '"${_searchController.text.trim()}"',
        'onClear': () {
          _searchController.clear();
          setState(() {});
        },
      });
    }

    if (filters.isEmpty) {
      return Text(
        'Showing a balanced editorial mix of archive voices and their latest stories.',
        style: GoogleFonts.outfit(
          fontSize: 13,
          height: 1.5,
          color: AppTheme.adaptiveTextSecondary,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.adaptiveBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filter['label'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: filter['onClear'] as VoidCallback,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['Featured People', 'Latest Stories'];

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppTheme.adaptiveTextPrimary
                          : AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildThemeRail() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final theme = _themes[index];
          final selected = _selectedTheme == theme;
          return GestureDetector(
            onTap: () => setState(() => _selectedTheme = theme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF5544FF)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF5544FF)
                      : AppTheme.adaptiveBorder,
                ),
              ),
              child: Text(
                theme,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTheme.adaptiveTextPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedTabIndex == 0 ? 'Featured People' : 'Latest Stories',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count results • $_selectedSort • $_selectedEra',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.adaptiveTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPersonCard(Map<String, dynamic> person) {
    final isFollowing = _followedPeople.contains(person['name']);

    return PersonCard(
      bgImageUrl: person['bgImage'] as String,
      avatarUrl: person['avatar'] as String,
      name: person['name'] as String,
      role: person['role'] as String,
      description: person['description'] as String,
      followersCount: _formatFollowers(person['followersCount'] as int),
      badgeLabel: person['featuredReason'] as String,
      isFollowing: isFollowing,
      onFollowTrigger: () => _toggleFollow(person),
      onTap: () => _openPersonDetail(person),
    );
  }

  Widget _buildLatestStoryCard(Map<String, dynamic> story) {
    final person = _personByName(story['personName'] as String);
    final accent = _storyAccent(story['theme'] as String);

    return GestureDetector(
      onTap: person == null ? null : () => _openPersonDetail(person),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_stories_outlined, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'] as String,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${story['personName']} • ${story['readTime']}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.adaptiveTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              story['excerpt'] as String,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMiniChip(story['theme'] as String, accent),
                _buildMiniChip(story['era'] as String, const Color(0xFFE2923A)),
                _buildMiniChip(
                  '${story['likes']} likes',
                  const Color(0xFF5ABA82),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.adaptiveTextSecondary,
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5544FF) : const Color(0xFFF4F1EC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.adaptiveTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF5544FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.travel_explore_outlined,
              color: Color(0xFF5544FF),
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No archives matched this search',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try another theme, switch tabs, or clear your search to keep exploring.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedTheme = 'All';
                _selectedEra = 'All';
                _selectedSort = 'Recommended';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5544FF),
              minimumSize: const Size(0, 46),
            ),
            child: const Text('Reset discovery'),
          ),
        ],
      ),
    );
  }

  Color _storyAccent(String theme) {
    switch (theme) {
      case 'Innovation':
        return const Color(0xFF5544FF);
      case 'Freedom':
        return const Color(0xFFE2923A);
      case 'Poetry':
        return const Color(0xFFE85D75);
      case 'Courage':
        return const Color(0xFF5ABA82);
      case 'Education':
        return const Color(0xFF2F80ED);
      case 'Leadership':
        return const Color(0xFF9B51E0);
      default:
        return const Color(0xFF5544FF);
    }
  }
}
