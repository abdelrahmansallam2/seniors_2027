class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://sneiors2027.runasp.net';

  // Auth
  static const String login = '/api/Auth/login';
  static const String verifyOtp = '/api/Auth/verify-otp';
  static const String me = '/api/Auth/me';
  static const String recognize = '/api/Auth/recognize';
  static const String uploadPhoto = '/api/Auth/upload-photo';

  // Users
  static const String users = '/api/Users';

  // Daily Highlights
  static const String dailyHighlightsActive = '/api/DailyHighlights/active';
  static const String dailyHighlightsArchive = '/api/DailyHighlights/archive';
  static const String dailyHighlightsUpload = '/api/DailyHighlights/upload';

  // Memory Board
  static const String memoryBoardPhotos = '/api/memoryboard/photos';
  static const String memoryBoardMyPhotos = '/api/memoryboard/my/photos';

  // Portal Content
  static const String announcements = '/api/portal-content/announcements';
  static const String events = '/api/portal-content/events';

  // Notes
  static const String notes = '/api/Notes';
}
