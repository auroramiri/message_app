class UserModel {
  final String username;
  final String uid;
  final String profileImageUrl;
  final bool active;
  final int lastSeen;
  final String phoneNumber;
  final List<String> groupId;
  final bool isAdmin;
  final String fcmToken;
  final String? rsaPublicKeyPem;

  UserModel({
    required this.username,
    required this.uid,
    required this.profileImageUrl,
    required this.active,
    required this.lastSeen,
    required this.phoneNumber,
    required this.groupId,
    this.isAdmin = false,
    required this.fcmToken,
    this.rsaPublicKeyPem,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'uid': uid,
      'profileImageUrl': profileImageUrl,
      'active': active,
      'lastSeen': lastSeen,
      'phoneNumber': phoneNumber,
      'groupId': groupId,
      'isAdmin': isAdmin,
      'fcmToken': fcmToken,
      'rsaPublicKeyPem': rsaPublicKeyPem,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'] ?? '',
      uid: map['uid'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      active: map['active'] ?? false,
      lastSeen: map['lastSeen'] ?? 0,
      phoneNumber: map['phoneNumber'] ?? '',
      groupId: List<String>.from(map['groupId'] ?? []),
      isAdmin: map['isAdmin'] ?? false,
      fcmToken: map['fcmToken'] ?? '',
      rsaPublicKeyPem: map['rsaPublicKeyPem'],
    );
  }
}
