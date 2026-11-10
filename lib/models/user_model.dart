class UserModel {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final String plan; // 'free', 'premium', etc.
  final int planExpiry; // Timestamp in ms
  final bool isAdmin;
  final bool trialUsed; // True if ₹1 trial was already used
  final String adultPasswordHash;
  final int createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.name = '',
    this.photoUrl = '',
    this.plan = 'free',
    this.planExpiry = 0,
    this.isAdmin = false,
    this.trialUsed = false,
    this.adultPasswordHash = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString() ?? '',
      plan: map['plan']?.toString() ?? 'free',
      planExpiry: (map['planExpiry'] is int)
          ? map['planExpiry'] as int
          : int.tryParse(map['planExpiry']?.toString() ?? '0') ?? 0,
      isAdmin: map['isAdmin'] == true,
      trialUsed: map['trialUsed'] == true,
      adultPasswordHash: map['adultPasswordHash']?.toString() ?? '',
      createdAt: (map['createdAt'] is int)
          ? map['createdAt'] as int
          : int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'plan': plan,
      'planExpiry': planExpiry,
      'isAdmin': isAdmin,
      'trialUsed': trialUsed,
      'adultPasswordHash': adultPasswordHash,
      'createdAt': createdAt,
    };
  }

  bool get isPremiumActive {
    return plan == 'premium' && planExpiry > DateTime.now().millisecondsSinceEpoch;
  }
}
