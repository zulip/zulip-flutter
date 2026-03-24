// Модуль локальных уведомлений для Flutter приложения
// Поддерживает Android, iOS и macOS

import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static int _idCounter = Random().nextInt(100000);

  static int generateId() {
    _idCounter = (_idCounter + 1) % 2147483647;
    return _idCounter;
  }
}

class LocalNotificationsService {
  static final LocalNotificationsService _instance =
      LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;
  LocalNotificationsService._internal();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // Инициализация сервиса уведомлений
  Future<void> init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Конфигурация для разных платформ
    if (Platform.isAndroid) {
      await _initAndroid();
    } else if (Platform.isIOS) {
      await _initIOS();
    } else if (Platform.isMacOS) {
      await _initMacOS();
    }
  }

  // Инициализация для Android
  Future<void> _initAndroid() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // Инициализация для iOS
  Future<void> _initIOS() async {
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
          // Добавляем поддержку background processing
          requestProvisionalPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // Инициализация для macOS
  Future<void> _initMacOS() async {
    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(macOS: initializationSettingsMacOS);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // Отображение уведомления
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String? icon,
    bool groupNotifications = false,
    String? groupKey,
    String? groupSummary,
    bool enableSound = true,
    bool enableVibration = true,
    String? soundName,
  }) async {
    // Создание идентификатора уведомления
    final int notificationId = NotificationHelper.generateId();

    // Платформо-специфичные настройки
    if (Platform.isAndroid) {
      await _showAndroidNotification(
        notificationId,
        title,
        body,
        payload,
        icon,
        groupNotifications,
        groupKey,
        groupSummary,
        enableSound,
        enableVibration,
        soundName,
      );
    } else if (Platform.isIOS) {
      await _showIOSNotification(
        notificationId,
        title,
        body,
        payload,
        icon,
        groupNotifications,
        groupKey,
        groupSummary,
        enableSound,
        enableVibration,
        soundName,
      );
    } else if (Platform.isMacOS) {
      await _showMacOSNotification(
        notificationId,
        title,
        body,
        payload,
        icon,
        groupNotifications,
        groupKey,
        groupSummary,
        enableSound,
        enableVibration,
        soundName,
      );
    }
  }

  // Отображение уведомления для Android
  Future<void> _showAndroidNotification(
    int id,
    String title,
    String body,
    String? payload,
    String? icon,
    bool groupNotifications,
    String? groupKey,
    String? groupSummary,
    bool enableSound,
    bool enableVibration,
    String? soundName,
  ) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,

          // Иконка уведомления
          icon: 'ic_notification',
        );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidNotificationDetails,
      ),
      payload: payload,
    );
  }

  // Отображение уведомления для iOS
  Future<void> _showIOSNotification(
    int id,
    String title,
    String body,
    String? payload,
    String? icon,
    bool groupNotifications,
    String? groupKey,
    String? groupSummary,
    bool enableSound,
    bool enableVibration,
    String? soundName,
  ) async {
    const NotificationDetails iosNotificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        // Добавляем поддержку категорий уведомлений для iOS
        categoryIdentifier: 'ZULIP_NOTIFICATION_CATEGORY',
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: iosNotificationDetails,
      payload: payload,
    );
  }

  // Отображение уведомления для macOS
  Future<void> _showMacOSNotification(
    int id,
    String title,
    String body,
    String? payload,
    String? icon,
    bool groupNotifications,
    String? groupKey,
    String? groupSummary,
    bool enableSound,
    bool enableVibration,
    String? soundName,
  ) async {
    const DarwinNotificationDetails macosNotificationDetails =
        DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(macOS: macosNotificationDetails),
      payload: payload,
    );
  }

  // Настройка группировки уведомлений
  Future<void> groupNotifications({
    required String groupKey,
    required String groupSummary,
    List<String> notifications = const [],
  }) async {
    // Логика группировки уведомлений
    if (Platform.isAndroid) {
      await _groupAndroidNotifications(groupKey, groupSummary, notifications);
    }
  }

  // Группировка уведомлений для Android
  Future<void> _groupAndroidNotifications(
    String groupKey,
    String groupSummary,
    List<String> notifications,
  ) async {
    // Для Android можно использовать группировку через channel
    const AndroidNotificationChannel groupChannel = AndroidNotificationChannel(
      'group_channel',
      'Group Notifications',
      description: 'Notifications grouped by sender',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(groupChannel);
  }

  // Настройка звука и вибрации
  Future<void> configureSoundAndVibration({
    required bool enableSound,
    required bool enableVibration,
    String? soundName,
    List<int>? vibrationPattern,
  }) async {
    // Настройка звука и вибрации для разных платформ
    if (Platform.isAndroid) {
      await _configureAndroidSoundAndVibration(
        enableSound,
        enableVibration,
        soundName,
        vibrationPattern,
      );
    } else if (Platform.isIOS) {
      await _configureIOSSoundAndVibration(
        enableSound,
        enableVibration,
        soundName,
      );
    } else if (Platform.isMacOS) {
      await _configureMacOSSoundAndVibration(
        enableSound,
        enableVibration,
        soundName,
      );
    }
  }

  // Настройка звука и вибрации для Android
  Future<void> _configureAndroidSoundAndVibration(
    bool enableSound,
    bool enableVibration,
    String? soundName,
    List<int>? vibrationPattern,
  ) async {
    // Реализация настройки звука и вибрации для Android
  }

  // Настройка звука и вибрации для iOS
  Future<void> _configureIOSSoundAndVibration(
    bool enableSound,
    bool enableVibration,
    String? soundName,
  ) async {
    // Реализация настройки звука и вибрации для iOS
  }

  // Настройка звука и вибрации для macOS
  Future<void> _configureMacOSSoundAndVibration(
    bool enableSound,
    bool enableVibration,
    String? soundName,
  ) async {
    // Реализация настройки звука и вибрации для macOS
  }

  // Обработка нажатия на уведомление
  Future<void> onNotificationClick(
    PendingNotificationRequest notification,
  ) async {
    // Логика обработки нажатия на уведомление
    // Открытие приложения или переход к нужному экрану
  }

  // Проверка статуса уведомлений для iOS и macOS
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS || Platform.isMacOS) {
      // For iOS and macOS, we can check the authorization status
      if (Platform.isIOS) {
        return await _checkIOSNotificationStatus();
      } else if (Platform.isMacOS) {
        return await _checkMacOSNotificationStatus();
      }
    }
    return false;
  }

  // Проверка статуса уведомлений для iOS
  Future<bool> _checkIOSNotificationStatus() async {
    // This would require platform-specific implementation
    // For now, we'll return a default value
    return true;
  }

  // Проверка статуса уведомлений для macOS
  Future<bool> _checkMacOSNotificationStatus() async {
    // This would require platform-specific implementation
    return true;
  }
}
