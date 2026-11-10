import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';

class ContentProvider extends ChangeNotifier {
  final DatabaseService _dbService;

  List<CategoryModel> _categories = [];
  List<VideoModel> _trendingVideos = [];
  List<VideoModel> _recentVideos = [];
  List<VideoModel> _allVideosCache = [];
  List<String> _watchLaterIds = [];
  Map<String, dynamic> _homeLayout = {};
  bool _isLoading = false;

  ContentProvider({DatabaseService? dbService}) : _dbService = dbService ?? DatabaseService() {
    loadWatchLaterIds();
  }

  List<CategoryModel> get categories => _categories;
  List<VideoModel> get trendingVideos => _trendingVideos;
  List<VideoModel> get recentVideos => _recentVideos;
  List<VideoModel> get allVideosCache => _allVideosCache;
  List<String> get watchLaterIds => _watchLaterIds;
  Map<String, dynamic> get homeLayout => _homeLayout;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.seedInitialDataIfEmpty();

      final results = await Future.wait([
        _dbService.getCategories(),
        _dbService.getTrendingVideos(limit: 10),
        _dbService.getVideos(limit: 20),
        _dbService.getHomeLayout(),
      ]);

      _categories = results[0] as List<CategoryModel>;
      _trendingVideos = results[1] as List<VideoModel>;
      _recentVideos = results[2] as List<VideoModel>;
      _allVideosCache = List.from(_recentVideos);
      _homeLayout = results[3] as Map<String, dynamic>;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWatchLaterIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _watchLaterIds = prefs.getStringList('watch_later_ids') ?? [];
      notifyListeners();
    } catch (_) {}
  }

  bool isWatchLater(String videoId) => _watchLaterIds.contains(videoId);

  Future<void> toggleWatchLater(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_watchLaterIds.contains(videoId)) {
      _watchLaterIds.remove(videoId);
    } else {
      _watchLaterIds.add(videoId);
    }
    await prefs.setStringList('watch_later_ids', _watchLaterIds);
    notifyListeners();
  }

  Future<List<VideoModel>> getWatchLaterVideos() async {
    final list = <VideoModel>[];
    for (final id in _watchLaterIds) {
      final vid = await _dbService.getVideoById(id);
      if (vid != null) list.add(vid);
    }
    return list;
  }
}
