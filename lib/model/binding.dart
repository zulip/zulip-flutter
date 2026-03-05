import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart' as device_info_plus;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_messaging/firebase_messaging.dart' as firebase_messaging;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:wakelock_plus/wakelock_plus.dart' as wakelock_plus;

import '../host/android_intents.dart' as android_intents_pigeon;
import '../host/android_notifications.dart';
import '../host/notifications.dart' as notif_pigeon;
import '../log.dart';
import 'store.dart';

export 'package:file_picker/file_picker.dart' show FilePickerResult, FileType, PlatformFile;
export 'package:image_picker/image_picker.dart' show ImageSource, XFile;

/// Alias for [url_launcher.LaunchMode].
typedef UrlLaunchMode = url_launcher.LaunchMode;

/// Alias for [firebase_messaging.RemoteMessage].
typedef FirebaseRemoteMessage = firebase_messaging.RemoteMessage;

/// A singleton service providing the app's data and use of Flutter plugins.
///
/// Only one instance will be constructed in the lifetime of the app,
/// by calling the `ensureInitialized` static method on a subclass.
/// This instance can be accessed as [instance].
///
/// Most code should not interact with the bindings directly.
/// Instead, use the corresponding higher-level APIs that expose the bindings'
/// functionality in a widget-oriented way; see [PlatformActions] for some.
///
/// This piece of architecture is modelled on the "binding" classes in Flutter
/// itself.  For discussion, see [BindingBase], [WidgetsFlutterBinding], and
/// [TestWidgetsFlutterBinding].
/// This version is simplified because we don't (yet?) have enough complexity
/// to put into these bindings to need to use mixins to split them up.
abstract class ZulipBinding {
  ZulipBinding() {
    assert(_instance == null);
    initInstance();
  }

  /// The single instance of [ZulipBinding].
  static ZulipBinding get instance => checkInstance(_instance);
  static ZulipBinding? _instance;

  static T checkInstance<T extends ZulipBinding>(T? instance) {
    assert(() {
      if (instance == null) {
        throw FlutterError.fromParts([
          ErrorSummary('Zulip binding has not yet been initialized.'),
          ErrorHint(
            'In the app, this is done by the `LiveZulipBinding.ensureInitialized()` call '
            'in the `void main()` method.',
          ),
          ErrorHint(
            'In a test, one can call `TestZulipBinding.ensureInitialized()` as the '
            'first line in the test\'s `main()` method to initialize the binding.',
          ),
        ]);
      }
      return true;
    }());
    return instance!;
  }

  /// Initialize the binding instance.
  ///
  /// This does the job of a constructor, but can be overridden in mixins
  /// as well as in ordinary classes.
  @protected
  @mustCallSuper
  void initInstance() {
    _instance = this;
  }

  /// Get the app's singleton [GlobalStore],
  /// loading it asynchronously if not already loaded.
  ///
  /// Where possible, use [GlobalStoreWidget.of] to get access to a [GlobalStore].
  /// Use this method only in contexts like notifications where
  /// a widget tree may not exist.
  Future<GlobalStore> getGlobalStore();

  /// Get the app's singleton [GlobalStore] if already loaded, else null.
  ///
  /// Where possible, use [GlobalStoreWidget.of] to get access to a [GlobalStore].
  /// Use this method only in contexts where getting access to a [BuildContext]
  /// is inconvenient.
  GlobalStore? getGlobalStoreSync();

  /// Like [getGlobalStore], but assert this method was not previously called.
  ///
  /// This is used by the implementation of [GlobalStoreWidget],
  /// so that our test framework code can detect some cases where
  /// a widget test neglects to clean up with `testBinding.reset`.
  Future<GlobalStore> getGlobalStoreUniquely();

  /// If true, make [getGlobalStoreUniquely] behave just like [getGlobalStore].
  bool debugRelaxGetGlobalStoreUniquely = false;

  /// Checks whether the platform can launch [url], via package:url_launcher.
  ///
  /// This wraps [url_launcher.canLaunchUrl].
  Future<bool> canLaunchUrl(Uri url);

  /// Pass [url] to the underlying platform, via package:url_launcher.
  ///
  /// This wraps [url_launcher.launchUrl].
  Future<bool> launchUrl(
    Uri url, {
    url_launcher.LaunchMode mode = url_launcher.LaunchMode.platformDefault,
  });

