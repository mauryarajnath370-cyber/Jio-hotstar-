class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String cdnUrl;
  final String categoryId;
  final bool isPaid;
  final bool isTrending;
  final bool isLive;
  final bool isDownloadable;
  final int views;
  final int createdAt;

  VideoModel({
    required this.id,
    required this.title,
    this.description = '',
    this.thumbnailUrl = '',
    required this.cdnUrl,
    this.categoryId = '',
    this.isPaid = false,
    this.isTrending = false,
    this.isLive = false,
    this.isDownloadable = true,
    this.views = 0,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory VideoModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return VideoModel(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? '',
      cdnUrl: map['cdnUrl']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      isPaid: map['isPaid'] == true,
      isTrending: map['isTrending'] == true,
      isLive: map['isLive'] == true,
      isDownloadable: map['isDownloadable'] != false,
      views: (map['views'] is int) ? map['views'] as int : int.tryParse(map['views']?.toString() ?? '0') ?? 0,
      createdAt: (map['createdAt'] is int) ? map['createdAt'] as int : int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'cdnUrl': cdnUrl,
      'categoryId': categoryId,
      'isPaid': isPaid,
      'isTrending': isTrending,
      'isLive': isLive,
      'isDownloadable': isDownloadable,
      'views': views,
      'createdAt': createdAt,
    };
  }
}
