import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data'; // Для Int64List
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:html/parser.dart' show parse;

class NotificationHelper {
  static int _idCounter = Random().nextInt(100000);

  static int generateId() {
    _idCounter = (_idCounter + 1) % 2147483647;
    if (_idCounter == 0) _idCounter = 1;
    return _idCounter;
  }
}

class LocalNotificationsService {
  static final LocalNotificationsService _instance =
      LocalNotificationsService._internal();

  factory LocalNotificationsService() => _instance;

  LocalNotificationsService._internal();

  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // Константы каналов
  static const String _androidChannelId = 'high_importance_channel';
  static const String _androidChannelName = 'Важные уведомления';
  static const String _androidChannelDesc = 'Уведомления с высоким приоритетом';

  /// Инициализация сервиса
  Future<void> init({
    void Function(NotificationResponse)? onSelectedNotification,
  }) async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Обработчик клика
    if (onSelectedNotification != null) {
      unawaited(
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      requestProvisionalPermission: false,
    );

    const macOSSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onSelectedNotification,
      onDidReceiveBackgroundNotificationResponse: onSelectedNotification,
    );

    if (Platform.isAndroid) {
      await _createAndroidChannel();
    }
  }

  Future<void> _createAndroidChannel() async {
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl == null) return;

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      // vibrationPattern можно задать здесь, но лучше в details для гибкости
    );

    await androidImpl.createNotificationChannel(channel);
  }

  /// Удаление HTML-тегов из текста
  String stripHtml(String html) {
    final document = parse(html);
    return document.body?.text.trim() ?? '';
  }

  /// Показ уведомления (главный публичный метод)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String? icon,

    // Группировка (Android)
    bool groupNotifications = false,
    String? groupKey,
    String? groupSummary,

    // Звук и вибрация
    bool enableSound = true,
    bool enableVibration = true,
    String? soundName,
    Int64List? vibrationPattern,
  }) async {
    final notificationId = NotificationHelper.generateId();
    final cleanBody = stripHtml(body);

    // unawaited(Get.snackbar(title, cleanBody).show());

    // Тестил фоновый процесс. Кажется, тщетно, но на будущее будет полезно
    // Future.delayed(
    //   Duration(seconds: 10),
    // ).then((_) => BackgroundService.instance.triggerBackgroundFetch());

    if (Platform.isAndroid) {
      return _showAndroid(
        id: notificationId,
        title: title,
        body: cleanBody,
        payload: payload,
        icon: icon,
        groupKey: groupNotifications ? groupKey : null,
        groupSummary: groupSummary,
        enableSound: enableSound,
        enableVibration: enableVibration,
        soundName: soundName,
        vibrationPattern: vibrationPattern,
      );
    } else if (Platform.isIOS) {
      return _showIOS(
        id: notificationId,
        title: title,
        body: cleanBody,
        payload: payload,
        enableSound: enableSound,
        soundName: soundName,
      );
    } else if (Platform.isMacOS) {
      return _showMacOS(
        id: notificationId,
        title: title,
        body: cleanBody,
        payload: payload,
        enableSound: enableSound,
        soundName: soundName,
      );
    }
  }

  /// Android: показ уведомления
  Future<void> _showAndroid({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? icon,
    String? groupKey,
    String? groupSummary,
    required bool enableSound,
    required bool enableVibration,
    String? soundName,
    Int64List? vibrationPattern,
  }) async {
    // Паттерн вибрации по умолчанию: ждать 0мс, вибрировать 250мс, пауза 250мс, вибрировать 250мс
    final effectiveVibration =
        vibrationPattern ?? Int64List.fromList([0, 250, 250, 250]);

    final androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDesc,
      importance: Importance.high,
      priority: Priority.high,

      // Иконка
      icon: icon ?? 'ic_notification',

      // Звук
      playSound: enableSound,

      // Вибрация
      enableVibration: enableVibration,
      vibrationPattern: enableVibration ? effectiveVibration : null,

      // Группировка
      groupKey: groupKey,
      setAsGroupSummary: groupKey != null && groupSummary != null,
      groupAlertBehavior: GroupAlertBehavior.all,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// iOS: показ уведомления
  Future<void> _showIOS({
    required int id,
    required String title,
    required String body,
    String? payload,
    required bool enableSound,
    String? soundName,
  }) async {
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: enableSound,
      presentBanner: true,
      sound: enableSound
          ? (soundName != null ? '$soundName.aiff' : 'default')
          : null,
      // Вибрация на iOS привязана к звуку и не настраивается отдельно
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(iOS: iosDetails),
      payload: payload,
    );
  }

  /// macOS: показ уведомления
  Future<void> _showMacOS({
    required int id,
    required String title,
    required String body,
    String? payload,
    required bool enableSound,
    String? soundName,
  }) async {
    final macosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: enableSound,
      sound: enableSound
          ? (soundName != null ? '$soundName.aiff' : 'default')
          : null,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(macOS: macosDetails),
      payload: payload,
    );
  }

  /// Запрос разрешений (полезно для iOS/macOS)
  Future<bool> requestPermissions({
    bool sound = true,
    bool alert = true,
    bool badge = true,
  }) async {
    if (Platform.isIOS || Platform.isMacOS) {
      final plugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      return await plugin?.requestPermissions(
            sound: sound,
            alert: alert,
            badge: badge,
          ) ??
          false;
    }

    if (Platform.isAndroid) {
      final plugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      return await plugin?.requestNotificationsPermission() ?? false;
    }

    return false;
  }

  /// Проверка, включены ли уведомления (iOS/macOS)
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final plugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      final settings = await plugin?.checkPermissions();
      return settings?.isSoundEnabled == true ||
          settings?.isAlertEnabled == true;
    }
    return true; // На Android считаем включёнными, если есть разрешение
  }

  /// Отмена всех уведомлений
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Отмена конкретного уведомления
  Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