  /// Checks whether [closeInAppWebView] is supported, via package:url_launcher.
  ///
  /// This wraps [url_launcher.supportsCloseForLaunchMode].
  Future<bool> supportsCloseForLaunchMode(url_launcher.LaunchMode mode);

  /// Closes the current in-app web view, via package:url_launcher.
  ///
  /// This wraps [url_launcher.closeInAppWebView].
  Future<void> closeInAppWebView();

  /// Provides access to the current UTC date and time.
  ///
  /// Outside tests, this just calls [DateTime.timestamp].
  DateTime utcNow();

  /// Provides access to a new stopwatch.
  ///
  /// Outside tests, this just calls the [Stopwatch] constructor.
  Stopwatch stopwatch();

  /// Provides device and operating system information,
  /// via package:device_info_plus.
  ///
  /// The returned Future resolves to null if an error is
  /// encountered while fetching the data.
  ///
  /// This wraps [device_info_plus.DeviceInfoPlugin.deviceInfo].
  Future<BaseDeviceInfo?> get deviceInfo;

  /// Provides device and operating system information,
  /// via package:device_info_plus.
  ///
  /// This is the value [deviceInfo] resolved to,
  /// or null if that hasn't resolved yet.
  BaseDeviceInfo? get syncDeviceInfo;

  /// Provides application package information,
  /// via package:package_info_plus.
  ///
  /// The returned Future resolves to null if an error is
  /// encountered while fetching the data.
  ///
  /// This wraps [package_info_plus.PackageInfo.fromPlatform].
  Future<PackageInfo?> get packageInfo;

  /// Provides application package information,
  /// via package:package_info_plus.
  ///
  /// This is the value [packageInfo] resolved to,
  /// or null if that hasn't resolved yet.
  PackageInfo? get syncPackageInfo;

  /// Initialize Firebase, to use for notifications.
  ///
  /// This wraps [firebase_core.Firebase.initializeApp].
  Future<void> firebaseInitializeApp({
      required firebase_core.FirebaseOptions options});

  /// Wraps [firebase_messaging.FirebaseMessaging.instance].
  firebase_messaging.FirebaseMessaging get firebaseMessaging;

  /// Wraps [firebase_messaging.FirebaseMessaging.onMessage].
  Stream<firebase_messaging.RemoteMessage> get firebaseMessagingOnMessage;

  /// Wraps [firebase_messaging.FirebaseMessaging.onBackgroundMessage].
  void firebaseMessagingOnBackgroundMessage(firebase_messaging.BackgroundMessageHandler handler);

  /// Wraps the [AndroidNotificationHostApi] constructor.
  AndroidNotificationHostApi get androidNotificationHost;

  /// Wraps the [notif_pigeon.NotificationHostApi] class.
  NotificationPigeonApi get notificationPigeonApi;

  Stream<android_intents_pigeon.AndroidIntentEvent> get androidIntentEvents;

  /// Pick files from the media library, via package:file_picker.
  ///
  /// This wraps [file_picker.pickFiles].
  Future<file_picker.FilePickerResult?> pickFiles({
    bool allowMultiple,
    bool withReadStream,
    file_picker.FileType type,
  });

  /// Pick files from the camera or media library, via package:image_picker.
  ///
  /// This wraps [image_picker.pickImage].
  Future<image_picker.XFile?> pickImage({
    required image_picker.ImageSource source,
    bool requestFullMetadata,
  });

  /// Enables or disables keeping the screen on, via package:wakelock_plus.
  ///
  /// This wraps [wakelock_plus.WakelockPlus.toggle].
  ///
  /// Despite the name, this does not involve Android's "wake locks".
  /// The implementation sets FLAG_KEEP_SCREEN_ON on Android:
  ///   https://developer.android.com/develop/background-work/background-tasks/awake/screen-on
  ///   https://github.com/fluttercommunity/wakelock_plus/blob/5ca5243e7894830ce289fc367bc5fdec27c7f0cf/wakelock_plus/android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/Wakelock.kt
  /// and idleTimerDisabled on iOS:
  ///   https://developer.apple.com/documentation/uikit/uiapplication/1623070-idletimerdisabled
  ///   https://github.com/fluttercommunity/wakelock_plus/blob/5ca5243e7894830ce289fc367bc5fdec27c7f0cf/wakelock_plus/ios/Classes/WakelockPlusPlugin.m
  Future<void> toggleWakelock({required bool enable});
}

