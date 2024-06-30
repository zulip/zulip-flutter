import 'package:device_info_plus/device_info_plus.dart' as device_info_plus;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_messaging/firebase_messaging.dart' as firebase_messaging;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../host/android_notifications.dart';
import '../log.dart';
import '../widgets/store.dart';
import 'store.dart';

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
/// functionality in a widget-oriented way.
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

  @protected
  @mustCallSuper
  void initInstance() {
    _instance = this;
  }

  /// Provides device and operating system information,
  /// via package:device_info_plus.
  ///
  /// This wraps [device_info_plus.DeviceInfoPlugin.deviceInfo].
  BaseDeviceInfo? get deviceInfo;

  /// Provides application package information,
  /// via package:package_info_plus.
  ///
  /// This wraps [package_info_plus.PackageInfo.fromPlatform].
  PackageInfo? get packageInfo;

  /// Prepare the app's [GlobalStore], loading the necessary data.
  ///
  /// Generally the app should call this function only once.
  ///
  /// This is part of the implementation of [GlobalStoreWidget].
  /// In application code, use [GlobalStoreWidget.of] to get access
  /// to a [GlobalStore].
  Future<GlobalStore> loadGlobalStore();

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

  /// Wraps the [FlutterLocalNotificationsPlugin] singleton constructor.
  FlutterLocalNotificationsPlugin get notifications;

  /// Wraps the [AndroidNotificationHostApi] constructor.
  AndroidNotificationHostApi get androidNotificationHost;

  /// Generates a user agent header for HTTP requests.
  ///
  /// Uses [deviceInfo] to get operating system information
  /// and [packageInfo] to get application version information.
  Map<String, String> userAgentHeader();
}

/// Like [device_info_plus.BaseDeviceInfo], but without things we don't use.
abstract class BaseDeviceInfo {
  BaseDeviceInfo();
}

/// Like [device_info_plus.AndroidDeviceInfo], but without things we don't use.
class AndroidDeviceInfo extends BaseDeviceInfo {
  /// The user-visible version string.
  ///
  /// E.g., "1.0" or "3.4b5" or "bananas". This field is an opaque string.
  /// Do not assume that its value has any particular structure or that
  /// values of RELEASE from different releases can be somehow ordered.
  final String release;

  /// The Android SDK version.
  ///
  /// Possible values are defined in:
  ///   https://developer.android.com/reference/android/os/Build.VERSION_CODES.html
  final int sdkInt;

  AndroidDeviceInfo({required this.release, required this.sdkInt});
}

/// Like [device_info_plus.IosDeviceInfo], but without things we don't use.
class IosDeviceInfo extends BaseDeviceInfo {
  /// The current operating system version.
  ///
  /// See: https://developer.apple.com/documentation/uikit/uidevice/1620043-systemversion
  final String systemVersion;

  IosDeviceInfo({required this.systemVersion});
}

/// Like [device_info_plus.MacOsDeviceInfo], but without things we don't use.
class MacOsDeviceInfo extends BaseDeviceInfo {
  /// The major release number, such as 10 in version 10.9.3.
  final int majorVersion;

  /// The minor release number, such as 9 in version 10.9.3.
  final int minorVersion;

  /// The update release number, such as 3 in version 10.9.3.
  final int patchVersion;

  MacOsDeviceInfo({
    required this.majorVersion,
    required this.minorVersion,
    required this.patchVersion,
  });
}

/// Like [device_info_plus.WindowsDeviceInfo], currently only used to
/// determine if we're on Windows.
class WindowsDeviceInfo implements BaseDeviceInfo {}

/// Like [device_info_plus.LinuxDeviceInfo], but without things we don't use.
///
/// See:
///   https://www.freedesktop.org/software/systemd/man/os-release.html
class LinuxDeviceInfo implements BaseDeviceInfo {
  /// A string identifying the operating system, without a version component,
  /// and suitable for presentation to the user.
  ///
  /// Examples: 'Fedora', 'Debian GNU/Linux'.
  ///
  /// If not set, defaults to 'Linux'.
  final String name;

  /// A lower-case string identifying the operating system version, excluding
  /// any OS name information or release code name, and suitable for processing
  /// by scripts or usage in generated filenames.
  ///
  /// The version is mostly numeric, and contains no spaces or other characters
  /// outside of 0–9, a–z, '.', '_' and '-'.
  ///
  /// Examples: '17', '11.04'.
  ///
  /// This field is optional and may be null on some systems.
  final String? versionId;

  LinuxDeviceInfo({required this.name, required this.versionId});
}

/// Like [package_info_plus.PackageInfo], but without things we don't use.
class PackageInfo {
  final String version;
  final String buildNumber;

