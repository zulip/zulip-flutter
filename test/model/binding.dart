import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:test/fake.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/store.dart';

import 'test_store.dart';

/// The binding instance used in tests.
///
/// This is the Zulip-specific analogue of [WidgetTester.binding].
TestZulipBinding get testBinding => TestZulipBinding.instance;

/// A concrete binding for use in the `flutter test` environment.
///
/// Tests that will mount a [GlobalStoreWidget], or invoke a Flutter plugin,
/// should initialize this binding
/// by calling [ensureInitialized] at the start of the `main` method.
///
/// Individual test functions that mount a [GlobalStoreWidget] may then use
/// [globalStore] to access the global store provided to the [GlobalStoreWidget],
/// and [TestGlobalStore.add] to set up test data there.  Such test functions
/// must also call [reset] to clean up the global store.
///
/// The global store returned by [loadGlobalStore], and consequently by
/// [GlobalStoreWidget.of] in application code, will be a [TestGlobalStore].
class TestZulipBinding extends ZulipBinding {
  /// Initialize the binding if necessary, and ensure it is a [TestZulipBinding].
  ///
  /// This method is idempotent; calling it repeatedly simply returns the
  /// existing binding.
  ///
  /// If there is an existing binding but it is not a [TestZulipBinding],
  /// this method throws an error.
  static TestZulipBinding ensureInitialized() {
    if (_instance == null) {
      TestZulipBinding();
    }
    return instance;
  }

  /// The single instance of the binding.
  static TestZulipBinding get instance => ZulipBinding.checkInstance(_instance);
  static TestZulipBinding? _instance;

  @override
  void initInstance() {
    super.initInstance();
    _instance = this;
  }

  /// Reset all test data to a clean state.
  ///
  /// Tests that mount a [GlobalStoreWidget], or invoke a Flutter plugin,
  /// or access [globalStore] or other methods on this class,
  /// should clean up by calling this method.  Typically this is done using
  /// [addTearDown], like `addTearDown(testBinding.reset);`.
  void reset() {
    _resetStore();
    _resetLaunchUrl();
    _resetDeviceInfo();
    _resetFirebase();
    _resetNotifications();
  }

  /// The current global store offered to a [GlobalStoreWidget].
  ///
  /// The store is created lazily when accessing this getter, or when mounting
  /// a [GlobalStoreWidget].  The same store will continue to be provided until
  /// a call to [reset].
  ///
  /// Tests that access this getter, or that mount a [GlobalStoreWidget],
  /// should clean up by calling [reset].
  TestGlobalStore get globalStore => _globalStore ??= TestGlobalStore(accounts: []);
  TestGlobalStore? _globalStore;

  bool _debugAlreadyLoadedStore = false;

  void _resetStore() {
    _globalStore?.dispose();
    _globalStore = null;
    assert(() {
      _debugAlreadyLoadedStore = false;
      return true;
    }());
  }

  @override
  Future<GlobalStore> loadGlobalStore() {
    assert(() {
      if (_debugAlreadyLoadedStore) {
        throw FlutterError.fromParts([
          ErrorSummary('The same test global store was loaded twice.'),
          ErrorDescription(
            'The global store is loaded when a [GlobalStoreWidget] is mounted.  '
            'In the app, only one [GlobalStoreWidget] element is ever mounted, '
            'and the global store is loaded only once.  In tests, after mounting '
            'a [GlobalStoreWidget] and before doing so again, the method '
            '[TestGlobalStore.reset] must be called in order to provide a fresh store.',
          ),
          ErrorHint(
            'Typically this is accomplished using [addTearDown], like '
            '`addTearDown(testBinding.reset);`.',
          ),
        ]);
      }
      _debugAlreadyLoadedStore = true;
      return true;
    }());
    return Future.value(globalStore);
  }

  /// The value that `ZulipBinding.instance.launchUrl()` should return.
  ///
  /// See also [takeLaunchUrlCalls].
  bool launchUrlResult = true;

  void _resetLaunchUrl() {
    launchUrlResult = true;
    _launchUrlCalls = null;
  }

  /// Consume the log of calls made to `ZulipBinding.instance.launchUrl()`.
  ///
  /// This returns a list of the arguments to all calls made
  /// to `ZulipBinding.instance.launchUrl()` since the last call to
  /// either this method or [reset].
  ///
  /// See also [launchUrlResult].
  List<({Uri url, url_launcher.LaunchMode mode})> takeLaunchUrlCalls() {
    final result = _launchUrlCalls;
    _launchUrlCalls = null;
    return result ?? [];
  }
  List<({Uri url, url_launcher.LaunchMode mode})>? _launchUrlCalls;

  @override
  Future<bool> launchUrl(
    Uri url, {
    url_launcher.LaunchMode mode = url_launcher.LaunchMode.platformDefault,
  }) async {
    (_launchUrlCalls ??= []).add((url: url, mode: mode));
    return launchUrlResult;
  }

  /// The value that `ZulipBinding.instance.deviceInfo()` should return.
  ///
  /// See also [takeDeviceInfoCalls].
  BaseDeviceInfo deviceInfoResult = _defaultDeviceInfoResult;
  static final _defaultDeviceInfoResult = AndroidDeviceInfo(sdkInt: 33);

  void _resetDeviceInfo() {
    deviceInfoResult = _defaultDeviceInfoResult;
  }

  @override
  Future<BaseDeviceInfo> deviceInfo() {
    return Future(() => deviceInfoResult);
  }

