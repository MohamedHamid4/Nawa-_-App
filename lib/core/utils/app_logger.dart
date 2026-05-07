import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void d(Object? message) => _logger.d(message);
  static void i(Object? message) => _logger.i(message);
  static void w(Object? message) => _logger.w(message);
  static void e(Object? message, [Object? error, StackTrace? stack]) =>
      _logger.e(message, error: error, stackTrace: stack);
}
