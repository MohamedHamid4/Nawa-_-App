import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_logger.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _local.initialize(settings);

    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n != null) {
          showNow(title: n.title ?? '', body: n.body ?? '');
        }
      });
    } catch (e) {
      AppLogger.w('FCM init skipped: $e');
    }

    _initialized = true;
  }

  Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      AppLogger.w('getFcmToken failed: $e');
      return null;
    }
  }

  NotificationDetails _details({bool reminder = false}) => NotificationDetails(
        android: AndroidNotificationDetails(
          reminder ? 'reminders' : 'nawa_default',
          reminder ? 'Reminders' : 'Nawa',
          channelDescription:
              reminder ? 'Note reminders' : 'Nawa notifications',
          importance: reminder ? Importance.max : Importance.high,
          priority: reminder ? Priority.max : Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  Future<void> showNow({required String title, required String body}) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _details(),
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    Duration leadTime = Duration.zero,
  }) async {
    final actualWhen = when.subtract(leadTime);
    final tzWhen = tz.TZDateTime.from(actualWhen, tz.local);
    await _local.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      _details(reminder: true),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancel(int id) => _local.cancel(id);
  Future<void> cancelAll() => _local.cancelAll();
}
