class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fmt-backend-new.onrender.com',
  );

  // ==========================================
  // Message Central OTP Auth endpoints
  // ==========================================

  /// Send OTP to phone number via Message Central
  static String get sendOtp => '$baseUrl/api/auth/send-otp';

  /// Verify OTP and authenticate (login or register)
  static String get verifyOtp => '$baseUrl/api/auth/verify-otp';

  /// Complete registration for new users after OTP verification
  static String get completeRegistration => '$baseUrl/api/auth/complete-registration';

  /// Check if phone number is already registered
  static String get checkPhone => '$baseUrl/api/auth/check-phone';

  /// Update user profile (name)
  static String get updateProfile => '$baseUrl/api/auth/update-profile';

  /// Update user email (optional)
  static String get updateEmail => '$baseUrl/api/auth/update-email';

  // ==========================================
  // Legacy Auth endpoints (DEPRECATED)
  // ==========================================

  static String get authenticate => '$baseUrl/api/auth/authenticate';
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';

  // ==========================================
  // Profile endpoints
  // ==========================================

  static String get studentProfile => '$baseUrl/api/auth/student-profile';
  static String get teacherProfile => '$baseUrl/api/auth/teacher-profile';
  static String get updateStudentProfile => '$baseUrl/api/auth/student-profile';
  static String get updateTeacherProfile => '$baseUrl/api/auth/teacher-profile';
  static String get me => '$baseUrl/api/auth/me';

  // Search endpoints
  static String get nearbyTeachers => '$baseUrl/api/auth/nearby-teachers';
  static String get nearbyStudents => '$baseUrl/api/auth/nearby-students';
  static String get allTeachers => '$baseUrl/api/auth/all-teachers';
  static String get allStudents => '$baseUrl/api/auth/all-students';
  static String get searchBySubject => '$baseUrl/api/auth/search-by-subject';
  static String teacherProfileById(String id) =>
      '$baseUrl/api/auth/teacher-profile/$id';
  static String studentProfileById(String id) =>
      '$baseUrl/api/auth/student-profile/$id';
  static String get updateLocation => '$baseUrl/api/auth/update-location';

  // Chat endpoints
  static String get chatBase => '$baseUrl/api/chat';
  static String get chatCreate => '$baseUrl/api/chat/create';
  static String chatUser(String userId) => '$baseUrl/api/chat/user/$userId';
  static String chatMessages(String chatId) =>
      '$baseUrl/api/chat/$chatId/messages';
  static String get chatSendMessage => '$baseUrl/api/chat/message';
  static String get chatMarkAsRead => '$baseUrl/api/chat/read';
  static String chatDelete(String chatId) => '$baseUrl/api/chat/$chatId';

  // Socket.IO endpoint
  static String get socketUrl => baseUrl;

  // Subscription endpoints
  static String get subscriptionCreate => '$baseUrl/api/subscription/create';
  static String get subscriptionVerify => '$baseUrl/api/subscription/verify';
  static String subscriptionStatus(String userId) =>
      '$baseUrl/api/subscription/status/$userId';
  static String get subscriptionCancel => '$baseUrl/api/subscription/cancel';

  // Banner endpoints
  static String get bannersNearby => '$baseUrl/api/banners/nearby';
  static String bannerImpression(String id) =>
      '$baseUrl/api/banners/$id/impression';
  static String bannerClick(String id) => '$baseUrl/api/banners/$id/click';
}
