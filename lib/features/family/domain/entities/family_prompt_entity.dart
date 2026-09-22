class FamilyPromptResponse {
  final String id;
  final String? text;
  final String? audioUrl;
  final String? userName;
  final String? userAvatar;
  final DateTime? createdAt;

  const FamilyPromptResponse({
    required this.id,
    this.text,
    this.audioUrl,
    this.userName,
    this.userAvatar,
    this.createdAt,
  });

  factory FamilyPromptResponse.fromJson(Map<String, dynamic> json) {
    final user =
        json['user'] as Map<String, dynamic>? ??
        json['createdBy'] as Map<String, dynamic>?;
    return FamilyPromptResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String?,
      audioUrl: json['audioUrl'] as String? ?? json['audioKey'] as String?,
      userName:
          user?['displayName'] as String? ??
          user?['name'] as String? ??
          'Family Member',
      userAvatar: user?['photoURL'] as String? ?? user?['avatar'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class FamilyPromptEntity {
  final String id;
  final String familyCircleId;
  final String question;
  final String category;
  final String? audioUrl;
  final String? creatorName;
  final String? creatorAvatar;
  final DateTime? createdAt;
  final List<FamilyPromptResponse> responses;

  const FamilyPromptEntity({
    required this.id,
    required this.familyCircleId,
    required this.question,
    required this.category,
    this.audioUrl,
    this.creatorName,
    this.creatorAvatar,
    this.createdAt,
    this.responses = const [],
  });

  factory FamilyPromptEntity.fromJson(Map<String, dynamic> json) {
    final creator =
        json['createdBy'] as Map<String, dynamic>? ??
        json['creator'] as Map<String, dynamic>?;

    final rawResponses = json['responses'] as List? ?? [];
    final parsedResponses = rawResponses
        .whereType<Map<String, dynamic>>()
        .map((r) => FamilyPromptResponse.fromJson(r))
        .toList();

    return FamilyPromptEntity(
      id: json['id']?.toString() ?? '',
      familyCircleId: json['familyCircleId']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      category: json['category'] as String? ?? 'Heritage',
      audioUrl: json['audioUrl'] as String? ?? json['audioKey'] as String?,
      creatorName:
          creator?['displayName'] as String? ??
          creator?['name'] as String? ??
          'Family Member',
      creatorAvatar:
          creator?['photoURL'] as String? ?? creator?['avatar'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      responses: parsedResponses,
    );
  }
}
