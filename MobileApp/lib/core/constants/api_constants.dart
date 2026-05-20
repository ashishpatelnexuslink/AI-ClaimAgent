class ApiConstants {
  ApiConstants._();

  // Base URLs per environment
  static const String devBaseUrl = 'http://192.168.11.5:5030/api';
  //static const String devBaseUrl = 'http://172.21.228.121:5030/api';
  //static const String devBaseUrl = 'https://claimai-api.nexuslink.in/api';
  static const String stagingBaseUrl = 'https://claimai-api.nexuslink.in/api';
  static const String prodBaseUrl = 'https://claimai-api.nexuslink.in/api';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Auth (mobile endpoints)
  static const String login = '/mobile/auth/login';
  static const String sendOtp = '/mobile/auth/send-otp';
  static const String verifyOtp = '/mobile/auth/verify-otp';
  static const String refreshToken = '/mobile/auth/refresh-token';
  static const String logout = '/mobile/auth/logout';
  static const String userProfile = '/mobile/users/profile';
  static const String updateProfile = '/mobile/users/profile';
  static const String uploadProfilePhoto = '/mobile/users/profile/photo';
  static const String updateBiometricSetting =
      '/mobile/users/profile/biometric';

  // Claims
  static const String claims = '/mobile/claims';
  static const String createClaim = '/mobile/claims';
  static const String createClaimFromChat = '/mobile/claims/from-chat';

  // Claim documents
  static const String uploadClaimDocument = '/mobile/claim-documents';
  static const String attachClaimDocuments = '/mobile/claim-documents/attach';
  static const String claimDocumentsByClaim =
      '/mobile/claim-documents/by-claim/{claimId}';
  static const String deleteClaimDocument = '/mobile/claim-documents/{id}';
  static const String deleteClaimDocumentsByThread =
      '/mobile/claim-documents/by-thread/{threadId}';
  static const String claimById = '/mobile/claims/{id}';
  static const String claimSummary = '/mobile/claims/{id}/summary';
  static const String claimStatus = '/mobile/claims/{id}/status';
  static const String updateClaimAccidentInfo =
      '/mobile/claims/{id}/accident-info';
  static const String claimHistory = '/mobile/claims/{id}/history';

  // Chat / AI
  static const String chatSend = '/mobile/chat/send';
  static const String chatHistory = '/mobile/chat/{claimId}/history';
  static const String chatSuggestions = '/mobile/chat/suggestions';
  static const String saveConversation = '/mobile/conversations';

  // Notifications
  static const String pendingActions = '/mobile/notifications/pending-actions';
  static const String notificationRead = '/mobile/notifications/{id}/read';
  static const String registerDevice = '/mobile/notifications/devices/register';
  static const String unregisterDevice =
      '/mobile/notifications/devices/{token}';

  // Templates
  static const String activeTemplate = '/mobile/templates/active';

  // Documents
  static const String documents = '/documents';
  static const String documentUpload = '/documents/upload';
  static const String documentDelete = '/documents/{id}';
  static const String documentTemplates = '/documents/templates';
  static const String documentFinalize = '/documents/{id}/finalize';
}
