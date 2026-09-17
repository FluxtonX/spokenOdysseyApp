class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? profession;
  final String? location;
  final String? relationship;
  final String? dateOfBirth;
  final String? birthDate;
  final List<String>? expertise;
  final String? lifeMotto;
  final String? firebaseUid;
  final int memoriesCount;
  final int albumsCount;
  final int followersCount;
  final int followingCount;
  final int familyCount;
  final bool isFollowing;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.profession,
    this.location,
    this.relationship,
    this.dateOfBirth,
    this.birthDate,
    this.expertise,
    this.lifeMotto,
    this.firebaseUid,
    this.memoriesCount = 0,
    this.albumsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.familyCount = 0,
    this.isFollowing = false,
  });
}
