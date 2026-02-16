import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
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
    // Periodic cleanup of expired alarms every 30 seconds
    Stream.periodic(const Duration(seconds: 30))
        .listen((_) => _cleanUpExpiredAlarms());
  }

  Future<void> _initNotifications() async {
    log('INIT START');
    tz.initializeTimeZones();
    try {
      final dynamic tzData = await FlutterTimezone.getLocalTimezone();
      String id = tzData.toString();
      log('🌎 Raw Timezone from device: "$id"');

      // Handle cases where it returns "Asia/Dhaka (Standard Time)"
      if (id.contains(' (')) {
        id = id.split(' (')[0];
      }

      tz.setLocalLocation(tz.getLocation(id));
      log('✅ Local timezone set to: $id');
    } catch (e) {
      log('❌ Timezone Error: $e');
      // Final fallback for user's likely region
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
        log('⚠️ Fallback to Asia/Dhaka');
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        log('⚠️ Fallback to UTC');
      }
    }
    log('⚙️ Initializing Android and iOS settings...');
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final alarmId = response.payload!;
          final alarm = alarms.firstWhereOrNull((e) => e.id == alarmId);
          if (alarm != null) {
            deleteAlarm(alarm);
            _showFollowUpNotification(alarm);
          }
        }
      },
    );

    // Create notification channel for alarms
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarms',
      description: 'Alarm notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request Notification Permissions (Android 13+)
    if (GetPlatform.isAndroid) {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();

      // Request exact alarm permission for Android 12+ (API 31+)
      final bool? exactAlarmGranted =
          await androidPlugin?.requestExactAlarmsPermission();

      log('📱 Exact alarm permission granted: $exactAlarmGranted');

      if (exactAlarmGranted == false) {
        Get.snackbar(
          'Permission Required',
          'Please enable "Alarms & reminders" permission in Settings for alarms to work',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    alarms.value =
        alarmsJson.map((e) => AlarmModel.fromJson(jsonDecode(e))).toList();
    _cleanUpExpiredAlarms();
  }

  void _cleanUpExpiredAlarms() {
    if (alarms.isEmpty) return;
    final now = DateTime.now();
    // Remove alarms whose time passed more than 1 minute ago
    final expiredAlarms = alarms
        .where((alarm) =>
            alarm.dateTime.isBefore(now.subtract(const Duration(minutes: 1))))
        .toList();

    if (expiredAlarms.isNotEmpty) {
      for (var alarm in expiredAlarms) {
        alarms.remove(alarm);
      }
      _saveAlarms();
      log('🧹 Cleaned up ${expiredAlarms.length} expired alarms');
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = alarms.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  Future<void> pickDateTime(BuildContext context,
      {AlarmModel? existingAlarm}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: existingAlarm?.dateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: existingAlarm != null
            ? TimeOfDay.fromDateTime(existingAlarm.dateTime)
            : TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);

        if (existingAlarm != null) {
          updateAlarm(existingAlarm, dateTime);
        } else {
          addAlarm(dateTime);
        }
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

  void updateAlarm(AlarmModel alarm, DateTime newDateTime) {
    final index = alarms.indexOf(alarm);
    if (index != -1) {
      _cancelNotification(int.parse(alarm.id.substring(alarm.id.length - 8)));
      final updatedAlarm = AlarmModel(
        id: alarm.id,
        dateTime: newDateTime,
        isEnabled: alarm.isEnabled,
      );
      alarms[index] = updatedAlarm;
      _saveAlarms();
      if (updatedAlarm.isEnabled) {
        _scheduleNotification(updatedAlarm);
      }
    }
  }

  void deleteAlarm(AlarmModel alarm) {
    _cancelNotification(int.parse(alarm.id.substring(alarm.id.length - 8)));
    alarms.remove(alarm);
    _saveAlarms();
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
    final now = tz.TZDateTime.now(tz.local);

    log('SCHED_DT: ${alarm.dateTime}');
    log('SCHED_TZ: $scheduledDate');
    log('NOW_TZ: $now');

    // If the alarm time has already passed, show notification immediately
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      log('IMMED_ALARM');
      await _showImmediateAlarm(alarm);
      return;
    }

    log('PUT_SCHED');
    try {
      await _notificationsPlugin.zonedSchedule(
        int.parse(alarm.id.substring(alarm.id.length - 8)),
        'Alarm',
        'It\'s time for your scheduled alarm!',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarms',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Alarm',
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            timeoutAfter: 60000,
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'stop',
                'Stop Alarm',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: alarm.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      log('SCHED_DONE');

      // Verify the notification was actually scheduled
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      log('PENDING: ${pending.length}');
    } catch (e) {
      log('SCHED_ERR: $e');
      Get.snackbar(
        'Alarm Error',
        'Failed to schedule alarm: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _showImmediateAlarm(AlarmModel alarm) async {
    await _notificationsPlugin.show(
      int.parse(alarm.id.substring(alarm.id.length - 8)),
      'Alarm',
      'It\'s time for your scheduled alarm!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Alarm',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          timeoutAfter: 60000,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'stop',
              'Stop Alarm',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: alarm.id,
    );
  }

  Future<void> _showFollowUpNotification(AlarmModel alarm) async {
    const androidDetails = AndroidNotificationDetails(
      'followup_channel',
      'Alarm Feedback',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999,
      'Alarm Stopped',
      'Your alarm for ${DateFormat('h:mm a').format(alarm.dateTime)} was turned off.',
      notificationDetails,
    );
  }

  Future<void> _cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
