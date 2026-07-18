// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

/// Schedules a local reminder at a task's set time. The reminder only fires if
/// the task is still not done — it is cancelled the moment the task is checked
/// off or deleted, and re-armed on app start so it survives reboots/reinstalls.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'task_reminders';
  static const _channelName = 'Rappels de tâches';
  static const _channelDesc =
      "Alerte à l'heure prévue si la tâche n'est pas encore faite";

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    // Wrapped so a notification failure can NEVER block app startup — the app
    // simply runs without reminders if anything here goes wrong.
    try {
      tzdata.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
      } catch (_) {
        // Falls back to UTC — reminders still fire, just off the device zone.
      }

      const androidInit = AndroidInitializationSettings('ic_stat_notify');
      await _plugin.initialize(const InitializationSettings(android: androidInit));

      await _android?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId, _channelName,
        description: _channelDesc,
        importance: Importance.max,
      ));
      _ready = true;
    } catch (_) {
      // Leave _ready = false; scheduling calls become no-ops.
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Ask for the notification + exact-alarm permissions (Android 13+ / 12+).
  Future<void> requestPermissions() async {
    await _android?.requestNotificationsPermission();
    await _android?.requestExactAlarmsPermission();
  }

  int _idFor(String uuid) => uuid.hashCode & 0x7fffffff;

  /// Extracts (hour, minute) from a time string like "08:30", "8h30", "8:5".
  static (int, int)? parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final m = RegExp(r'(\d{1,2})\s*[:hH]?\s*(\d{0,2})').firstMatch(raw.trim());
    if (m == null) return null;
    final h = int.tryParse(m.group(1) ?? '') ?? -1;
    final minStr = m.group(2) ?? '';
    final min = minStr.isEmpty ? 0 : (int.tryParse(minStr) ?? -1);
    if (h < 0 || h > 23 || min < 0 || min > 59) return null;
    return (h, min);
  }

  /// (Re)schedule the reminder for [task]. Cancels first, then arms it only if
  /// the task is not done, has a valid time, and that time is still in the future.
  Future<void> scheduleTask(DailyTask task) async {
    if (!_ready) await init();
    if (!_ready) return;
    await cancelTask(task.id);
    if (task.isDone) return;

    final parsed = parseTime(task.time);
    if (parsed == null) return;
    final (h, min) = parsed;

    final when = DateTime(task.date.year, task.date.month, task.date.day, h, min);
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return; // time already passed

    final hhmm = '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId, _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_notify',
      ),
    );

    Future<void> arm(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          _idFor(task.id),
          '⏰ $hhmm — Rappel',
          task.title,
          scheduled,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

    try {
      await arm(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      // Exact alarms not permitted → best-effort (may fire a few minutes late).
      await arm(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelTask(String uuid) async {
    if (!_ready) return;
    await _plugin.cancel(_idFor(uuid));
  }

  /// Re-arm every task's reminder — call on app start after loading data.
  Future<void> syncAll(List<DailyTask> tasks) async {
    if (!_ready) await init();
    for (final t in tasks) {
      await scheduleTask(t);
    }
  }
}
