class Env {
  Env._();

  static const String aiEndpoint = String.fromEnvironment(
    'AI_ENDPOINT',
    defaultValue: '',
  );

  static const String aiApiKey = String.fromEnvironment(
    'AI_API_KEY',
    defaultValue: '',
  );

  // Gemini API Key — replace with your own from https://aistudio.google.com/apikey
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCgS7CaD_8Q3_eMNG7jy9y3u7i4sGjU5Xo',
  );

  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dggu6jp7k',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'nawa_unsigned',
  );

  static const bool debugLogging = bool.fromEnvironment(
    'DEBUG_LOGGING',
    defaultValue: true,
  );

  static const bool adsEnabled = bool.fromEnvironment(
    'ADS_ENABLED',
    defaultValue: true,
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@nawa.app',
  );

  static bool get hasAi => geminiApiKey.isNotEmpty || aiEndpoint.isNotEmpty;
}
