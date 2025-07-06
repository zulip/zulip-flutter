import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:test/fake.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:zulip/host/android_notifications.dart';
import 'package:zulip/host/notifications.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app.dart';

import '../example_data.dart' as eg;
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
/// The global store returned by [getGlobalStore], and consequently by
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
    ZulipApp.debugReset();
    _resetStore();
    _resetCanLaunchUrl();
    _resetLaunchUrl();
    _resetCloseInAppWebView();
    _resetDeviceInfo();
    _resetPackageInfo();
    _resetFirebase();
    _resetNotifications();
    _resetPickFiles();
    _resetPickImage();
    _resetWakelock();
  }

  /// The current global store offered to a [GlobalStoreWidget].
  ///
  /// The store is created lazily when accessing this getter, or when mounting
  /// a [GlobalStoreWidget].  The same store will continue to be provided until
  /// a call to [reset].
  ///
  /// Tests that access this getter, or that mount a [GlobalStoreWidget],
  /// should clean up by calling [reset].
  TestGlobalStore get globalStore => _globalStore ??= eg.globalStore();
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
  Future<GlobalStore> getGlobalStore() => Future.value(globalStore);

  @override
  GlobalStore? getGlobalStoreSync() => globalStore;

  @override
  Future<GlobalStore> getGlobalStoreUniquely() {
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
    return getGlobalStore();
  }

  /// The value that `ZulipBinding.instance.canLaunchUrl()` should return.
  ///
  /// See also [takeCanLaunchUrlCalls].
  bool canLaunchUrlResult = true;

  void _resetCanLaunchUrl() {
    canLaunchUrlResult = true;
    _canLaunchUrlCalls = null;
  }

  /// Consume the log of calls made to `ZulipBinding.instance.canLaunchUrl()`.
  ///
  /// This returns a list of the arguments to all calls made
  /// to `ZulipBinding.instance.canLaunchUrl()` since the last call to
  /// either this method or [reset].
  ///
  /// See also [canLaunchUrlResult].
  List<Uri> takeCanLaunchUrlCalls() {
    final result = _canLaunchUrlCalls;
    _canLaunchUrlCalls = null;
    return result ?? [];
  }
  List<Uri>? _canLaunchUrlCalls;

  @override
  Future<bool> canLaunchUrl(Uri url) async {
    (_canLaunchUrlCalls ??= []).add(url);
    return canLaunchUrlResult;
  }

  /// The value that `ZulipBinding.instance.launchUrl()` should return.
  ///
  /// See also:
  ///   * [launchUrlException]
  ///   * [takeLaunchUrlCalls]
  bool launchUrlResult = true;

  /// The [PlatformException] that `ZulipBinding.instance.launchUrl()` should throw.
  ///
  /// See also:
  ///   * [launchUrlResult]
  ///   * [takeLaunchUrlCalls]
  PlatformException? launchUrlException;

  void _resetLaunchUrl() {
    launchUrlResult = true;
    launchUrlException = null;
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

    if (!launchUrlResult && launchUrlException != null) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'TestZulipBinding.launchUrl called '
          'with launchUrlResult: false and non-null launchUrlException'),
        ErrorHint(
          'Tests should either set launchUrlResult or launchUrlException, '
          'but not both.'),
      ]);
    }

    if (launchUrlException != null) {
      throw launchUrlException!;
    }

    return launchUrlResult;
  }

  @override
  Future<bool> supportsCloseForLaunchMode(url_launcher.LaunchMode mode) async => true;

  void _resetCloseInAppWebView() {
    _closeInAppWebViewCallCount = 0;
  }

  /// Read and reset the count of calls to `ZulipBinding.instance.closeInAppWebView()`.
  int takeCloseInAppWebViewCallCount() {
    final result = _closeInAppWebViewCallCount;
    _closeInAppWebViewCallCount = 0;
    return result;
  }
  int _closeInAppWebViewCallCount = 0;

  @override
  Future<void> closeInAppWebView() async {
    _closeInAppWebViewCallCount++;
  }

  @override
  DateTime utcNow() => clock.now().toUtc();

  @override
  Stopwatch stopwatch() => clock.stopwatch();

  /// The value that `ZulipBinding.instance.deviceInfo` should return.
  BaseDeviceInfo deviceInfoResult = _defaultDeviceInfoResult;
  static const _defaultDeviceInfoResult = AndroidDeviceInfo(sdkInt: 33, release: '13');

  void _resetDeviceInfo() {
    deviceInfoResult = _defaultDeviceInfoResult;
  }

  @override
  Future<BaseDeviceInfo?> get deviceInfo async => deviceInfoResult;

  @override
  BaseDeviceInfo? get syncDeviceInfo => deviceInfoResult;

  /// The value that `ZulipBinding.instance.packageInfo` should return.
  PackageInfo packageInfoResult = _defaultPackageInfo;
  static final _defaultPackageInfo = eg.packageInfo();

  void _resetPackageInfo() {
    packageInfoResult = _defaultPackageInfo;
  }

  @override
  Future<PackageInfo?> get packageInfo async => packageInfoResult;

  @override
  PackageInfo? get syncPackageInfo => packageInfoResult;

  void _resetFirebase() {
    _firebaseInitialized = false;
    _firebaseMessaging = null;
  }

  bool _firebaseInitialized = false;
  FakeFirebaseMessaging? _firebaseMessaging;

  @override
  Future<void> firebaseInitializeApp({required FirebaseOptions options}) async {
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

  @override
  void firebaseMessagingOnBackgroundMessage(BackgroundMessageHandler handler) {
    firebaseMessaging.onBackgroundMessage.stream.listen(handler);
  }

  void _resetNotifications() {
    _androidNotificationHostApi = null;
    _notificationPigeonApi = null;
  }

  @override
  FakeAndroidNotificationHostApi get androidNotificationHost =>
    (_androidNotificationHostApi ??= FakeAndroidNotificationHostApi());
  FakeAndroidNotificationHostApi? _androidNotificationHostApi;

  @override
  FakeNotificationPigeonApi get notificationPigeonApi =>
    (_notificationPigeonApi ??= FakeNotificationPigeonApi());
  FakeNotificationPigeonApi? _notificationPigeonApi;

  /// The value that `ZulipBinding.instance.pickFiles()` should return.
  ///
  /// See also [takePickFilesCalls].
  FilePickerResult? pickFilesResult;

  void _resetPickFiles() {
    pickFilesResult = null;
    _pickFilesCalls = null;
  }

  /// Consume the log of calls made to `ZulipBinding.instance.pickFiles()`.
  ///
  /// This returns a list of the arguments to all calls made
  /// to `ZulipBinding.instance.pickFiles()` since the last call to
  /// either this method or [reset].
  ///
  /// See also [pickFilesResult].
  List<({
    bool? allowMultiple,
    bool? withReadStream,
    FileType? type,
  })> takePickFilesCalls() {
    final result = _pickFilesCalls;
    _pickFilesCalls = null;
    return result ?? [];
  }
  List<({
    bool? allowMultiple,
    bool? withReadStream,
    FileType? type,
  })>? _pickFilesCalls;

  @override
  Future<FilePickerResult?> pickFiles({
    bool? allowMultiple,
    bool? withReadStream,
    FileType? type,
  }) async {
    (_pickFilesCalls ??= []).add((allowMultiple: allowMultiple, withReadStream: withReadStream, type: type));
    return pickFilesResult;
  }

  /// The value that `ZulipBinding.instance.pickImage()` should return.
  ///
  /// See also [takePickImageCalls].
  XFile? pickImageResult;

  void _resetPickImage() {
    pickImageResult = null;
    _pickImageCalls = null;
  }

  /// Consume the log of calls made to `ZulipBinding.instance.pickImage()`.
  ///
  /// This returns a list of the arguments to all calls made
  /// to `ZulipBinding.instance.pickImage()` since the last call to
  /// either this method or [reset].
  ///
  /// See also [pickImageResult].
  List<({
    ImageSource source,
    bool requestFullMetadata,
  })> takePickImageCalls() {
    final result = _pickImageCalls;
    _pickImageCalls = null;
    return result ?? [];
  }
  List<({
    ImageSource source,
    bool requestFullMetadata,
  })>? _pickImageCalls;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    bool requestFullMetadata = true,
  }) async {
    (_pickImageCalls ??= []).add((source: source, requestFullMetadata: requestFullMetadata));
    return pickImageResult;
  }

  /// Returns the current status of wakelock, which can be
  /// changed via [toggleWakelock].
  bool get wakelockEnabled => _wakelockEnabled;
  bool _wakelockEnabled = false;

  void _resetWakelock() {
    _wakelockEnabled = false;
  }

  @override
  Future<void> toggleWakelock({required bool enable}) async {
    _wakelockEnabled = enable;
  }
}

