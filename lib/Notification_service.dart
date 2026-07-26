import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  static Future<void> init() async {
    // 1. Setup Timezones
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2. Request Android 13+ and Exact Alarm Permissions
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    }

    // 3. Initialize Icon
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('ic_notification');
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: DarwinInitializationSettings());

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        selectNotificationStream.add(response.payload);
      },
    );
  }

  static Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
  }

  // --- Helper: Calculates next 4:00 PM ---
  static tz.TZDateTime _nextInstanceOf4PM({bool skipToday = false}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 0); // 16 = 4:00 PM

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (skipToday && scheduledDate.day == now.day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // --- Helper: Calculates next 5:00 PM ---
  static tz.TZDateTime _nextInstanceOf5PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 17, 0); // 17 = 5:00 PM

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- 1. Daily Watering Reminder (4:00 PM) ---
  static Future<void> scheduleDailyReminder({bool skipToday = false}) async {
    // If user already watered today, don't nag them at 4 PM
    if (skipToday && _nextInstanceOf4PM(skipToday: skipToday).day == tz.TZDateTime.now(tz.local).day) {
      return;
    }

    await _notificationsPlugin.cancel(100);

    await _notificationsPlugin.zonedSchedule(
      100,
      "🌱 Garden Check-in!",
      "It's 4:00 PM! Time to check your plants' condition and water them. 💧",
      _nextInstanceOf4PM(skipToday: skipToday),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_watering_channel',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
          color: Color(0xFF2EF889),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at this time
      payload: 'watering_reminder',
    );
  }

  // --- 2. Two Hour Snooze Reminder ---
  static Future<void> scheduleTwoHourReminder() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime = now.add(const Duration(hours: 2));

    // Cancel snooze if it pushes past 9:00 PM (21:00) so we don't wake the user up
    if (scheduledTime.hour >= 21) return;

    await _notificationsPlugin.zonedSchedule(
      101,
      "⏰ Quick Reminder!",
      "Did you get a chance to water your plants yet?",
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'snooze_channel',
          'Snooze Reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
          color: Color(0xFF2EF889),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'watering_reminder',
    );
  }

  // --- 3. Daily Scan Reminder (5:00 PM) ---
  static Future<void> scheduleDailyScanReminder() async {
    await _notificationsPlugin.zonedSchedule(
      3,
      'Time to check your plant! 🔍',
      'Scan your plant now to track its growth and earn your daily 15 XP!',
      _nextInstanceOf5PM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_scan_channel',
          'Daily Scan Reminder',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
          color: Color(0xFF2EF889),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at this time
    );
  }

  static Future<void> cancelSnooze() async {
    await _notificationsPlugin.cancel(101);
  }
}