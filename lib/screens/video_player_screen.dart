import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import '../core/theme/app_theme.dart';
import '../models/video_model.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../core/utils/premium_helper.dart';
import '../l10n/app_strings.dart';
import 'premium_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  bool _isPlaying = true;
  bool _showDescription = false;
  double _playbackSpeed = 1.0;
  double _currentProgress = 0.25; // Simulated playback timeline
  bool _adCompleted = false;
  List<VideoModel> _moreVideos = [];

  // Ad Tracking
  final AdService _adService = AdService();
  bool _waitingForAdResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkProtection();
    _loadCategoryVideos();
    _checkAndTriggerAdFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      ScreenProtector.preventScreenshotOff();
    } catch (_) {}
    super.dispose();
  }

  void _checkProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (_) {}
  }

  void _loadCategoryVideos() async {
    if (widget.video.categoryId.isNotEmpty) {
      final list = await DatabaseService().getVideosByCategory(
        widget.video.categoryId,
        limit: 10,
        excludeId: widget.video.id,
      );
      if (mounted) setState(() => _moreVideos = list);
    }
  }

  void _checkAndTriggerAdFlow() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final isPrem = user != null && PremiumHelper.isPremium(user);

    // If premium user and not adult, bypass ad
    if (isPrem) {
      setState(() => _adCompleted = true);
      return;
    }

    // Check if ads enabled
    final adSettings = await DatabaseService().getAdSettings();
    if (adSettings['adsEnabled'] == false) {
      setState(() => _adCompleted = true);
      return;
    }

    final adLink = await _adService.getNormalAdLink();
    final timerSeconds = await _adService.getAdTimerSeconds();

    if (adLink.isEmpty) {
      setState(() => _adCompleted = true);
      return;
    }

    if (mounted) {
      _showAdDialog(adLink, timerSeconds);
    }
  }

  void _showAdDialog(String adLink, int timerSeconds) {
    int remaining = timerSeconds;
    Timer? countdownTimer;
    bool linkOpened = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.campaign, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.t('sponsored_link'),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Click Continue to open the sponsored sponsor link, then come back to watch in HD.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  if (linkOpened)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            remaining > 0 ? '${AppStrings.t('please_wait')} ${remaining}s' : 'Ready to stream!',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                if (!linkOpened)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                    onPressed: () async {
                      linkOpened = true;
                      _waitingForAdResume = true;
                      setDialogState(() {});

                      final uri = Uri.parse(adLink);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (_) {}

                      // Countdown timer
                      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                        if (remaining > 0) {
                          setDialogState(() => remaining--);
                        } else {
                          timer.cancel();
                          Navigator.of(dialogContext, rootNavigator: true).pop();
                          if (mounted) setState(() => _adCompleted = true);
                        }
                      });
                    },
                    child: Text(AppStrings.t('continue')),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleWatchLater() {
    final cp = Provider.of<ContentProvider>(context, listen: false);
    cp.toggleWatchLater(widget.video.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cp.isWatchLater(widget.video.id) ? 'Saved to Watch Later' : 'Removed from Watch Later'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleShare() async {
    final settings = await DatabaseService().getAppSettings();
    final link = settings['appStoreLink'] ?? 'https://jiohotstar.app';
    Share.share('Watch "${widget.video.title}" on Jio Hotstar Premium! Download: $link');
  }

  void _handleDownload() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null || !PremiumHelper.isPremium(user)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading encrypted video for 7 days offline access...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    final isSaved = contentProvider.isWatchLater(widget.video.id);
    final authUser = Provider.of<AuthProvider>(context).currentUser;
    final bool canPlayVideo = PremiumHelper.canPlay(widget.video, authUser);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Container (16:9)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  CachedNetworkImage(
                    imageUrl: widget.video.thumbnailUrl.isNotEmpty
                        ? widget.video.thumbnailUrl
                        : 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800',
                    fit: BoxFit.cover,
                  ),

                  // Strict Paywall Lock Overlay if paid video and user is not premium
                  if (!canPlayVideo)
                    Container(
                      color: Colors.black.withOpacity(0.85),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD700),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock, color: Colors.black, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Premium VIP Video',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Active subscription required to watch this content.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.workspace_premium, size: 18),
                            label: const Text('Unlock for ₹1', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    // Dark player controls overlay
                    Container(
                      color: Colors.black38,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top bar inside player
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              // Speed selector
                              PopupMenuButton<double>(
                                icon: const Icon(Icons.speed, color: Colors.white),
                                tooltip: 'Playback Speed',
                                onSelected: (speed) => setState(() => _playbackSpeed = speed),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                                  const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
                                  const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                                  const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.white),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          // Center controls (10s back, play/pause, 10s forward)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                                onPressed: () {
                                  setState(() {
                                    _currentProgress = (_currentProgress - 0.05).clamp(0.0, 1.0);
                                  });
                                },
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: AppTheme.accent,
                                  size: 54,
                                ),
                                onPressed: () => setState(() => _isPlaying = !_isPlaying),
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                                onPressed: () {
                                  setState(() {
                                    _currentProgress = (_currentProgress + 0.05).clamp(0.0, 1.0);
                                  });
                                },
                              ),
                            ],
                          ),
                          // Bottom seekbar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppTheme.accent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: AppTheme.accent,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                value: _currentProgress,
                                onChanged: (val) => setState(() => _currentProgress = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Details & Recommendations
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.video.views} views • Today',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 16),

                    // Action Row (Watch Later, Share, Download, Report)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? AppTheme.accent : Colors.white,
                          label: AppStrings.t('watch_later'),
                          onTap: _handleWatchLater,
                        ),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          color: Colors.white,
                          label: AppStrings.t('share'),
                          onTap: _handleShare,
                        ),
                        _buildActionButton(
                          icon: Icons.download_outlined,
                          color: Colors.white,
                          label: AppStrings.t('download'),
                          onTap: _handleDownload,
                        ),
                        _buildActionButton(
                          icon: Icons.flag_outlined,
                          color: Colors.white,
                          label: AppStrings.t('report'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Issue reported to Jio Hotstar support.')),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF2B2B2B), height: 32),

                    // Description
                    if (widget.video.description.isNotEmpty) ...[
                      Text(
                        widget.video.description,
                        maxLines: _showDescription ? null : 2,
                        overflow: _showDescription ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showDescription = !_showDescription),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _showDescription ? 'Show less' : 'Show more',
                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // "More from this category"
                    Text(
                      AppStrings.t('more_from_category'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _moreVideos.isNotEmpty ? _moreVideos.length : 3,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (_moreVideos.isEmpty) {
                          return Container(
                            height: 70,
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                          );
                        }
                        final item = _moreVideos[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: item)),
                            );
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 120,
                                  height: 68,
                                  child: CachedNetworkImage(
                                    imageUrl: item.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(color: AppTheme.surface),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.views} views',
                                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.surface,
        icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.accent),
        label: const Text('Live Chat', style: TextStyle(color: Colors.white)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.surface,
            builder: (_) => Container(
              padding: const EdgeInsets.all(24),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.live_tv, size: 48, color: AppTheme.accent),
                  SizedBox(height: 12),
                  Text('Live Interactive Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Coming Soon in Step 3 — P2P Interactive Room', style: TextStyle(color: AppTheme.textGrey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }
}
