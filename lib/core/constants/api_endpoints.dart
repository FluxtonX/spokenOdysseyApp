class ApiEndpoints {
  ApiEndpoints._();

  // Deployed AWS EC2 Production Backend URL (Identical to spoken-odyssey-web configuration)
  static const String liveProductionUrl =
      'http://ec2-13-206-196-136.ap-south-1.compute.amazonaws.com:5001/api';

  // Toggle this flag if you want to switch to local development backend
  static const bool useLiveProductionBackend = true;

  static String get baseUrl {
    if (useLiveProductionBackend) {
      return liveProductionUrl;
    }
    // Using specific local network IP on port 5001 (matching spoken-odyssey-web configuration)
    return 'http://192.168.1.18:5001/api';
  }

  // Auth & User Profile Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get googleLogin => '$baseUrl/auth/google';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get refreshToken => '$baseUrl/auth/refresh-token';
  static String get me => '$baseUrl/auth/me';
  static String get updateProfile => '$baseUrl/auth/profile';
  static String get changePassword => '$baseUrl/auth/change-password';
  static String get notificationPreferences =>
      '$baseUrl/auth/notifications/preferences';
  static String get activeSessions => '$baseUrl/auth/sessions';
  static String get revokeSession => '$baseUrl/auth/revoke-session';
  static String get mfaStatus => '$baseUrl/auth/mfa/status';
  static String get mfaSetup => '$baseUrl/auth/mfa/totp/setup';
  static String get mfaVerifySetup => '$baseUrl/auth/mfa/totp/verify-setup';
  static String get mfaDisable => '$baseUrl/auth/mfa/disable';

  // User & Social Endpoints
  static String get usersDiscovery => '$baseUrl/users/discovery';
  static String get usersFeatured => '$baseUrl/users/featured';
  static String get followers => '$baseUrl/users/followers';
  static String get following => '$baseUrl/users/following';
  static String followUser(String targetUid) =>
      '$baseUrl/users/follow/$targetUid';
  static String userProfileById(String userId) => '$baseUrl/users/$userId';

  // Memories Endpoints
  static String get memories => '$baseUrl/memories';
  static String get memoriesFeed => '$baseUrl/memories/feed';
  static String get memoriesDiscovery => '$baseUrl/memories/discovery';
  static String memoryById(String id) => '$baseUrl/memories/$id';
  static String memoryInteract(String id) => '$baseUrl/memories/$id/interact';
  static String memoryShare(String id) => '$baseUrl/memories/$id/share';
  static String memoryReact(String id) => '$baseUrl/memories/$id/react';
  static String memoryComments(String id) => '$baseUrl/memories/$id/comments';
  static String commentReact(String memoryId, String commentId) =>
      '$baseUrl/memories/$memoryId/comments/$commentId/react';

  // Albums Endpoints
  static String get albums => '$baseUrl/albums';
  static String albumById(String id) => '$baseUrl/albums/$id';

  // Family Circle & Invitations
  static String get familyCircle => '$baseUrl/family-circle';
  static String familyPrompts(String circleId) =>
      '$baseUrl/family-circle/$circleId/prompts';
  static String respondFamilyPrompt(String promptId) =>
      '$baseUrl/family-circle/prompts/$promptId/respond';
  static String get familyCircleMembers => '$baseUrl/family-circle/members';
  static String get familySharedMemories =>
      '$baseUrl/family-circle/shared-memories';
  static String get familyIsAdmin => '$baseUrl/family-circle/is-admin';
  static String get familyPendingApprovals =>
      '$baseUrl/family-circle/pending-approvals';
  static String approveFamilyInvitation(String id) =>
      '$baseUrl/family-circle/approvals/$id/approve';
  static String declineFamilyApproval(String id) =>
      '$baseUrl/family-circle/approvals/$id/decline';
  static String promoteFamilyMember(String id) =>
      '$baseUrl/family-circle/members/$id/promote';
  static String demoteFamilyMember(String id) =>
      '$baseUrl/family-circle/members/$id/demote';
  static String removeFamilyMember(String id) =>
      '$baseUrl/family-circle/members/$id';

  static String get usersFamily => '$baseUrl/users/family';
  static String usersTaggable([String query = '']) =>
      '$baseUrl/users/taggable?query=${Uri.encodeComponent(query)}';
  static String get familyInvitationsSms =>
      '$baseUrl/users/family/invitations/sms';
  static String get familyInvitationsLink =>
      '$baseUrl/users/family/invitations/link';
  static String get familyInvitationsQr =>
      '$baseUrl/users/family/invitations/qr';
  static String get familyInvitations => '$baseUrl/users/family/invitations';
  static String acceptFamilyInvite(String id) =>
      '$baseUrl/users/family/invitations/$id/accept';
  static String declineFamilyInvite(String id) =>
      '$baseUrl/users/family/invitations/$id/decline';
  static String get familyBadgeCount => '$baseUrl/users/family/badge-count';
  static String get familyMarkSeen => '$baseUrl/users/family/mark-seen';
  static String validateInvitationToken(String token) =>
      '$baseUrl/users/family/invitations/validate?token=${Uri.encodeComponent(token)}';

  // Search & Notifications & Legacy
  static String get search => '$baseUrl/search';
  static String get notifications => '$baseUrl/notifications';
  static String get notificationsUnreadCount =>
      '$baseUrl/notifications/unread-count';
  static String notificationRead(String id) =>
      '$baseUrl/notifications/$id/read';
  static String get notificationsReadAll => '$baseUrl/notifications/read-all';
  static String notificationDelete(String id) => '$baseUrl/notifications/$id';
  static String get legacyAccess => '$baseUrl/legacy-access';
  static String get legacyRequestRelease =>
      '$baseUrl/legacy-access/request-release';
  static String get legacyVaultMemories =>
      '$baseUrl/legacy-access/vault-memories';
  static String get legacyFamilyVaults =>
      '$baseUrl/legacy-access/family-vaults';
  static String get legacyPendingRequests =>
      '$baseUrl/legacy-access/pending-requests';
  static String legacyApproveRelease(String requestId) =>
      '$baseUrl/legacy-access/verify-release/$requestId';
  static String legacyRejectRelease(String requestId) =>
      '$baseUrl/legacy-access/reject-release/$requestId';

  // AI Family Historian Endpoints
  static String get aiHistorianChat => '$baseUrl/ai/family-historian/chat';
  static String get aiHistorianStatus => '$baseUrl/ai/family-historian/status';
  static String get insightsSummary => '$baseUrl/insights/summary';

  // Story Layers Endpoints
  static String storyLayers(String memoryId) =>
      '$baseUrl/memories/$memoryId/story-layers';

  // Odyssey Store E-Commerce Endpoints
  static String get storeProducts => '$baseUrl/v1/store/products';
  static String storeProductBySlug(String slug) =>
      '$baseUrl/v1/store/products/$slug';
  static String get storeCart => '$baseUrl/v1/store/cart';
  static String get storeCartItems => '$baseUrl/v1/store/cart/items';
  static String storeCartItemById(String id) =>
      '$baseUrl/v1/store/cart/items/$id';
  static String get storeOrders => '$baseUrl/v1/store/orders';
  static String storeOrderById(String id) => '$baseUrl/v1/store/orders/$id';
  static String get storeApplyCoupon => '$baseUrl/v1/store/coupons/apply';
}