/// Like [device_info_plus.BaseDeviceInfo], but without things we don't use.
abstract class BaseDeviceInfo {
  const BaseDeviceInfo();
}

/// Like [device_info_plus.AndroidDeviceInfo], but without things we don't use.
class AndroidDeviceInfo extends BaseDeviceInfo {
  /// The Android version string, Build.VERSION.RELEASE, e.g. "14".
  ///
  /// Upstream documents this as an opaque string with no particular structure,
  /// but e.g. on stock Android 14 it's "14".
  ///
  /// See: https://developer.android.com/reference/android/os/Build.VERSION#RELEASE
  final String release;

  /// The Android SDK version.
  ///
  /// Possible values are defined in:
  ///   https://developer.android.com/reference/android/os/Build.VERSION_CODES.html
  final int sdkInt;

  const AndroidDeviceInfo({required this.release, required this.sdkInt});
}

/// Like [device_info_plus.IosDeviceInfo], but without things we don't use.
class IosDeviceInfo extends BaseDeviceInfo {
  /// The current operating system version.
  ///
  /// See: https://developer.apple.com/documentation/uikit/uidevice/1620043-systemversion
  final String systemVersion;

  const IosDeviceInfo({required this.systemVersion});
}

/// Like [device_info_plus.MacOsDeviceInfo], but without things we don't use.
class MacOsDeviceInfo extends BaseDeviceInfo {
  /// See: https://developer.apple.com/documentation/foundation/operatingsystemversion/1414662-majorversion
  final int majorVersion;

  /// See: https://developer.apple.com/documentation/foundation/operatingsystemversion/1413801-minorversion
  final int minorVersion;

  /// See: https://developer.apple.com/documentation/foundation/operatingsystemversion/1415564-patchversion
  final int patchVersion;

  const MacOsDeviceInfo({
    required this.majorVersion,
    required this.minorVersion,
    required this.patchVersion,
  });
}

/// Like [device_info_plus.WindowsDeviceInfo], currently only used to
/// determine if we're on Windows.
// TODO Determine a method to identify the Windows version.
//  Currently, we do not include Windows version information because
//  Windows OS does not provide a straightforward way to obtain
//  recognizable version information.
//  Here's an example of `WindowsDeviceInfo` data[1]. Based on that
//  data, there are two possible approaches to identify the Windows
//  version:
//    - One approach is to use a combination of the majorVersion,
//      minorVersion, and buildNumber fields. However, this data does
//      not directly correspond to recognizable Windows versions
//      (for example major=10, minor=0, build=22631 actually represents
//      "Windows 11, 23H2"). Refer to the link in this comment[2] for
//      Chromium's implementation of parsing Windows version numbers.
//    - Another approach is to use the productName field. While this
//      field contains the Windows version, it also includes extraneous
//      information. For example, some productName strings are:
//      "Windows 11 Pro" and "Windows 10 Home Single Language", which
//      makes it less ideal.
//  [1]: https://gist.github.com/rajveermalviya/58b3add437280cc7f8356f3697099b7c
//  [2]: https://github.com/zulip/zulip-flutter/pull/724#discussion_r1628318991
class WindowsDeviceInfo implements BaseDeviceInfo {
  const WindowsDeviceInfo();
}

/// Like [device_info_plus.LinuxDeviceInfo], but without things we don't use.
class LinuxDeviceInfo implements BaseDeviceInfo {
  /// The operating system name, 'NAME' field in /etc/os-release.
  ///
  /// Examples: 'Fedora', 'Debian GNU/Linux', or just 'Linux'.
  ///
  /// See: https://www.freedesktop.org/software/systemd/man/latest/os-release.html#NAME=
  final String name;

  /// The operating system version, 'VERSION_ID' field in /etc/os-release.
  ///
  /// This string contains only the version number and excludes the
  /// OS name and version codenames.
  ///
  /// Examples: '17', '11.04'.
  ///
  /// See: https://www.freedesktop.org/software/systemd/man/latest/os-release.html#VERSION_ID=
  final String? versionId;

  const LinuxDeviceInfo({required this.name, required this.versionId});
}

