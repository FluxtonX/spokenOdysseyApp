import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.avatarUrl,
    super.bio,
    super.location,
    super.relationship,
    super.dateOfBirth,
    super.firebaseUid,
    super.memoriesCount = 0,
    super.albumsCount = 0,
    super.followersCount = 0,
    super.followingCount = 0,
    super.familyCount = 0,
    super.isFollowing = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['uid']?.toString() ?? '',
      email: json['email'] ?? json['ownerEmail'] ?? '',
      name: json['displayName'] ??
          json['name'] ??
          json['fullName'] ??
          json['ownerDisplayName'] ??
          json['userName'] ??
          json['username'] ??
          json['userDisplayName'] ??
          (json['email'] != null ? json['email'].toString().split('@').first : null),
      avatarUrl: json['photoURL'] ??
          json['avatarUrl'] ??
          json['avatar'] ??
          json['ownerAvatarUrl'] ??
          json['userAvatar'] ??
          json['photo'] ??
          json['profilePic'],
      bio: json['bio'],
      location: json['location'],
      relationship: json['relationship'],
      dateOfBirth: json['dateOfBirth'],
      firebaseUid: json['firebaseUid'] ?? json['uid'],
      memoriesCount: json['memoriesCount'] ?? json['stats']?['memories'] ?? 0,
      albumsCount: json['albumsCount'] ?? json['stats']?['albums'] ?? 0,
      followersCount: json['followersCount'] ?? json['stats']?['followers'] ?? 0,
      followingCount: json['followingCount'] ?? json['stats']?['following'] ?? 0,
      familyCount: json['familyCount'] ?? json['stats']?['family'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': name,
      'photoURL': avatarUrl,
      'bio': bio,
      'location': location,
      'relationship': relationship,
      'dateOfBirth': dateOfBirth,
      'firebaseUid': firebaseUid,
    };
  }
}