  void _resetFirebase() {
    _firebaseInitialized = false;
    _firebaseMessaging = null;
  }

  bool _firebaseInitialized = false;
  FakeFirebaseMessaging? _firebaseMessaging;

  @override
  Future<void> firebaseInitializeApp() async {
    _firebaseInitialized = true;
  }

  /// The value `firebaseMessaging.getToken` will initialize the token to.
  ///
  /// After `firebaseMessaging.getToken` has been called once, this has no effect.
  set firebaseMessagingInitialToken(String value) {
    (_firebaseMessaging ??= FakeFirebaseMessaging())._initialToken = value;
  }

  @override
  FakeFirebaseMessaging get firebaseMessaging {
    assert(_firebaseInitialized);
    return (_firebaseMessaging ??= FakeFirebaseMessaging());
  }

  @override
  Stream<RemoteMessage> get firebaseMessagingOnMessage => firebaseMessaging.onMessage.stream;

  void _resetNotifications() {
    _notificationsPlugin = null;
  }

  FakeFlutterLocalNotificationsPlugin? _notificationsPlugin;

  @override
  FakeFlutterLocalNotificationsPlugin get notifications {
    return (_notificationsPlugin ??= FakeFlutterLocalNotificationsPlugin());
  }
}

class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  String? _initialToken;

  /// Set the token to a new value, as if it were newly generated.
  ///
  /// This will cause listeners of [onTokenRefresh] to be called, but
  /// in a microtask, not synchronously.
  void setToken(String value) {
    _token = value;
    _tokenController.add(value);
  }

  String? _token;

  final StreamController<String> _tokenController =
    StreamController<String>.broadcast();

  @override
  Future<String?> getToken({String? vapidKey}) async {
    assert(vapidKey == null);
    if (_token == null) {
      assert(_initialToken != null,
        'Tests that call [NotificationService.start], or otherwise cause'
        ' a call to `ZulipBinding.instance.firebaseMessaging.getToken`,'
        ' must set `testBinding.firebaseMessagingInitialToken` first.');

      // This causes [onTokenRefresh] to fire, just like the real [getToken]
      // does when no token exists (e.g., on first run after install).
      setToken(_initialToken!);
    }
    return _token;
  }

  @override
  Stream<String> get onTokenRefresh => _tokenController.stream;

  StreamController<RemoteMessage> onMessage = StreamController.broadcast();
}

class FakeFlutterLocalNotificationsPlugin extends Fake implements FlutterLocalNotificationsPlugin {
  InitializationSettings? initializationSettings;
  DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse;
  DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async {
    assert(this.initializationSettings == null);
    this.initializationSettings = initializationSettings;
    this.onDidReceiveNotificationResponse = onDidReceiveNotificationResponse;
    this.onDidReceiveBackgroundNotificationResponse = onDidReceiveBackgroundNotificationResponse;
    return true;
  }

  FlutterLocalNotificationsPlatform? _platform;

  @override
  T? resolvePlatformSpecificImplementation<T extends FlutterLocalNotificationsPlatform>() {
    // This follows the logic of the base class's implementation,
    // but supplies our fakes for the per-platform classes.
    assert(initializationSettings != null);
    assert(T != FlutterLocalNotificationsPlatform);
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        assert(_platform == null || _platform is FakeAndroidFlutterLocalNotificationsPlugin);
        if (T != AndroidFlutterLocalNotificationsPlugin) return null;
        return (_platform ??= FakeAndroidFlutterLocalNotificationsPlugin()) as T?;

      case TargetPlatform.iOS:
        assert(_platform == null || _platform is FakeIOSFlutterLocalNotificationsPlugin);
        if (T != IOSFlutterLocalNotificationsPlugin) return null;
        return (_platform ??= FakeIOSFlutterLocalNotificationsPlugin()) as T?;

      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  /// Consume the log of calls made to [show].
  ///
  /// This returns a list of the arguments to all calls made
  /// to [show] since the last call to this method.
  List<FlutterLocalNotificationsPluginShowCall> takeShowCalls() {
    final result = _showCalls;
    _showCalls = [];
    return result;
  }
  List<FlutterLocalNotificationsPluginShowCall> _showCalls = [];

  @override
  Future<void> show(int id, String? title, String? body,
      NotificationDetails? notificationDetails, {String? payload}) async {
    assert(initializationSettings != null);
    _showCalls.add((id, title, body, notificationDetails, payload: payload));
  }
}

typedef FlutterLocalNotificationsPluginShowCall = (
  int id, String? title, String? body,
  NotificationDetails? notificationDetails, {String? payload}
);

class FakeAndroidFlutterLocalNotificationsPlugin extends Fake implements AndroidFlutterLocalNotificationsPlugin {
  /// Consume the log of calls made to [createNotificationChannel].
  ///
  /// This returns a list of the arguments to all calls made
  /// to [createNotificationChannel] since the last call to this method.
  List<AndroidNotificationChannel> takeCreatedChannels() {
    final result = _createdChannels;
    _createdChannels = [];
    return result;
  }
  List<AndroidNotificationChannel> _createdChannels = [];

  @override
  Future<void> createNotificationChannel(AndroidNotificationChannel notificationChannel) async {
    _createdChannels.add(notificationChannel);
  }
}

class FakeIOSFlutterLocalNotificationsPlugin extends Fake implements IOSFlutterLocalNotificationsPlugin {
}