/// Like [package_info_plus.PackageInfo], but without things we don't use.
class PackageInfo {
  final String version;
  final String buildNumber;
  final String packageName;

  const PackageInfo({
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });
}

// Pigeon generates methods under `@EventChannelApi` annotated classes
// in global scope of the generated file. This is a helper class to
// namespace the notification related Pigeon API under a single class.
class NotificationPigeonApi {
  final _hostApi = notif_pigeon.NotificationHostApi();

  Future<notif_pigeon.NotificationDataFromLaunch?> getNotificationDataFromLaunch() =>
    _hostApi.getNotificationDataFromLaunch();

  /// An event stream that emits a notification payload
  /// when a notification is tapped.
  ///
  /// For details, see [notif_pigeon.notificationTapEvents].
  Stream<notif_pigeon.NotificationTapEvent> notificationTapEventsStream() =>
    notif_pigeon.notificationTapEvents();
}

/// An implementation of the app's data store binding for use in the live app.
///
/// The global store returned by [getGlobalStore], and consequently by
/// [GlobalStoreWidget.of] in application code, will be a [LiveGlobalStore].
/// It therefore uses a live server and live, persistent local database.
mixin LiveZulipStoreBinding on ZulipBinding {
  @override
  Future<GlobalStore> getGlobalStore() {
    return _globalStoreFuture ??= LiveGlobalStore.load().then((store) {
      return _globalStore = store;
    });
  }

  @override
  GlobalStore? getGlobalStoreSync() => _globalStore;

  Future<GlobalStore>? _globalStoreFuture;
  GlobalStore? _globalStore;

  @override
  Future<GlobalStore> getGlobalStoreUniquely() {
    assert(debugRelaxGetGlobalStoreUniquely
        || _debugEnforceGetGlobalStoreUniquely());
    return getGlobalStore();
  }

  bool _debugEnforceGetGlobalStoreUniquely() {
    assert(!_debugCalledGetGlobalStoreUniquely);
    assert(_debugCalledGetGlobalStoreUniquely = true);
    return true;
  }
  bool _debugCalledGetGlobalStoreUniquely = false;

  @visibleForTesting
  void debugResetStore() {
    assert(!(_globalStoreFuture != null && _globalStore == null),
      // If we proceeded naively without this check, then the previous
      // LiveGlobalStore.load().then(…) could clobber _globalStore later.
      // If necessary, we could add some logic to support canceling/ignoring
      // that previous call.
      "attempted debugResetStore while in the middle of loading store");
    _globalStore?.dispose();
    _globalStore = null;
    _globalStoreFuture = null;
    assert(() {
     _debugCalledGetGlobalStoreUniquely = false;
      return true;
    }());
  }
}

