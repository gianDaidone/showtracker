import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_toast.dart';

class ScheduledNotifInfo {
  final int id;
  final String showTitle;
  final String body;
  final DateTime scheduledAt;

  const ScheduledNotifInfo({
    required this.id,
    required this.showTitle,
    required this.body,
    required this.scheduledAt,
  });
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // In-memory registry of scheduled notifications (survives only current session).
  static final Map<int, ScheduledNotifInfo> _registry = {};

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

  /// Pianifica una notifica per l'uscita di un episodio.
  ///
  /// Per serie normali (TMDB): alle 09:00 del giorno di uscita.
  /// Per anime (AniList): all'orario preciso se [useExactTime] è true.
  static Future<void> schedule({
    required int tmdbId,
    required String showTitle,
    required int seasonNumber,
    required int episodeNumber,
    required String episodeName,
    required DateTime airDate,
    bool useExactTime = false,
    String? seasonName,
  }) async {
    try {
      final scheduledAt = useExactTime
          ? airDate
          : DateTime(airDate.year, airDate.month, airDate.day, 9, 0);
      if (!scheduledAt.isAfter(DateTime.now())) return;

      final body = episodeBody(
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        episodeName: episodeName,
        seasonName: seasonName,
      );

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

      _registry[tmdbId] = ScheduledNotifInfo(
        id: tmdbId,
        showTitle: showTitle,
        body: body,
        scheduledAt: scheduledAt,
      );
    } catch (_) {
      AppToast.show('Impossibile pianificare la notifica per $showTitle');
    }
  }

  static final _placeholderEpisodeName =
      RegExp(r'^Episod(?:io|e)\s+\d+$', caseSensitive: false);

  /// Testo della notifica di uscita, es. "Stagione 2, episodio 1: «Lo scoppio
  /// della guerra» è disponibile oggi!". Parole intere anziché "S02E01" o un
  /// misto come "Stagione 2 E01"; il titolo viene omesso quando è solo il
  /// segnaposto TMDB "Episodio 1", che ripeterebbe il numero.
  static String episodeBody({
    required int seasonNumber,
    required int episodeNumber,
    required String episodeName,
    String? seasonName,
  }) {
    final season = seasonName != null && seasonName.trim().isNotEmpty
        ? seasonName.trim()
        : 'Stagione $seasonNumber';
    final name = episodeName.trim();
    final hasTitle = name.isNotEmpty && !_placeholderEpisodeName.hasMatch(name);
    return hasTitle
        ? '$season, episodio $episodeNumber: «$name» è disponibile oggi!'
        : '$season, episodio $episodeNumber è disponibile oggi!';
  }

  static Future<void> cancel(int tmdbId) async {
    _registry.remove(tmdbId);
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
    _registry.clear();
    await _plugin.cancelAll();
  }

  /// Returns pending notifications combining Android's scheduler (persists
  /// across restarts) with the in-session registry (adds scheduled time).
  static Future<List<ScheduledNotifInfo>> getPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((p) => p.id).toSet();

    // Remove stale registry entries that Android already fired/cancelled.
    _registry.removeWhere((id, _) => !pendingIds.contains(id));

    return pending.map((p) {
      final reg = _registry[p.id];
      return ScheduledNotifInfo(
        id: p.id,
        showTitle: reg?.showTitle ?? p.title ?? '—',
        body: reg?.body ?? p.body ?? '—',
        scheduledAt: reg?.scheduledAt ?? DateTime(0),
      );
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }
}
