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
import 'package:permission_handler/permission_handler.dart';
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
    _setup();
  }

  Future<void> _setup() async {
    log('🚀 AlarmController Setup Start');
    await _loadAlarms();
    await _initNotifications();

    // Periodic cleanup of expired alarms every 30 seconds
    Stream.periodic(const Duration(seconds: 30))
        .listen((_) => _cleanUpExpiredAlarms());

    // Check if the app was launched from a notification
    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      log('📱 App launched from notification');
      final response = launchDetails!.notificationResponse;
      if (response != null && response.payload != null) {
        _handleNotificationResponse(response);
      }
    }

    _rescheduleAlarms();
    log('✅ AlarmController Setup Complete');
  }

  void _rescheduleAlarms() {
    log('🔄 Rescheduling ${alarms.length} alarms...');
    int count = 0;
    for (var alarm in alarms) {
      if (alarm.isEnabled) {
        _scheduleNotification(alarm);
        count++;
      }
    }
    log('✅ Processed $count enabled alarms');
  }

  Future<void> _initNotifications() async {
    log('🔔 Initializing Notifications...');
    tz.initializeTimeZones();
    try {
      final dynamic tzData = await FlutterTimezone.getLocalTimezone();
      String tzName = tzData.toString();

      // Handle cases where it returns "Asia/Dhaka (Standard Time)"
      if (tzName.contains(' (')) {
        tzName = tzName.split(' (')[0];
      }

      tz.setLocalLocation(tz.getLocation(tzName));
      log('🌎 Timezone: $tzName');
    } catch (e) {
      log('⚠️ Timezone fallback: Asia/Dhaka ($e)');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Create notification channels
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // 1. Main Alarm Channel
    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel_v3', // Changed ID to force update
      'Alarms',
      description: 'Scheduled alarm notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(alarmChannel);

    // 2. Follow-up Channel
    const followUpChannel = AndroidNotificationChannel(
      'followup_channel_v2',
      'Alarm Feedback',
      description: 'Notifications after stopping an alarm',
      importance: Importance.high,
      playSound: true,
    );
    await androidPlugin?.createNotificationChannel(followUpChannel);

    // Request permissions (Android 13+)
    if (GetPlatform.isAndroid) {
      await androidPlugin?.requestNotificationsPermission();
      final bool? exactGranted =
          await androidPlugin?.requestExactAlarmsPermission();
      log('🔒 Exact alarm permission: $exactGranted');

      // Request ignore battery optimizations
      if (!await Permission.ignoreBatteryOptimizations.isGranted) {
        log('🔋 Requesting battery optimization ignore...');
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    log('🔘 Notification Clicked: actionId=${response.actionId}, payload=${response.payload}');
    if (response.payload != null) {
      final alarmId = response.payload!;
      final alarm = alarms.firstWhereOrNull((e) => e.id == alarmId);
      if (alarm != null) {
        deleteAlarm(alarm);
        _showFollowUpNotification(alarm);
      } else {
        log('⚠️ Alarm not found for ID: $alarmId');
      }
    }
  }

  Future<void> _loadAlarms() async {
    log('💾 Loading alarms from storage...');
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    alarms.value =
        alarmsJson.map((e) => AlarmModel.fromJson(jsonDecode(e))).toList();
    log('📊 Loaded ${alarms.length} alarms');
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
      log('🧹 Cleaning up ${expiredAlarms.length} expired alarms');
      for (var alarm in expiredAlarms) {
        alarms.remove(alarm);
      }
      _saveAlarms();
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

  void deleteAlarm(AlarmModel alarm, {bool showFollowUp = false}) {
    _cancelNotification(int.parse(alarm.id.substring(alarm.id.length - 8)));
    alarms.remove(alarm);
    _saveAlarms();
    if (showFollowUp) {
      _showFollowUpNotification(alarm);
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
      _showFollowUpNotification(alarm);
    }
  }

  Future<void> _scheduleNotification(AlarmModel alarm) async {
    final scheduledDate = tz.TZDateTime.from(alarm.dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    log('📅 Scheduling Alarm: ${alarm.dateTime}');
    // Trigger immediately if time is now or slightly in the past (within cleanup window)
    if (!scheduledDate.isAfter(now)) {
      log('⌛ Alarm time reached or passed, showing immediate notification');
      await _showImmediateAlarm(alarm);
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        int.parse(alarm.id.substring(alarm.id.length - 8)),
        'Stop Alarm',
        'It\'s time for your scheduled alarm!',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel_v3',
            'Alarms',
            importance: Importance.max,
            priority: Priority.max,
            ticker: 'Stop Alarm',
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
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
      log('✅ Alarm scheduled for $scheduledDate');
    } catch (e) {
      log('❌ Schedule Error: $e');
    }
  }

  Future<void> _showImmediateAlarm(AlarmModel alarm) async {
    await _notificationsPlugin.show(
      int.parse(alarm.id.substring(alarm.id.length - 8)),
      'Stop Alarm',
      'It\'s time for your scheduled alarm!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel_v3',
          'Alarms',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'Stop Alarm',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
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
      'followup_channel_v2',
      'Alarm Feedback',
      importance: Importance.high,
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