/// An implementation of the app's miscellaneous needs from plugins and the
/// device platform, for use in the live app.
///
/// Methods wrapping a plugin, like [launchUrl], invoke the actual
/// underlying plugin method.
mixin LiveZulipDeviceBinding on ZulipBinding {
  @override
  void initInstance() {
    super.initInstance();
    _deviceInfo = _prefetchDeviceInfo();
    _packageInfo = _prefetchPackageInfo();
  }

  @override
  Future<bool> canLaunchUrl(Uri url) => url_launcher.canLaunchUrl(url);

  @override
  Future<bool> launchUrl(
    Uri url, {
    url_launcher.LaunchMode mode = url_launcher.LaunchMode.platformDefault,
  }) {
    return url_launcher.launchUrl(url, mode: mode);
  }

  @override
  Future<bool> supportsCloseForLaunchMode(url_launcher.LaunchMode mode) async {
    return url_launcher.supportsCloseForLaunchMode(mode);
  }

  @override
  Future<void> closeInAppWebView() async {
    return url_launcher.closeInAppWebView();
  }

  @override
  DateTime utcNow() => DateTime.timestamp();

  @override
  Stopwatch stopwatch() => Stopwatch();

  @override
  Future<BaseDeviceInfo?> get deviceInfo => _deviceInfo;
  late Future<BaseDeviceInfo?> _deviceInfo;

  @override
  BaseDeviceInfo? get syncDeviceInfo => _syncDeviceInfo;
  BaseDeviceInfo? _syncDeviceInfo;

  Future<BaseDeviceInfo?> _prefetchDeviceInfo() async {
    try {
      final info = await device_info_plus.DeviceInfoPlugin().deviceInfo;
      _syncDeviceInfo = switch (info) {
        device_info_plus.AndroidDeviceInfo() => AndroidDeviceInfo(release: info.version.release,
                                                                  sdkInt: info.version.sdkInt),
        device_info_plus.IosDeviceInfo()     => IosDeviceInfo(systemVersion: info.systemVersion),
        device_info_plus.MacOsDeviceInfo()   => MacOsDeviceInfo(majorVersion: info.majorVersion,
                                                                minorVersion: info.minorVersion,
                                                                patchVersion: info.patchVersion),
        device_info_plus.WindowsDeviceInfo() => const WindowsDeviceInfo(),
        device_info_plus.LinuxDeviceInfo()   => LinuxDeviceInfo(name: info.name,
                                                                versionId: info.versionId),
        _                                    => throw UnimplementedError(),
      };
    } catch (e, st) {
      assert(debugLog('Failed to prefetch device info: $e\n$st')); // TODO(log)
    }
    return _syncDeviceInfo;
  }

  @override
  Future<PackageInfo?> get packageInfo => _packageInfo;
  late Future<PackageInfo?> _packageInfo;

  @override
  PackageInfo? get syncPackageInfo => _syncPackageInfo;
  PackageInfo? _syncPackageInfo;

  Future<PackageInfo?> _prefetchPackageInfo() async {
    try {
      final info = await package_info_plus.PackageInfo.fromPlatform();
      _syncPackageInfo = PackageInfo(
        version: info.version,
        buildNumber: info.buildNumber,
        packageName: info.packageName,
      );
    } catch (e, st) {
      assert(debugLog('Failed to prefetch package info: $e\n$st')); // TODO(log)
    }
    return _syncPackageInfo;
  }

  @override
  Future<void> firebaseInitializeApp({
      required firebase_core.FirebaseOptions options}) {
    return firebase_core.Firebase.initializeApp(options: options);
  }

  @override
  firebase_messaging.FirebaseMessaging get firebaseMessaging {
    return firebase_messaging.FirebaseMessaging.instance;
  }

  @override
  Stream<firebase_messaging.RemoteMessage> get firebaseMessagingOnMessage {
    return firebase_messaging.FirebaseMessaging.onMessage;
  }

  @override
  void firebaseMessagingOnBackgroundMessage(firebase_messaging.BackgroundMessageHandler handler) {
    firebase_messaging.FirebaseMessaging.onBackgroundMessage(handler);
  }

  @override
  AndroidNotificationHostApi get androidNotificationHost => AndroidNotificationHostApi();

  @override
  NotificationPigeonApi get notificationPigeonApi => NotificationPigeonApi();

  @override
  Stream<android_intents_pigeon.AndroidIntentEvent> get androidIntentEvents => android_intents_pigeon.androidIntentEvents();

  @override
  Future<file_picker.FilePickerResult?> pickFiles({
    bool allowMultiple = false,
    bool withReadStream = false,
    file_picker.FileType type = file_picker.FileType.any,
  }) async {
    return file_picker.FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      withReadStream: withReadStream,
      type: type,
    );
  }

  @override
  Future<image_picker.XFile?> pickImage({
    required image_picker.ImageSource source,
    bool requestFullMetadata = true,
  }) async {
    return image_picker.ImagePicker()
      .pickImage(source: source, requestFullMetadata: requestFullMetadata);
  }

  @override
  Future<void> toggleWakelock({required bool enable}) async {
    return wakelock_plus.WakelockPlus.toggle(enable: enable);
  }
}

/// A concrete binding for use in the live application.
///
/// The global store returned by [getGlobalStore], and consequently by
/// [GlobalStoreWidget.of] in application code, will be a [LiveGlobalStore].
/// It therefore uses a live server and live, persistent local database.
///
/// Methods wrapping a plugin, like [launchUrl], invoke the actual
/// underlying plugin method.
class LiveZulipBinding extends ZulipBinding with LiveZulipStoreBinding, LiveZulipDeviceBinding {
  /// Initialize the binding if necessary, and ensure it is a [LiveZulipBinding].
  static LiveZulipBinding ensureInitialized() {
    if (ZulipBinding._instance == null) {
      LiveZulipBinding();
    }
    return ZulipBinding.instance as LiveZulipBinding;
  }

}
