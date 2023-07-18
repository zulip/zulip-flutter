import 'package:device_info_plus/device_info_plus.dart' as device_info_plus;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
export 'package:url_launcher/url_launcher.dart' show LaunchMode;

import '../widgets/store.dart';
import 'store.dart';

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

  /// Prepare the app's [GlobalStore], loading the necessary data.
  ///
  /// Generally the app should call this function only once.
  ///
  /// This is part of the implementation of [GlobalStoreWidget].
  /// In application code, use [GlobalStoreWidget.of] to get access
  /// to a [GlobalStore].
  Future<GlobalStore> loadGlobalStore();

  /// Pass [url] to the underlying platform, via package:url_launcher.
  ///
  /// This wraps [url_launcher.launchUrl].
  Future<bool> launchUrl(
    Uri url, {
    url_launcher.LaunchMode mode = url_launcher.LaunchMode.platformDefault,
  });

  /// Provides device and operating system information,
  /// via package:device_info_plus.
  ///
  /// This wraps [device_info_plus.DeviceInfoPlugin.deviceInfo].
  Future<BaseDeviceInfo> deviceInfo();
}

/// Like [device_info_plus.BaseDeviceInfo], but without things we don't use.
abstract class BaseDeviceInfo {
  BaseDeviceInfo();
}

/// Like [device_info_plus.AndroidDeviceInfo], but without things we don't use.
class AndroidDeviceInfo extends BaseDeviceInfo {
  /// The Android SDK version.
  ///
  /// Possible values are defined in:
  ///   https://developer.android.com/reference/android/os/Build.VERSION_CODES.html
  final int sdkInt;

  AndroidDeviceInfo({required this.sdkInt});
}

/// Like [device_info_plus.IosDeviceInfo], but without things we don't use.
class IosDeviceInfo extends BaseDeviceInfo {
  /// The current operating system version.
  ///
  /// See: https://developer.apple.com/documentation/uikit/uidevice/1620043-systemversion
  final String systemVersion;

  IosDeviceInfo({required this.systemVersion});
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
      LiveZulipBinding();
    }
    return ZulipBinding.instance as LiveZulipBinding;
  }

  @override
  Future<GlobalStore> loadGlobalStore() {
    return LiveGlobalStore.load();
  }

  @override
  Future<bool> launchUrl(
    Uri url, {
    url_launcher.LaunchMode mode = url_launcher.LaunchMode.platformDefault,
  }) {
    return url_launcher.launchUrl(url, mode: mode);
  }

  @override
  Future<BaseDeviceInfo> deviceInfo() async {
    final deviceInfo = await device_info_plus.DeviceInfoPlugin().deviceInfo;
    return switch (deviceInfo) {
      device_info_plus.AndroidDeviceInfo(:var version)   => AndroidDeviceInfo(sdkInt: version.sdkInt),
      device_info_plus.IosDeviceInfo(:var systemVersion) => IosDeviceInfo(systemVersion: systemVersion),
      _                                                  => throw UnimplementedError(),
    };
  }
}
