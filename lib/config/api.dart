class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://findmy-tutor-backend.onrender.com',
  );

  // Auth endpoints
  static String get register => '$baseUrl/api/auth/register';
  static String get verifyOtp => '$baseUrl/api/auth/verify-otp';
  static String get login => '$baseUrl/api/auth/login';
  static String get studentProfile => '$baseUrl/api/auth/student-profile';
  static String get teacherProfile => '$baseUrl/api/auth/teacher-profile';
  static String get me => '$baseUrl/api/auth/me';
  
  // Search endpoints
  static String get nearbyTeachers => '$baseUrl/api/auth/nearby-teachers';
  static String get nearbyStudents => '$baseUrl/api/auth/nearby-students';
  static String get searchBySubject => '$baseUrl/api/auth/search-by-subject';
  static String get allTeachers => '$baseUrl/api/auth/all-teachers';
  static String get allStudents => '$baseUrl/api/auth/all-students';
  static String teacherProfileById(String id) => '$baseUrl/api/auth/teacher-profile/$id';
  static String studentProfileById(String id) => '$baseUrl/api/auth/student-profile/$id';
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
  static String subscriptionStatus(String userId) => '$baseUrl/api/subscription/status/$userId';
  static String get subscriptionCancel => '$baseUrl/api/subscription/cancel';
}
