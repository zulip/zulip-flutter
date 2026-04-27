// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:zulip/model/binding.dart';
import 'package:zulip/widgets/app.dart';

import '../test/model/binding.dart';

/// The binding instance used in semi-live tests.
///
/// Compare [testBinding].
SemiLiveZulipBinding get semiLiveBinding => SemiLiveZulipBinding.instance;

/// A concrete [ZulipBinding] implementation for semi-live Patrol tests.
///
/// The data store, and requests to the Zulip server, are fake.
/// The plugins and device-platform APIs are real.
class SemiLiveZulipBinding extends ZulipBinding
    with LiveZulipDeviceBinding, TestBindingBase, TestZulipStoreBinding {
  /// Initialize the binding if necessary, and ensure it is a [SemiLiveZulipBinding].
  ///
  /// This method is idempotent; calling it repeatedly simply returns the
  /// existing binding.
  ///
  /// If there is an existing binding but it is not a [SemiLiveZulipBinding],
  /// this method throws an error.
  static SemiLiveZulipBinding ensureInitialized() {
    if (_instance == null) {
      SemiLiveZulipBinding();
    }
    return instance;
  }

  /// The single instance of the binding.
  static SemiLiveZulipBinding get instance => ZulipBinding.checkInstance(_instance);
  static SemiLiveZulipBinding? _instance;

  @override
  void initInstance() {
    super.initInstance();
    _instance = this;
  }

  @override
  void reset() {
    ZulipApp.debugReset();
    super.reset();
  }
}
