import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_toast.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'episode_releases';
  static const _channelName = 'Uscite episodi';

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Pianifica una notifica alle 13:00 del giorno di uscita dell'episodio.
  /// Se l'orario è già passato la notifica viene ignorata.
  static Future<void> schedule({
    required int tmdbId,
    required String showTitle,
    required int seasonNumber,
    required int episodeNumber,
    required String episodeName,
    required DateTime airDate,
  }) async {
    try {
      final scheduledAt = DateTime(
        airDate.year, airDate.month, airDate.day, 9, 0,
      );
      if (!scheduledAt.isAfter(DateTime.now())) return;

      final sNum = seasonNumber.toString().padLeft(2, '0');
      final eNum = episodeNumber.toString().padLeft(2, '0');
      final body = 'S${sNum}E$eNum – $episodeName è disponibile oggi!';

      await _plugin.zonedSchedule(
        id: tmdbId,
        title: showTitle,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: '@drawable/ic_notification',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    } catch (_) {
      AppToast.show('Impossibile pianificare la notifica per $showTitle');
    }
  }

  static Future<void> cancel(int tmdbId) async {
    try {
      await _plugin.cancel(id: tmdbId);
    } catch (_) {
      AppToast.show('Impossibile cancellare la notifica pianificata');
    }
  }

  static Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: '@drawable/ic_notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleInSeconds({
    required int seconds,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id: 99999,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: '@drawable/ic_notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
