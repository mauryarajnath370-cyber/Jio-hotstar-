import 'package:firebase_database/firebase_database.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/video_model.dart';
import '../models/category_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/encryption_helper.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: AppConstants.rtdbUrl,
  );

  DatabaseReference get _rootRef => _db.ref();

  // Seed Initial Database Data if empty
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final snapshot = await _rootRef.child('categories').get();
      if (!snapshot.exists || snapshot.value == null) {
        final seedData = {
          "categories": {
            "-Ncat1": {"name": "Trending", "isPaid": false, "order": 0, "isAdult": false},
            "-Ncat2": {"name": "Movies", "isPaid": false, "order": 1, "isAdult": false},
            "-Ncat3": {"name": "Web Series", "isPaid": false, "order": 2, "isAdult": false},
            "-Ncat4": {"name": "Adult", "isPaid": false, "order": 99, "isAdult": true}
          },
          "home_layout": {
            "sections": [
              {"type": "carousel", "title": "Live Events", "source": "live_events", "order": 0},
              {"type": "row", "title": "Trending", "source": "videos", "filter": "trending", "order": 1},
              {"type": "row", "title": "Movies", "source": "videos", "category": "-Ncat2", "order": 2},
              {"type": "row", "title": "Web Series", "source": "videos", "category": "-Ncat3", "order": 3},
              {"type": "adult_card", "title": "Adult", "order": 99}
            ]
          },
          "live_events": {
            "-live1": {
              "title": "ICC World Cup 2026: Live Mega Match",
              "thumbnailUrl": "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800",
              "streamUrl": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
              "startTime": DateTime.now().millisecondsSinceEpoch,
              "isLive": true
            }
          },
          "settings": {
            "ads": {
              "normalAdLink": "",
              "adultAdLink": "",
              "adTimerSeconds": 5,
              "adsEnabled": true
            },
            "app": {
              "appStoreLink": "https://jiohotstar.app/download",
              "updateUrl": "https://jiohotstar.app/update",
              "forceUpdate": false,
              "maintenanceMode": false,
              "minVersion": "1.0.0",
              "adminUPI": "hotstar@upi"
            }
          },
          "plans": {
            "trial_1rs": {
              "id": "trial_1rs",
              "name": "₹1 Premium Trial",
              "price": 1,
              "durationDays": 1,
              "order": 0,
              "isTrial": true
            },
            "-plan1": {"name": "1 Month", "price": 99, "durationDays": 30, "order": 1},
            "-plan2": {"name": "3 Months", "price": 249, "durationDays": 90, "order": 2, "isPopular": true},
            "-plan3": {"name": "1 Year", "price": 899, "durationDays": 365, "order": 3}
          }
        };
        await _rootRef.update(seedData);
      }
    } catch (_) {}
  }

  // --- Live Streams ---
  Future<List<Map<String, dynamic>>> getLiveEvents() async {
    try {
      final snapshot = await _rootRef.child('live_events').get();
      if (!snapshot.exists || snapshot.value == null) return [];
      final list = <Map<String, dynamic>>[];
      if (snapshot.value is Map) {
        final map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, val) {
          if (val is Map) {
            final item = Map<String, dynamic>.from(val);
            item['id'] = key.toString();
            list.add(item);
          }
        });
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<String> addLiveEvent(String title, String thumbnailUrl, String streamUrl, int startTime, bool isLive) async {
    final ref = _rootRef.child('live_events').push();
    await ref.set({
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'streamUrl': streamUrl,
      'startTime': startTime,
      'isLive': isLive,
      'createdAt': ServerValue.timestamp,
    });
    return ref.key ?? '';
  }

  Future<void> deleteLiveEvent(String id) async {
    await _rootRef.child('live_events/$id').remove();
  }

  Future<void> toggleLiveEvent(String id, bool isLive) async {
    await _rootRef.child('live_events/$id/isLive').set(isLive);
  }

  Future<List<VideoModel>> getVideos({int limit = 20, String? startAfterKey}) async {
    Query query = _rootRef.child('videos').orderByKey();
    if (startAfterKey != null) {
      query = query.startAfter(startAfterKey);
    }
    query = query.limitToFirst(limit);

    final snapshot = await query.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final list = <VideoModel>[];
    if (snapshot.value is Map) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        if (value is Map) {
          list.add(VideoModel.fromMap(key.toString(), value));
        }
      });
    }
    return list;
  }

  Future<VideoModel?> getVideoById(String id) async {
    try {
      final snapshot = await _rootRef.child('videos/$id').get();
      if (snapshot.exists && snapshot.value is Map) {
        return VideoModel.fromMap(id, snapshot.value as Map<dynamic, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _rootRef.child('categories').orderByChild('order').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final list = <CategoryModel>[];
    if (snapshot.value is Map) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        if (value is Map) {
          list.add(CategoryModel.fromMap(key.toString(), value));
        }
      });
      list.sort((a, b) => a.order.compareTo(b.order));
    }
    return list;
  }

  Future<Map<String, dynamic>> getHomeLayout() async {
    final snapshot = await _rootRef.child('home_layout').get();
    if (snapshot.exists && snapshot.value is Map) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {
      'sections': [
        {"type": "carousel", "title": "Live Events", "source": "live_events", "order": 0},
        {"type": "row", "title": "Trending", "source": "videos", "filter": "trending", "order": 1},
        {"type": "adult_card", "title": "Adult Content", "order": 99}
      ],
    };
  }

  Future<Map<String, dynamic>> getAdSettings() async {
    final snapshot = await _rootRef.child('settings/ads').get();
    if (!snapshot.exists || snapshot.value == null) {
      return {
        'normalAdLink': '',
        'adultAdLink': '',
        'adTimerSeconds': 5,
        'adsEnabled': true,
      };
    }

    final raw = snapshot.value as Map<dynamic, dynamic>;
    final normalEnc = raw['normalAdLink']?.toString() ?? '';
    final adultEnc = raw['adultAdLink']?.toString() ?? '';
    final timer = int.tryParse(raw['adTimerSeconds']?.toString() ?? '5') ?? 5;
    final enabled = raw['adsEnabled'] != false;

    return {
      'normalAdLink': normalEnc.isNotEmpty ? EncryptionHelper.decrypt(normalEnc) : '',
      'adultAdLink': adultEnc.isNotEmpty ? EncryptionHelper.decrypt(adultEnc) : '',
      'adTimerSeconds': timer,
      'adsEnabled': enabled,
    };
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    final snapshot = await _rootRef.child('settings/app').get();
    if (snapshot.exists && snapshot.value is Map) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {
      'appName': AppConstants.appName,
      'appStoreLink': 'https://jiohotstar.app/download',
      'updateUrl': 'https://jiohotstar.app/update',
      'forceUpdate': false,
      'maintenanceMode': false,
      'minVersion': '1.0.0',
      'adminUPI': 'hotstar@upi',
    };
  }

  static Future<String> getAdminUPI() async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: AppConstants.rtdbUrl,
      );
      final snapshot = await db.ref('settings/app/adminUPI').get();
      return snapshot.value?.toString() ?? 'hotstar@upi';
    } catch (_) {
      return 'hotstar@upi';
    }
  }

  Future<List<VideoModel>> getVideosByCategory(String categoryId, {int limit = 10, String? excludeId}) async {
    final query = _rootRef
        .child('videos')
        .orderByChild('categoryId')
        .equalTo(categoryId)
        .limitToFirst(limit + (excludeId != null ? 1 : 0));

    final snapshot = await query.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final list = <VideoModel>[];
    if (snapshot.value is Map) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        if (value is Map && key.toString() != excludeId) {
          list.add(VideoModel.fromMap(key.toString(), value));
        }
      });
    }
    return list.take(limit).toList();
  }

  Future<List<VideoModel>> getTrendingVideos({int limit = 10}) async {
    final query = _rootRef
        .child('videos')
        .orderByChild('isTrending')
        .equalTo(true)
        .limitToFirst(limit);

    final snapshot = await query.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final list = <VideoModel>[];
    if (snapshot.value is Map) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        if (value is Map) {
          list.add(VideoModel.fromMap(key.toString(), value));
        }
      });
    }
    return list;
  }

  // --- Admin CRUD Operations ---
  Future<String> addVideo(VideoModel video) async {
    final newRef = _rootRef.child('videos').push();
    final data = video.toMap();
    data['createdAt'] = ServerValue.timestamp;
    data['views'] = 0;
    await newRef.set(data);
    return newRef.key ?? '';
  }

  Future<void> updateVideo(String id, Map<String, dynamic> data) async {
    await _rootRef.child('videos/$id').update(data);
  }

  Future<void> deleteVideo(String id) async {
    await _rootRef.child('videos/$id').remove();
  }

  Future<void> addCategory(String name, bool isPaid, int order, bool isAdult) async {
    final newRef = _rootRef.child('categories').push();
    await newRef.set({
      'name': name,
      'isPaid': isPaid,
      'order': order,
      'isAdult': isAdult,
    });
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _rootRef.child('categories/$id').update(data);
  }

  Future<void> deleteCategory(String id) async {
    await _rootRef.child('categories/$id').remove();
  }

  Future<void> saveHomeSections(List<Map<String, dynamic>> sections) async {
    await _rootRef.child('home_layout/sections').set(sections);
  }

  Future<void> saveAdSettings({
    required String normalAdLink,
    required String adultAdLink,
    required int timerSeconds,
    required bool enabled,
  }) async {
    final normalEnc = normalAdLink.isNotEmpty ? EncryptionHelper.encrypt(normalAdLink) : '';
    final adultEnc = adultAdLink.isNotEmpty ? EncryptionHelper.encrypt(adultAdLink) : '';

    await _rootRef.child('settings/ads').set({
      'normalAdLink': normalEnc,
      'adultAdLink': adultEnc,
      'adTimerSeconds': timerSeconds,
      'adsEnabled': enabled,
    });
  }

  Future<List<Map<String, dynamic>>> getPlans() async {
    final snapshot = await _rootRef.child('plans').get();
    final list = <Map<String, dynamic>>[];
    if (snapshot.exists && snapshot.value is Map) {
      final map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        if (value is Map) {
          final item = Map<String, dynamic>.from(value);
          item['id'] = key.toString();
          list.add(item);
        }
      });
    }

    // Ensure ₹1 Premium Trial is present
    if (!list.any((p) => p['id'] == 'trial_1rs' || p['price'] == 1)) {
      list.insert(0, {
        'id': 'trial_1rs',
        'name': '₹1 Premium Trial',
        'price': 1,
        'durationDays': 1,
        'order': 0,
        'isTrial': true,
      });
      try {
        await _rootRef.child('plans/trial_1rs').set({
          'name': '₹1 Premium Trial',
          'price': 1,
          'durationDays': 1,
          'order': 0,
          'isTrial': true,
        });
      } catch (_) {}
    }

    list.sort((a, b) => ((a['order'] ?? 10) as num).compareTo((b['order'] ?? 10) as num));
    return list;
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _rootRef.child('orders/$orderId').remove();
    } catch (_) {}
  }

  Future<void> addPlan(String name, int price, int durationDays) async {
    final ref = _rootRef.child('plans').push();
    await ref.set({
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'order': 10,
    });
  }

  Future<void> deletePlan(String id) async {
    await _rootRef.child('plans/$id').remove();
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await _rootRef.child('settings/app').update(settings);
  }

  // Dashboard Stats
  Future<Map<String, int>> getStats() async {
    int totalUsers = 0;
    int premiumUsers = 0;
    int totalVideos = 0;
    int totalCategories = 0;

    try {
      final usersSnap = await _rootRef.child('users').get();
      if (usersSnap.exists && usersSnap.value is Map) {
        final users = usersSnap.value as Map;
        totalUsers = users.length;
        users.forEach((_, val) {
          if (val is Map && val['plan'] == 'premium') {
            premiumUsers++;
          }
        });
      }

      final videosSnap = await _rootRef.child('videos').get();
      if (videosSnap.exists && videosSnap.value is Map) {
        totalVideos = (videosSnap.value as Map).length;
      }

      final catSnap = await _rootRef.child('categories').get();
      if (catSnap.exists && catSnap.value is Map) {
        totalCategories = (catSnap.value as Map).length;
      }
    } catch (_) {}

    return {
      'totalUsers': totalUsers,
      'premiumUsers': premiumUsers,
      'totalVideos': totalVideos,
      'totalCategories': totalCategories,
    };
  }

  // Adult Password
  Future<void> setAdultPassword(String uid, String rawPassword) async {
    final bytes = utf8.encode(rawPassword);
    final hash = sha256.convert(bytes).toString();
    await _rootRef.child('users/$uid/adultPasswordHash').set(hash);
  }

  Future<bool> verifyAdultPassword(String uid, String rawPassword) async {
    final snapshot = await _rootRef.child('users/$uid/adultPasswordHash').get();
    if (!snapshot.exists || snapshot.value == null) return false;
    final storedHash = snapshot.value.toString();
    final bytes = utf8.encode(rawPassword);
    final inputHash = sha256.convert(bytes).toString();
    return storedHash == inputHash;
  }
}
