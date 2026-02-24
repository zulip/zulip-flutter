// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:zulip/model/binding.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app.dart';

import '../../test/model/binding.dart';

/// The binding instance used in live Patrol tests.
///
/// Compare [testBinding].
PatrolLiveZulipBinding get patrolLiveBinding => PatrolLiveZulipBinding.instance;

/// A concrete [ZulipBinding] implementation for live Patrol tests.
///
/// This class is a subclass of [LiveZulipBinding], and provides all the
/// "live" bindings from that class.
/// This adds methods convenient for manipulating the state from tests.
///
/// Because this is a subclass of [LiveZulipBinding], calling [ensureInitialized]
/// will also have the effect of [LiveZulipBinding.ensureInitialized].
/// In live Patrol tests, call `PatrolLiveZulipBinding.ensureInitialized`
/// before [mainInit].
class PatrolLiveZulipBinding extends LiveZulipBinding {
  /// Initialize the binding if necessary, and ensure it is a [PatrolLiveZulipBinding].
  ///
  /// This method is idempotent; calling it repeatedly simply returns the
  /// existing binding.
  ///
  /// If there is an existing binding but it is not a [PatrolLiveZulipBinding],
  /// this method throws an error.
  static PatrolLiveZulipBinding ensureInitialized() {
    if (_instance == null) {
      PatrolLiveZulipBinding();
    }
    return instance;
  }

  /// The single instance of the binding.
  static PatrolLiveZulipBinding get instance => ZulipBinding.checkInstance(_instance);
  static PatrolLiveZulipBinding? _instance;

  @override
  void initInstance() {
    super.initInstance();
    _instance = this;
  }

  /// Reset all test data to a clean state.
  ///
  /// In particular this wipes the app's database.
  Future<void> reset() async {
    ZulipApp.debugReset();
    debugResetStore();
    final dbFile = await LiveGlobalStore.dbFile();
    try {
      await dbFile.delete();
    } on PathNotFoundException {
      // ignore
    }
  }
}