class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  //|//////////////////////////////
  // Permissions.

  NotificationSettings requestPermissionResult = const NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.disabled,
    authorizationStatus: AuthorizationStatus.authorized,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.disabled,
    lockScreen: AppleNotificationSetting.enabled,
    notificationCenter: AppleNotificationSetting.enabled,
    showPreviews: AppleShowPreviewSetting.whenAuthenticated,
    timeSensitive: AppleNotificationSetting.disabled,
    criticalAlert: AppleNotificationSetting.disabled,
    sound: AppleNotificationSetting.enabled,
    providesAppNotificationSettings: AppleNotificationSetting.disabled,
  );

  List<FirebaseMessagingRequestPermissionCall> takeRequestPermissionCalls() {
    final result = _requestPermissionCalls;
    _requestPermissionCalls = [];
    return result;
  }
  List<FirebaseMessagingRequestPermissionCall> _requestPermissionCalls = [];

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    _requestPermissionCalls.add((
      alert: alert,
      announcement: announcement,
      badge: badge,
      carPlay: carPlay,
      criticalAlert: criticalAlert,
      provisional: provisional,
      sound: sound,
      providesAppNotificationSettings: providesAppNotificationSettings,
    ));
    return requestPermissionResult;
  }

  //|//////////////////////////////
  // Tokens.

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

  @override
  Future<String?> getAPNSToken() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // In principle the APNs token is unrelated to any FCM token.
        // But for tests it's convenient to have just one version of
        // [TestBinding.firebaseMessagingInitialToken].
        return _initialToken;

      case TargetPlatform.android:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  //|//////////////////////////////
  // Messages.

  StreamController<RemoteMessage> onMessage = StreamController.broadcast();

  /// Controls [TestZulipBinding.firebaseMessagingOnBackgroundMessage].
  ///
  /// Calling [StreamController.add] on this will cause a call
  /// to any handler registered through that method.
  StreamController<RemoteMessage> onBackgroundMessage = StreamController.broadcast();
}

