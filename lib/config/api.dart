class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://findmy-tutor-backend.onrender.com',
  );

  static String get register => '$baseUrl/api/auth/register';
  static String get verifyOtp => '$baseUrl/api/auth/verify-otp';
  static String get login => '$baseUrl/api/auth/login';
  static String get studentProfile => '$baseUrl/api/auth/student-profile';
  static String get teacherProfile => '$baseUrl/api/auth/teacher-profile';
  static String get me => '$baseUrl/api/auth/me';
}
