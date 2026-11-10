import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/video_model.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';
import '../../services/lulustream_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final LuluStreamService _lulu = LuluStreamService();

  // Stats
  Map<String, int> _stats = {'totalUsers': 0, 'premiumUsers': 0, 'totalVideos': 0, 'totalCategories': 0};
  Map<String, dynamic>? _luluAccountInfo;
  List<VideoModel> _videos = [];
  List<Map<String, dynamic>> _liveEvents = [];
  List<CategoryModel> _categories = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _plans = [];

  // Ads Controllers
  final TextEditingController _normalAdController = TextEditingController();
  final TextEditingController _adultAdController = TextEditingController();
  final TextEditingController _adTimerController = TextEditingController(text: '5');
  bool _adsEnabled = true;

  // App Settings Controllers
  final TextEditingController _appStoreLinkController = TextEditingController();
  final TextEditingController _updateUrlController = TextEditingController();
  final TextEditingController _adminUpiController = TextEditingController();
  final TextEditingController _luluKeyController = TextEditingController();
  bool _forceUpdate = false;
  bool _maintenanceMode = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _normalAdController.dispose();
    _adultAdController.dispose();
    _adTimerController.dispose();
    _appStoreLinkController.dispose();
    _updateUrlController.dispose();
    _adminUpiController.dispose();
    _luluKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);

    final stats = await _db.getStats();
    final videos = await _db.getVideos(limit: 50);
    final liveEvents = await _db.getLiveEvents();
    final categories = await _db.getCategories();
    final homeLayout = await _db.getHomeLayout();
    final adSettings = await _db.getAdSettings();
    final appSettings = await _db.getAppSettings();
    final plans = await _db.getPlans();
    final luluKey = await _lulu.getApiKey() ?? '';
    final luluAccount = await _lulu.getAccountInfo();

    if (!mounted) return;

    setState(() {
      _stats = stats;
      _luluAccountInfo = luluAccount;
      _videos = videos;
      _liveEvents = liveEvents;
      _categories = categories;
      _sections = List<Map<String, dynamic>>.from(homeLayout['sections'] ?? []);
      _plans = plans;

      _normalAdController.text = adSettings['normalAdLink'] ?? '';
      _adultAdController.text = adSettings['adultAdLink'] ?? '';
      _adTimerController.text = (adSettings['adTimerSeconds'] ?? 5).toString();
      _adsEnabled = adSettings['adsEnabled'] ?? true;

      _appStoreLinkController.text = appSettings['appStoreLink'] ?? '';
      _updateUrlController.text = appSettings['updateUrl'] ?? '';
      _adminUpiController.text = appSettings['adminUPI'] ?? '';
      _luluKeyController.text = luluKey;
      _forceUpdate = appSettings['forceUpdate'] ?? false;
      _maintenanceMode = appSettings['maintenanceMode'] ?? false;

      _isLoading = false;
    });
  }

  // --- TAB 1: DASHBOARD ---
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('System Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.refresh, color: AppTheme.accent), onPressed: _loadAllAdminData),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('Total Users', _stats['totalUsers'].toString(), Icons.people, Colors.blue),
              _buildStatCard('Premium Users', _stats['premiumUsers'].toString(), Icons.star, const Color(0xFFFFD700)),
              _buildStatCard('Total Videos', _stats['totalVideos'].toString(), Icons.movie, Colors.purple),
              _buildStatCard('Live Streams', _liveEvents.length.toString(), Icons.live_tv, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 24),

          // LuluStream Account Status Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2B2B2B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_done, color: Colors.blue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'LuluStream Storage & CDN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (_luluAccountInfo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('NO KEY', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_luluAccountInfo != null) ...[
                  Text('Storage Used: ${_luluAccountInfo!['storage_used'] ?? "0 MB"}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Storage Left: ${_luluAccountInfo!['storage_left'] ?? "Unlimited"}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Balance: \$${_luluAccountInfo!['balance'] ?? "0.00"}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Account Type: ${_luluAccountInfo!['premium'] == 1 ? "Premium VIP" : "Standard Free"}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold)),
                ] else ...[
                  const Text(
                    'API key not configured yet. Go to App Settings tab and paste your LuluStream API key to view storage statistics and enable 1-click video uploads.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  // --- TAB 2: CONTENT MANAGER (with LuluStream Upload) ---
  Widget _buildContentManagerTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _videos.isEmpty
          ? const Center(child: Text('No videos in database. Click + to add.', style: TextStyle(color: AppTheme.textGrey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _videos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final video = _videos[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2B2B2B)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 80,
                          height: 45,
                          child: CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: Colors.black26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(video.isPaid ? 'PAID • ${video.views} views' : 'FREE • ${video.views} views', style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _openAddEditVideoDialog(existing: video),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.accent, size: 20),
                        onPressed: () async {
                          await _db.deleteVideo(video.id);
                          _loadAllAdminData();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        onPressed: () => _openAddEditVideoDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openAddEditVideoDialog({VideoModel? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final thumbCtrl = TextEditingController(text: existing?.thumbnailUrl ?? '');
    final cdnCtrl = TextEditingController(text: existing?.cdnUrl ?? '');
    final luluUrlCtrl = TextEditingController();

    File? pickedVideoFile;
    File? pickedThumbFile;
    String? pickedVideoFileName;

    String categoryId = existing?.categoryId ?? (_categories.isNotEmpty ? _categories.first.id : '');
    bool isPaid = existing?.isPaid ?? false;
    bool isTrending = existing?.isTrending ?? false;
    bool isLive = existing?.isLive ?? false;
    bool isDownloadable = existing?.isDownloadable ?? true;

    double uploadProgress = 0.0;
    bool isUploading = false;
    int uploadTab = 0; // 0 = Device Upload, 1 = URL Import

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
          bool isLuluExpanded = true;
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(existing == null ? 'Add Video to Firebase' : 'Edit Video', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Title *', labelStyle: TextStyle(color: AppTheme.textGrey)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppTheme.textGrey)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: thumbCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Thumbnail URL',
                        labelStyle: TextStyle(color: AppTheme.textGrey),
                        hintText: 'http://img.lulustream.com/... or image URL',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- EXPANDABLE SECTION ABOVE "CDN Stream URL" ---
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A23),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withOpacity(0.35)),
                      ),
                      child: Theme(
                        data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 22),
                          title: const Text(
                            'Upload via LuluStream (Optional)',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          children: [
                            // Two tabs: [Device Upload] and [URL Import]
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(child: Text('Device Upload', style: TextStyle(fontSize: 12))),
                                    selected: uploadTab == 0,
                                    selectedColor: Colors.blue.withOpacity(0.3),
                                    onSelected: (_) => setDialogState(() => uploadTab = 0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(child: Text('URL Import', style: TextStyle(fontSize: 12))),
                                    selected: uploadTab == 1,
                                    selectedColor: Colors.blue.withOpacity(0.3),
                                    onSelected: (_) => setDialogState(() => uploadTab = 1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Tab 1: Device Upload
                            if (uploadTab == 0) ...[
                              // Button 1: Pick Video File
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFF3B4A5A)),
                                  ),
                                  icon: const Icon(Icons.video_file_outlined, size: 18, color: Colors.blue),
                                  label: Text(
                                    pickedVideoFileName != null ? 'Selected: $pickedVideoFileName' : 'Pick Video File',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          try {
                                            final result = await FilePicker.platform.pickFiles(type: FileType.video);
                                            if (result != null && result.files.single.path != null) {
                                              setDialogState(() {
                                                pickedVideoFile = File(result.files.single.path!);
                                                pickedVideoFileName = result.files.single.name;
                                              });
                                            }
                                          } catch (_) {}
                                        },
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Button 2: Pick Thumbnail
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFF3B4A5A)),
                                  ),
                                  icon: const Icon(Icons.image_outlined, size: 18, color: Colors.greenAccent),
                                  label: Text(
                                    pickedThumbFile != null ? 'Thumbnail Selected ✓' : 'Pick Thumbnail',
                                  ),
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          try {
                                            final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                                            if (image != null) {
                                              setDialogState(() {
                                                pickedThumbFile = File(image.path);
                                              });
                                            }
                                          } catch (_) {}
                                        },
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Button 3: Upload to LuluStream
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  icon: const Icon(Icons.upload, size: 18),
                                  label: Text(isUploading ? 'Uploading to LuluStream...' : 'Upload to LuluStream'),
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          if (titleCtrl.text.trim().isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please enter Title first.')),
                                            );
                                            return;
                                          }
                                          if (pickedVideoFile == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please select a video file using "Pick Video File".')),
                                            );
                                            return;
                                          }
                                          setDialogState(() {
                                            isUploading = true;
                                            uploadProgress = 0.1;
                                          });
                                          try {
                                            String? filecode = await LuluStreamService.uploadVideo(
                                              pickedVideoFile!,
                                              pickedThumbFile,
                                              titleCtrl.text.trim(),
                                              descCtrl.text.trim(),
                                              false,
                                            );

                                            if (filecode != null) {
                                              cdnCtrl.text = "https://lulustream.com/$filecode.html";
                                              thumbCtrl.text = "http://img.lulustream.com/$filecode.jpg";

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Uploaded Successfully! Filecode: $filecode"),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(seconds: 4),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Upload Failed. Check API Key."),
                                                  backgroundColor: AppTheme.accent,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.accent),
                                            );
                                          } finally {
                                            setDialogState(() => isUploading = false);
                                          }
                                        },
                                ),
                              ),
                              if (isUploading) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: uploadProgress > 0 ? uploadProgress : null,
                                  color: Colors.blue,
                                  backgroundColor: const Color(0xFF2B2B2B),
                                ),
                              ],
                            ] else ...[
                              // Tab 2: URL Import
                              TextField(
                                controller: luluUrlCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Paste Video URL',
                                  labelStyle: TextStyle(color: AppTheme.textGrey),
                                  hintText: 'https://example.com/movie.mp4',
                                  prefixIcon: Icon(Icons.link, color: Colors.blue, size: 18),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  icon: const Icon(Icons.download, size: 18),
                                  label: Text(isUploading ? 'Importing from URL...' : 'Import from URL'),
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          if (luluUrlCtrl.text.trim().isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please paste a video URL.')),
                                            );
                                            return;
                                          }
                                          setDialogState(() => isUploading = true);
                                          try {
                                            final result = await _lulu.uploadFromUrl(
                                              videoUrl: luluUrlCtrl.text.trim(),
                                              title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Imported Video',
                                              description: descCtrl.text.trim(),
                                            );

                                            if (result.success && result.filecode != null) {
                                              cdnCtrl.text = _lulu.getCdnUrl(result.filecode!);
                                              thumbCtrl.text = _lulu.getThumbnailUrl(result.filecode!);

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Filecode: ${result.filecode} — ${result.message}'),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(seconds: 4),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('URL import failed: ${result.message}'),
                                                  backgroundColor: AppTheme.accent,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.accent),
                                            );
                                          } finally {
                                            setDialogState(() => isUploading = false);
                                          }
                                        },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CDN Stream URL (Auto-filled by LuluStream or entered manually)
                    TextField(
                      controller: cdnCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'CDN Stream URL *',
                        labelStyle: TextStyle(color: AppTheme.textGrey),
                        hintText: 'https://lulustream.com/abcd123.html or .mp4 / .m3u8',
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: categoryId.isNotEmpty && _categories.any((c) => c.id == categoryId) ? categoryId : _categories.first.id,
                        dropdownColor: AppTheme.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: AppTheme.textGrey)),
                        items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => setDialogState(() => categoryId = val ?? ''),
                      ),

                    const SizedBox(height: 10),
                    // Paid/Premium toggle
                    SwitchListTile(
                      title: const Text('Is Premium / Paid', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: isPaid,
                      activeColor: AppTheme.accent,
                      onChanged: (v) => setDialogState(() => isPaid = v),
                    ),
                    SwitchListTile(
                      title: const Text('Is Trending', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: isTrending,
                      activeColor: AppTheme.accent,
                      onChanged: (v) => setDialogState(() => isTrending = v),
                    ),
                    SwitchListTile(
                      title: const Text('Is Live Stream', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: isLive,
                      activeColor: AppTheme.accent,
                      onChanged: (v) => setDialogState(() => isLive = v),
                    ),
                    SwitchListTile(
                      title: const Text('Allow Download', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: isDownloadable,
                      activeColor: AppTheme.accent,
                      onChanged: (v) => setDialogState(() => isDownloadable = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || cdnCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and CDN Stream URL are required.')));
                    return;
                  }
                final model = VideoModel(
                  id: existing?.id ?? '',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  thumbnailUrl: thumbCtrl.text.trim().isNotEmpty ? thumbCtrl.text.trim() : 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
                  cdnUrl: cdnCtrl.text.trim(),
                  categoryId: categoryId,
                  isPaid: isPaid,
                  isTrending: isTrending,
                  isLive: isLive,
                  isDownloadable: isDownloadable,
                );

                if (existing == null) {
                  await _db.addVideo(model);
                } else {
                  await _db.updateVideo(existing.id, model.toMap());
                }
                Navigator.pop(ctx);
                _loadAllAdminData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: LIVE STREAMS (Section C Implementation) ---
  Widget _buildLiveStreamsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _liveEvents.isEmpty
          ? const Center(child: Text('No active live streams. Click + to add.', style: TextStyle(color: AppTheme.textGrey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _liveEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = _liveEvents[index];
                final isLive = event['isLive'] == true;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isLive ? Colors.red.withOpacity(0.5) : const Color(0xFF2B2B2B)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive ? Colors.red : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLive ? 'LIVE' : 'ENDED',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['title']?.toString() ?? 'Event', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(event['streamUrl']?.toString() ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 11), maxLines: 1),
                          ],
                        ),
                      ),
                      Switch(
                        value: isLive,
                        activeColor: Colors.red,
                        onChanged: (val) async {
                          await _db.toggleLiveEvent(event['id'], val);
                          _loadAllAdminData();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.accent),
                        onPressed: () async {
                          await _db.deleteLiveEvent(event['id']);
                          _loadAllAdminData();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: _openAddLiveEventDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openAddLiveEventDialog() {
    final titleCtrl = TextEditingController();
    final thumbCtrl = TextEditingController();
    final streamCtrl = TextEditingController();
    bool isLive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Add Live Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Event Title', labelStyle: TextStyle(color: AppTheme.textGrey))),
              TextField(controller: thumbCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Thumbnail URL', labelStyle: TextStyle(color: AppTheme.textGrey))),
              TextField(controller: streamCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stream URL (.m3u8 / RTMP)', labelStyle: TextStyle(color: AppTheme.textGrey))),
              SwitchListTile(title: const Text('Is Live Now', style: TextStyle(color: Colors.white)), value: isLive, activeColor: Colors.red, onChanged: (v) => setDialogState(() => isLive = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty && streamCtrl.text.isNotEmpty) {
                  await _db.addLiveEvent(
                    titleCtrl.text.trim(),
                    thumbCtrl.text.trim().isNotEmpty ? thumbCtrl.text.trim() : 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
                    streamCtrl.text.trim(),
                    DateTime.now().millisecondsSinceEpoch,
                    isLive,
                  );
                  Navigator.pop(ctx);
                  _loadAllAdminData();
                }
              },
              child: const Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 4: CATEGORIES ---
  Widget _buildCategoriesTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Order: ${cat.order} • ${cat.isAdult ? "🔞 ADULT" : "STANDARD"} • ${cat.isPaid ? "PAID" : "FREE"}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.accent),
                  onPressed: () async {
                    await _db.deleteCategory(cat.id);
                    _loadAllAdminData();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        onPressed: _openAddCategoryDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '1');
    bool isPaid = false;
    bool isAdult = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Add Category', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppTheme.textGrey))),
              TextField(controller: orderCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Display Order', labelStyle: TextStyle(color: AppTheme.textGrey))),
              SwitchListTile(title: const Text('Is Paid', style: TextStyle(color: Colors.white)), value: isPaid, activeColor: AppTheme.accent, onChanged: (v) => setDialogState(() => isPaid = v)),
              SwitchListTile(title: const Text('Is 18+ Adult', style: TextStyle(color: Colors.white)), value: isAdult, activeColor: AppTheme.accent, onChanged: (v) => setDialogState(() => isAdult = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  await _db.addCategory(nameCtrl.text.trim(), isPaid, int.tryParse(orderCtrl.text) ?? 0, isAdult);
                  Navigator.pop(ctx);
                  _loadAllAdminData();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 5: HOME LAYOUT ---
  Widget _buildHomeLayoutTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ReorderableListView(
        padding: const EdgeInsets.all(16),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _sections.removeAt(oldIndex);
            _sections.insert(newIndex, item);
          });
          _db.saveHomeSections(_sections);
        },
        children: [
          for (int i = 0; i < _sections.length; i++)
            Container(
              key: ValueKey(i),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.drag_handle, color: AppTheme.textGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_sections[i]['title']?.toString() ?? 'Section', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Type: ${_sections[i]['type']} • Source: ${_sections[i]['source'] ?? ""}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.accent, size: 20),
                    onPressed: () {
                      setState(() => _sections.removeAt(i));
                      _db.saveHomeSections(_sections);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- TAB 6: ADS ---
  Widget _buildAdsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ad Monetization & Sponsorships', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('URLs are encrypted with AES-256 before writing to Firebase.', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 20),
          TextField(controller: _normalAdController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Normal Sponsored Link (URL)', labelStyle: TextStyle(color: AppTheme.textGrey))),
          const SizedBox(height: 14),
          TextField(controller: _adultAdController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Adult Sponsored Link (URL)', labelStyle: TextStyle(color: AppTheme.textGrey))),
          const SizedBox(height: 14),
          TextField(controller: _adTimerController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Ad Timer (Seconds)', labelStyle: TextStyle(color: AppTheme.textGrey))),
          const SizedBox(height: 10),
          SwitchListTile(title: const Text('Enable In-App Ads', style: TextStyle(color: Colors.white)), value: _adsEnabled, activeColor: AppTheme.accent, onChanged: (v) => setState(() => _adsEnabled = v)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () async {
                await _db.saveAdSettings(
                  normalAdLink: _normalAdController.text.trim(),
                  adultAdLink: _adultAdController.text.trim(),
                  timerSeconds: int.tryParse(_adTimerController.text) ?? 5,
                  enabled: _adsEnabled,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad settings encrypted & saved!')));
              },
              child: const Text('Encrypt & Save Ads'),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 7: PLANS ---
  Widget _buildPlansTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan['name']?.toString() ?? 'Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₹${plan['price']} • ${plan['durationDays']} Days', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.accent),
                  onPressed: () async {
                    await _db.deletePlan(plan['id'] ?? '');
                    _loadAllAdminData();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- TAB 8: APP SETTINGS (with LuluStream Key Field) ---
  Widget _buildAppSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: _appStoreLinkController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'App Store / Download Link', labelStyle: TextStyle(color: AppTheme.textGrey))),
          const SizedBox(height: 12),
          TextField(controller: _updateUrlController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Update URL', labelStyle: TextStyle(color: AppTheme.textGrey))),
          const SizedBox(height: 12),
          TextField(controller: _adminUpiController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Admin UPI ID', labelStyle: TextStyle(color: AppTheme.textGrey))),
          const SizedBox(height: 16),

          // LuluStream Key Field
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LuluStream API Configuration', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _luluKeyController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'LuluStream API Key',
                    labelStyle: TextStyle(color: AppTheme.textGrey),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () async {
                        await _lulu.saveApiKey(_luluKeyController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LuluStream API Key securely saved!')));
                        _loadAllAdminData();
                      },
                      child: const Text('Save Key'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        await _lulu.clearApiKey();
                        _luluKeyController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LuluStream Key cleared.')));
                        _loadAllAdminData();
                      },
                      child: const Text('Clear Key', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          SwitchListTile(title: const Text('Force Update', style: TextStyle(color: Colors.white)), value: _forceUpdate, activeColor: AppTheme.accent, onChanged: (v) => setState(() => _forceUpdate = v)),
          SwitchListTile(title: const Text('Maintenance Mode', style: TextStyle(color: Colors.white)), value: _maintenanceMode, activeColor: AppTheme.accent, onChanged: (v) => setState(() => _maintenanceMode = v)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () async {
                await _db.saveAppSettings({
                  'appStoreLink': _appStoreLinkController.text.trim(),
                  'updateUrl': _updateUrlController.text.trim(),
                  'adminUPI': _adminUpiController.text.trim(),
                  'forceUpdate': _forceUpdate,
                  'maintenanceMode': _maintenanceMode,
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App settings saved to Firebase!')));
              },
              child: const Text('Save App Settings'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: const Text('Jio Hotstar Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textGrey,
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Content'),
              Tab(text: 'Live Streams'),
              Tab(text: 'Categories'),
              Tab(text: 'Layout'),
              Tab(text: 'Ads'),
              Tab(text: 'Plans'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : TabBarView(
                children: [
                  _buildDashboardTab(),
                  _buildContentManagerTab(),
                  _buildLiveStreamsTab(),
                  _buildCategoriesTab(),
                  _buildHomeLayoutTab(),
                  _buildAdsTab(),
                  _buildPlansTab(),
                  _buildAppSettingsTab(),
                ],
              ),
      ),
    );
  }
}