typedef FirebaseMessagingRequestPermissionCall = ({
  bool alert,
  bool announcement,
  bool badge,
  bool carPlay,
  bool criticalAlert,
  bool provisional,
  bool sound,
  bool providesAppNotificationSettings,
});

class FakeAndroidNotificationHostApi implements AndroidNotificationHostApi {
  // TODO(?): Find a better way to handle this. This member is exported from
  //   the Pigeon generated class but are not used for this fake class,
  //   so return the default value.
  @override
  // ignore: non_constant_identifier_names
  final BinaryMessenger? pigeonVar_binaryMessenger = null;

  // TODO(?): Find a better way to handle this. This member is exported from
  //   the Pigeon generated class but are not used for this fake class,
  //   so return the default value.
  @override
  // ignore: non_constant_identifier_names
  final String pigeonVar_messageChannelSuffix = '';

  /// Lists currently active channels, result is aggregated from calls made to
  /// [createNotificationChannel] and [deleteNotificationChannel],
  /// order of creation is preserved.
  Iterable<NotificationChannel> get activeChannels => _activeChannels.values;
  final Map<String, NotificationChannel> _activeChannels = {};

  /// Consume the log of calls made to [createNotificationChannel].
  ///
  /// This returns a list of the arguments to all calls made
  /// to [createNotificationChannel] since the last call to this method.
  List<NotificationChannel> takeCreatedChannels() {
    final result = _createdChannels;
    _createdChannels = [];
    return result;
  }
  List<NotificationChannel> _createdChannels = [];

