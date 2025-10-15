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
}
