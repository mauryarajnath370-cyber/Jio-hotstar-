import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screen_protector/screen_protector.dart';
import '../core/theme/app_theme.dart';
import '../models/video_model.dart';
import '../services/database_service.dart';
import 'video_player_screen.dart';

class AdultCategoryScreen extends StatefulWidget {
  const AdultCategoryScreen({super.key});

  @override
  State<AdultCategoryScreen> createState() => _AdultCategoryScreenState();
}

class _AdultCategoryScreenState extends State<AdultCategoryScreen> {
  List<VideoModel> _adultVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    _fetchAdultVideos();
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  void _enableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (_) {}
  }

  void _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (_) {}
  }

  void _fetchAdultVideos() async {
    final db = DatabaseService();
    final categories = await db.getCategories();
    final adultCats = categories.where((c) => c.isAdult).toList();

    List<VideoModel> allAdult = [];
    if (adultCats.isNotEmpty) {
      for (final cat in adultCats) {
        final list = await db.getVideosByCategory(cat.id, limit: 20);
        allAdult.addAll(list);
      }
    } else {
      // Default to general videos if no adult category created yet
      allAdult = await db.getVideos(limit: 10);
    }

    if (mounted) {
      setState(() {
        _adultVideos = allAdult;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text(
              '18+ Adult Content',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _adultVideos.isEmpty
              ? const Center(
                  child: Text(
                    'No videos currently available in this category.\nCheck back soon or add via Admin Panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _adultVideos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final video = _adultVideos[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2B2B2B)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 130,
                                height: 75,
                                child: CachedNetworkImage(
                                  imageUrl: video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(color: Colors.black),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade900,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('18+', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${video.views} views',
                                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