  @override
  Future<void> createNotificationChannel(NotificationChannel channel) async {
    _createdChannels.add(channel);
    _activeChannels[channel.id] = channel;
  }

  @override
  Future<List<NotificationChannel>> getNotificationChannels() async {
    return _activeChannels.values.toList(growable: false);
  }

  /// Consume the log of calls made to [deleteNotificationChannel].
  ///
  /// This returns a list of the arguments to all calls made
  /// to [deleteNotificationChannel] since the last call to this method.
  List<String> takeDeletedChannels() {
    final result = _deletedChannels;
    _deletedChannels = [];
    return result;
  }
  List<String> _deletedChannels = [];

  @override
  Future<void> deleteNotificationChannel(String channelId) async {
    _deletedChannels.add(channelId);
    _activeChannels.remove(channelId);
  }

  /// A URL that the fake [copySoundResourceToMediaStore] would produce
  /// for a resource with the given name.
  String fakeStoredNotificationSoundUrl(String resourceName) {
    return 'content://media/external_primary/audio/media/$resourceName';
  }

  final _storedNotificationSounds = <StoredNotificationSound>[];

  /// Populates the media store with the provided entries.
  void setupStoredNotificationSounds(List<StoredNotificationSound> sounds) {
    _storedNotificationSounds.addAll(sounds);
  }

  @override
  Future<List<StoredNotificationSound>> listStoredSoundsInNotificationsDirectory() async {
    return _storedNotificationSounds.toList(growable: false);
  }

  /// Consume the log of calls made to [copySoundResourceToMediaStore].
  ///
  /// This returns a list of the arguments to all calls made
  /// to [copySoundResourceToMediaStore] since the last call to this method.
  List<CopySoundResourceToMediaStoreCall> takeCopySoundResourceToMediaStoreCalls() {
    final result = _copySoundResourceToMediaStoreCalls;
    _copySoundResourceToMediaStoreCalls = [];
    return result;
  }
  List<CopySoundResourceToMediaStoreCall> _copySoundResourceToMediaStoreCalls = [];

  @override
  Future<String> copySoundResourceToMediaStore({
    required String targetFileDisplayName,
    required String sourceResourceName,
  }) async {
    _copySoundResourceToMediaStoreCalls.add((
      targetFileDisplayName: targetFileDisplayName,
      sourceResourceName: sourceResourceName));

    final url = fakeStoredNotificationSoundUrl(sourceResourceName);
    _storedNotificationSounds.add(StoredNotificationSound(
      fileName: targetFileDisplayName,
      isOwned: true,
      contentUrl: url));
    return url;
  }

  /// Consume the log of calls made to [notify].
  ///
  /// This returns a list of the arguments to all calls made
  /// to [notify] since the last call to this method.
  List<AndroidNotificationHostApiNotifyCall> takeNotifyCalls() {
    final result = _notifyCalls;
    _notifyCalls = [];
    return result;
  }
  List<AndroidNotificationHostApiNotifyCall> _notifyCalls = [];

  Iterable<StatusBarNotification> get activeNotifications => _activeNotifications.values;
  final Map<(int, String?), StatusBarNotification> _activeNotifications = {};

  final Map<String, MessagingStyle?> _activeNotificationsMessagingStyle = {};

  /// Clears all active notifications that have been created via [notify].
  void clearActiveNotifications() {
    _activeNotifications.clear();
    _activeNotificationsMessagingStyle.clear();
  }

