import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);
    _isInitialized = true;
  }

  // Schedule a medication reminder
  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicineName,
    required DateTime scheduledTime,
    required String timeSlot,
  }) async {
    await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders for medication doses',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      enableLights: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        sound: 'notification_sound.aiff',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _notifications.zonedSchedule(
      id,
      'Medication Reminder',
      'Time to take $medicineName ($timeSlot)',
      scheduledTZTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Send buzzer command to ESP32
    await sendBuzzerCommand();
  }

  // Send buzzer command to ESP32
  static Future<void> sendBuzzerCommand() async {
    try {
      // Replace with your ESP32 IP address and endpoint
      const String esp32Url = 'http://192.168.1.100/buzzer';
      
      final response = await http.post(
        Uri.parse(esp32Url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'command': 'buzzer_on', 'duration': 5000}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('Buzzer command sent successfully');
      } else {
        print('Failed to send buzzer command: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending buzzer command: $e');
    }
  }

  // Log missed dose
  static Future<void> logMissedDose({
    required String medicineName,
    required DateTime scheduledTime,
    required String timeSlot,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> missedDoses = prefs.getStringList('missedDoses') ?? [];
    
    final missedDose = {
      'medicineName': medicineName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'timeSlot': timeSlot,
      'loggedAt': DateTime.now().toIso8601String(),
    };

    missedDoses.add(json.encode(missedDose));
    await prefs.setStringList('missedDoses', missedDoses);
  }

  // Get missed doses
  static Future<List<Map<String, dynamic>>> getMissedDoses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> missedDoses = prefs.getStringList('missedDoses') ?? [];
    
    return missedDoses.map((dose) => json.decode(dose) as Map<String, dynamic>).toList();
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
} 