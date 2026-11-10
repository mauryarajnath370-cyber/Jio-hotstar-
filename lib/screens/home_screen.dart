import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/jio_hotstar_logo.dart';
import '../models/video_model.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../services/database_service.dart';
import '../l10n/app_strings.dart';
import 'video_player_screen.dart';
import 'search_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'adult_category_screen.dart';
import 'admin/admin_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;

  // 5-tap Admin trigger tracker
  int _logoTapCount = 0;
  DateTime? _firstTapTime;

  // Carousel
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _carouselCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContentProvider>(context, listen: false).loadInitialData();
    });
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController.hasClients) {
        _carouselCurrentPage++;
        _carouselController.animateToPage(
          _carouselCurrentPage % 5,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_firstTapTime == null || now.difference(_firstTapTime!).inMilliseconds > 2000) {
      _firstTapTime = now;
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
      if (_logoTapCount >= 5) {
        _logoTapCount = 0;
        _firstTapTime = null;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      }
    }
  }

  void _handleAdultCardTap() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    if (authProvider.isAdultSessionActive) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdultCategoryScreen()),
      );
      return;
    }

    final db = DatabaseService();
    final snapshot = await db.verifyAdultPassword(user.uid, ""); // Check if set
    // Check if user has password set
    final hasPassword = user.adultPasswordHash.isNotEmpty;

    if (!mounted) return;

    if (!hasPassword) {
      _showSetAdultPasswordDialog(user.uid);
    } else {
      _showEnterAdultPasswordDialog(user.uid);
    }
  }

  void _showSetAdultPasswordDialog(String uid) {
    final pass1 = TextEditingController();
    final pass2 = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(AppStrings.t('set_password'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set a 4+ digit PIN/Password to access 18+ content safely.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pass1,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: AppTheme.textGrey)),
            ),
            TextField(
              controller: pass2,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Confirm Password', labelStyle: TextStyle(color: AppTheme.textGrey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () async {
              if (pass1.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum 4 characters required')));
                return;
              }
              if (pass1.text != pass2.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              Navigator.pop(ctx);
              await DatabaseService().setAdultPassword(uid, pass1.text.trim());
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.refreshUser();
              auth.unlockAdultSession();
              if (mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdultCategoryScreen()));
              }
            },
            child: const Text('Save & Unlock'),
          ),
        ],
      ),
    );
  }

  void _showEnterAdultPasswordDialog(String uid) {
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(AppStrings.t('enter_password'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: AppTheme.textGrey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () async {
              final correct = await DatabaseService().verifyAdultPassword(uid, passController.text.trim());
              if (!mounted) return;
              if (correct) {
                Navigator.pop(ctx);
                Provider.of<AuthProvider>(context, listen: false).unlockAdultSession();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdultCategoryScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrong password!'), backgroundColor: AppTheme.accent),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);

    // If bottom nav is switched, show corresponding sub-screen
    Widget bodyContent;
    switch (_currentBottomNavIndex) {
      case 1:
        bodyContent = const SearchScreen();
        break;
      case 2:
        bodyContent = const PremiumScreen();
        break;
      case 3:
        bodyContent = const SettingsScreen();
        break;
      case 0:
      default:
        bodyContent = _buildHomeFeed(contentProvider);
        break;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        titleSpacing: 16,
        title: GestureDetector(
          onTap: _handleLogoTap,
          child: const JioHotstarLogo(size: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: AppStrings.t('search'),
            onPressed: () => setState(() => _currentBottomNavIndex = 1),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: AppStrings.t('settings'),
            onPressed: () => setState(() => _currentBottomNavIndex = 3),
          ),
        ],
      ),
      body: bodyContent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.95),
          border: const Border(top: BorderSide(color: Color(0xFF2B2B2B), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) => setState(() => _currentBottomNavIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.textGrey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: AppStrings.t('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: AppStrings.t('search'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star),
              label: AppStrings.t('premium'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: AppStrings.t('settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeFeed(ContentProvider contentProvider) {
    if (contentProvider.isLoading) {
      return _buildShimmerSkeletons();
    }

    final sections = (contentProvider.homeLayout['sections'] as List<dynamic>?) ?? [
      {"type": "carousel", "title": "Live Events", "source": "live_events", "order": 0},
      {"type": "row", "title": "Trending", "source": "videos", "filter": "trending", "order": 1},
      {"type": "adult_card", "title": "Adult Content", "order": 99}
    ];

    // Sort by order
    final sortedSections = List.from(sections);
    sortedSections.sort((a, b) {
      final orderA = (a is Map) ? (a['order'] ?? 0) : 0;
      final orderB = (b is Map) ? (b['order'] ?? 0) : 0;
      return (orderA as int).compareTo(orderB as int);
    });

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      onRefresh: () => contentProvider.loadInitialData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedSections.map((sec) {
            if (sec is! Map) return const SizedBox.shrink();
            final type = sec['type']?.toString() ?? 'row';
            final title = sec['title']?.toString() ?? 'Featured';

            switch (type) {
              case 'carousel':
                return _buildCarousel(contentProvider.trendingVideos);
              case 'adult_card':
                return _buildAdultCard();
              case 'row':
              default:
                return _buildVideoRow(title, sec, contentProvider);
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<VideoModel> trending) {
    final items = trending.isNotEmpty
        ? trending.take(5).toList()
        : [
            VideoModel(
              id: 'demo_1',
              title: 'Jio Hotstar Blockbuster: Cricket Live & Big Movies',
              cdnUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              thumbnailUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
              isPaid: true,
              isTrending: true,
            ),
          ];

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _carouselController,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final video = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl.isNotEmpty
                      ? video.thumbnailUrl
                      : 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF222222)),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x800F0F0F),
                        Color(0xFF0F0F0F),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (video.isPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PREMIUM',
                                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            Text(
                              video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(AppStrings.t('watch_now'), style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoRow(String title, Map<dynamic, dynamic> sec, ContentProvider contentProvider) {
    final filter = sec['filter']?.toString();
    final categoryId = sec['category']?.toString();
    List<VideoModel> videos = contentProvider.recentVideos;

    if (filter == 'trending') {
      videos = contentProvider.trendingVideos;
    } else if (categoryId != null && categoryId.isNotEmpty) {
      videos = contentProvider.recentVideos.where((v) => v.categoryId == categoryId).toList();
    }

    if (videos.isEmpty) {
      videos = contentProvider.recentVideos;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Text(
                  '${AppStrings.t('see_all')} >',
                  style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: videos.isNotEmpty ? videos.length : 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (videos.isEmpty) {
                return _buildPlaceholderCard();
              }
              final video = videos[index];
              return _buildVideoCard(video);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
        );
      },
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnailUrl.isNotEmpty
                          ? video.thumbnailUrl
                          : 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppTheme.surface),
                    ),
                  ),
                ),
                if (video.isPaid)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.movie, color: Colors.white24, size: 36),
      ),
    );
  }

  Widget _buildAdultCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: InkWell(
        onTap: _handleAdultCardTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B0000), Color(0xFF1A0000), Color(0xFF0F0F0F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔞 Adult Content',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PIN Protected • 18+ Only',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
                child: const Icon(Icons.lock, color: Colors.redAccent, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerSkeletons() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surface,
      highlightColor: const Color(0xFF2A2A2A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 20),
            Container(height: 20, width: 140, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                3,
                (_) => Container(
                  width: 110,
                  height: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