  PackageInfo({
    required this.version,
    required this.buildNumber,
  });
}

/// A concrete binding for use in the live application.
///
/// The global store returned by [loadGlobalStore], and consequently by
/// [GlobalStoreWidget.of] in application code, will be a [LiveGlobalStore].
/// It therefore uses a live server and live, persistent local database.
///
/// Methods wrapping a plugin, like [launchUrl], invoke the actual
/// underlying plugin method.
class LiveZulipBinding extends ZulipBinding {
  /// Initialize the binding if necessary, and ensure it is a [LiveZulipBinding].
  static LiveZulipBinding ensureInitialized() {
    if (ZulipBinding._instance == null) {
      final binding = LiveZulipBinding();
      binding._prefetchDeviceInfo();
      binding._prefetchPackageInfo();
    }
    return ZulipBinding.instance as LiveZulipBinding;
  }

  // Stored user agent header, since it remains constant.
  Map<String, String>? _userAgentHeader;

  @override
  BaseDeviceInfo? get deviceInfo => _deviceInfo;
  BaseDeviceInfo? _deviceInfo;

  @override
  PackageInfo? get packageInfo => _packageInfo;
  PackageInfo? _packageInfo;

  Future<void> _prefetchDeviceInfo() async {
    final info = await device_info_plus.DeviceInfoPlugin().deviceInfo;
    _deviceInfo = switch (info) {
      device_info_plus.AndroidDeviceInfo() => AndroidDeviceInfo(release: info.version.release,
                                                                sdkInt: info.version.sdkInt),
      device_info_plus.IosDeviceInfo()     => IosDeviceInfo(systemVersion: info.systemVersion),
      device_info_plus.MacOsDeviceInfo()   => MacOsDeviceInfo(majorVersion: info.majorVersion,
                                                              minorVersion: info.minorVersion,
                                                              patchVersion: info.patchVersion),
      device_info_plus.WindowsDeviceInfo() => WindowsDeviceInfo(),
      device_info_plus.LinuxDeviceInfo()   => LinuxDeviceInfo(name: info.name,
                                                              versionId: info.versionId),
      _                                    => throw UnimplementedError(),
    };
  }

  Future<void> _prefetchPackageInfo() async {
    final info = await package_info_plus.PackageInfo.fromPlatform();
    _packageInfo =  PackageInfo(
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }

  @override
  Future<GlobalStore> loadGlobalStore() {
    return LiveGlobalStore.load();
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
  FlutterLocalNotificationsPlugin get notifications => FlutterLocalNotificationsPlugin();

  @override
  AndroidNotificationHostApi get androidNotificationHost => AndroidNotificationHostApi();

  @override
  Map<String, String> userAgentHeader() {
    if (deviceInfo == null || packageInfo == null) {
      debugLog('userAgentHeader: Dependencies not initialized, falling back to \'ZulipFlutter\'.');
      return {'User-Agent': 'ZulipFlutter'}; // TODO(log)
    }
    return _userAgentHeader ??= buildUserAgentHeader(deviceInfo!, packageInfo!);
  }
}

@visibleForTesting
Map<String, String> buildUserAgentHeader(BaseDeviceInfo deviceInfo, PackageInfo packageInfo) {
  final osInfo = switch (deviceInfo) {
    AndroidDeviceInfo(
      :var release)       => 'Android $release', // "Android 14"
    IosDeviceInfo(
      :var systemVersion) => 'iOS $systemVersion', // "iOS 17.4"
    MacOsDeviceInfo(
      :var majorVersion,
      :var minorVersion,
      :var patchVersion)  => 'macOS $majorVersion.$minorVersion.$patchVersion', // "macOS 14.5.0"
    WindowsDeviceInfo()   => 'Windows', // "Windows"
    LinuxDeviceInfo(
      :var name,
      :var versionId)     => 'Linux; $name${versionId != null ? ' $versionId' : ''}', // "Linux; Fedora Linux 40" or "Linux; Fedora Linux"
    _                     => throw UnimplementedError(),
  };
  final PackageInfo(:version, :buildNumber) = packageInfo;

  // Possible examples:
  //  'ZulipFlutter/0.0.15+15 (Android 14)'
  //  'ZulipFlutter/0.0.15+15 (iOS 17.4)'
  //  'ZulipFlutter/0.0.15+15 (macOS 14.5.0)'
  //  'ZulipFlutter/0.0.15+15 (Windows)'
  //  'ZulipFlutter/0.0.15+15 (Linux; Fedora Linux 40)'
  return {
    'User-Agent': 'ZulipFlutter/$version+$buildNumber ($osInfo)',
  };
}
