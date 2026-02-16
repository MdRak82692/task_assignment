import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../../location/controllers/location_controller.dart';

class AlarmController extends GetxController {
  final alarms = <AlarmModel>[].obs;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final locationController = Get.find<LocationController>();

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
    _loadAlarms();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification click
      },
    );

    // Request Notification Permissions (Android 13+)
    if (GetPlatform.isAndroid) {
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    alarms.value =
        alarmsJson.map((e) => AlarmModel.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = alarms.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  Future<void> pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        addAlarm(dateTime);
      }
    }
  }

  void addAlarm(DateTime dateTime) {
    final alarm = AlarmModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: dateTime,
    );
    alarms.add(alarm);
    _saveAlarms();
    if (alarm.isEnabled) {
      _scheduleNotification(alarm);
    }
  }

  void toggleAlarm(AlarmModel alarm) {
    alarm.isEnabled = !alarm.isEnabled;
    alarms.refresh();
    _saveAlarms();
    if (alarm.isEnabled) {
      _scheduleNotification(alarm);
    } else {
      _cancelNotification(int.parse(alarm.id.substring(alarm.id.length - 8)));
    }
  }

  Future<void> _scheduleNotification(AlarmModel alarm) async {
    final scheduledDate = tz.TZDateTime.from(alarm.dateTime, tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notificationsPlugin.zonedSchedule(
      int.parse(alarm.id.substring(alarm.id.length - 8)),
      'Alarm',
      'It\'s time for your scheduled alarm!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