  @override
  Future<void> notify({
    String? tag,
    required int id,
    bool? autoCancel,
    required String channelId,
    int? color,
    PendingIntent? contentIntent,
    String? contentText,
    String? contentTitle,
    Map<String, String>? extras,
    String? groupKey,
    InboxStyle? inboxStyle,
    bool? isGroupSummary,
    MessagingStyle? messagingStyle,
    int? number,
    String? smallIconResourceName,
  }) async {
    _notifyCalls.add((
      tag: tag,
      id: id,
      autoCancel: autoCancel,
      channelId: channelId,
      color: color,
      contentIntent: contentIntent,
      contentText: contentText,
      contentTitle: contentTitle,
      extras: extras,
      groupKey: groupKey,
      inboxStyle: inboxStyle,
      isGroupSummary: isGroupSummary,
      messagingStyle: messagingStyle,
      number: number,
      smallIconResourceName: smallIconResourceName,
    ));

    if (tag != null) {
      _activeNotifications[(id, tag)] = StatusBarNotification(
        id: id,
        notification: Notification(group: groupKey ?? '', extras: extras ?? {}),
        tag: tag);

      _activeNotificationsMessagingStyle[tag] = messagingStyle == null
        ? null
        : MessagingStyle(
            user: messagingStyle.user,
            conversationTitle: messagingStyle.conversationTitle,
            isGroupConversation: messagingStyle.isGroupConversation,
            messages: messagingStyle.messages.map((message) =>
              MessagingStyleMessage(
                text: message.text,
                timestampMs: message.timestampMs,
                person: Person(
                  key: message.person.key,
                  name: message.person.name,
                  iconBitmap: null)),
            ).toList(growable: false));
    }
  }

  @override
  Future<MessagingStyle?> getActiveNotificationMessagingStyleByTag(String tag) async =>
    _activeNotificationsMessagingStyle[tag];

  @override
  Future<List<StatusBarNotification>> getActiveNotifications({required List<String> desiredExtras}) async {
    return _activeNotifications.values.map((statusNotif) {
      final notificationExtras = statusNotif.notification.extras;
      statusNotif.notification.extras = {
        for (final key in desiredExtras)
          if (notificationExtras[key] != null)
            key: notificationExtras[key]!,
      };
      return statusNotif;
    }).toList(growable: false);
  }

  @override
  Future<void> cancel({String? tag, required int id}) async {
    _activeNotifications.remove((id, tag));
  }
}

class FakeNotificationPigeonApi implements NotificationPigeonApi {
  NotificationDataFromLaunch? _notificationDataFromLaunch;

  /// Populates the notification data for launch to be returned
  /// by [getNotificationDataFromLaunch].
  void setNotificationDataFromLaunch(NotificationDataFromLaunch? data) {
    _notificationDataFromLaunch = data;
  }

  @override
  Future<NotificationDataFromLaunch?> getNotificationDataFromLaunch() async =>
    _notificationDataFromLaunch;

  StreamController<NotificationTapEvent>? _notificationTapEventsStreamController;

  void addNotificationTapEvent(NotificationTapEvent event) {
    _notificationTapEventsStreamController!.add(event);
  }

  @override
  Stream<NotificationTapEvent> notificationTapEventsStream() {
    _notificationTapEventsStreamController ??= StreamController();
    return _notificationTapEventsStreamController!.stream;
  }
}

typedef AndroidNotificationHostApiNotifyCall = ({
  String? tag,
  int id,
  bool? autoCancel,
  String channelId,
  int? color,
  PendingIntent? contentIntent,
  String? contentText,
  String? contentTitle,
  Map<String?, String?>? extras,
  String? groupKey,
  InboxStyle? inboxStyle,
  bool? isGroupSummary,
  MessagingStyle? messagingStyle,
  int? number,
  String? smallIconResourceName,
});

typedef CopySoundResourceToMediaStoreCall = ({
  String targetFileDisplayName,
  String sourceResourceName,
});
