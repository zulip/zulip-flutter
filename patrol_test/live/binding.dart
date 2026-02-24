// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:zulip/api/core.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/app.dart';

import '../../test/example_data.dart' as eg;
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

/// The live Zulip credentials provided in the build environment.
///
/// In Patrol tests, these come from `.patrol.env` at the root of the tree.
/// See `docs/patrol.md`.
abstract class LiveCredentials {
  static const realmUrlStr = String.fromEnvironment('REALM_URL');
  static final realmUrl = Uri.parse(const String.fromEnvironment('REALM_URL'));

  static const email = String.fromEnvironment('EMAIL');
  static const password = String.fromEnvironment('PASSWORD');
  static final userId = int.parse(const String.fromEnvironment('USER_ID'), radix: 10);
  static const apiKey = String.fromEnvironment('API_KEY');

  static const otherEmail = String.fromEnvironment('OTHER_EMAIL');
  static const otherApiKey = String.fromEnvironment('OTHER_API_KEY');

  static Account account({
    int? id,
    String? realmName,
    Uri? realmIcon,
    int? zulipFeatureLevel,
    String? zulipVersion,
    String? zulipMergeBase,
  }) {
    return eg.account(
      realmUrl: realmUrl,
      user: eg.user(
        userId: userId,
        deliveryEmail: email),
      apiKey: apiKey,
      id: id,
      realmName: realmName,
      realmIcon: realmIcon,
      zulipFeatureLevel: zulipFeatureLevel,
      zulipVersion: zulipVersion,
      zulipMergeBase: zulipMergeBase,
    );
  }

  static ApiConnection makeOtherConnection() {
    return ApiConnection.live(
      realmUrl: realmUrl,
      email: otherEmail,
      apiKey: otherApiKey,
      zulipFeatureLevel: eg.recentZulipFeatureLevel, // TODO get real value from server
    );
  }
}
