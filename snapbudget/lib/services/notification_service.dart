import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // Initialize timezone
    tz.initializeTimeZones();
    // Default to local generic, since getting exact local timezone requires another package natively
    // for this feature using UTC relative offsets works fine as well.
    tz.setLocalLocation(tz.local);

    _initialized = true;
  }

  /// Shows a notification reminding YOU to pay [friendName] [amount]
  Future<void> remindSelfToPay({
    required String friendName,
    required String amount,
    required String billTitle,
  }) async {
    await init();
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '💸 Payment Reminder',
      'You owe $friendName $amount for "$billTitle". Don\'t forget to pay!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminder',
          'Payment Reminders',
          channelDescription: 'Reminders to pay your share',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Shows a notification as if sent to [friendName] to remind them to pay you
  Future<void> remindFriendToPay({
    required String friendName,
    required String amount,
    required String billTitle,
  }) async {
    await init();
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '🔔 Reminder Sent to $friendName',
      '$friendName has been reminded to pay $amount for "$billTitle".',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'friend_reminder',
          'Friend Reminders',
          channelDescription: 'Reminders sent to friends',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Schedules a notification reminding YOU to pay [friendName] [amount] at a specific [scheduledDate]
  Future<void> scheduleReminderSelf({
    required String friendName,
    required String amount,
    required String billTitle,
    required DateTime scheduledDate,
  }) async {
    await init();

    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    await _notifications.zonedSchedule(
      id,
      '💸 Scheduled Payment Reminder',
      'You owe $friendName $amount for "$billTitle". Time to settle up!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_payment_reminder',
          'Scheduled Payment Reminders',
          channelDescription: 'Scheduled reminders to pay your share',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
