import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../get/services/global_service.dart';
import '../model/store.dart';
import 'local_notifications.dart';

class BackgroundService extends GetxService {
  static BackgroundService get instance => Get.find<BackgroundService>();

  static const _channel = MethodChannel('zulip/background');
  static const _readyChannel = MethodChannel('zulip/ready');
  Timer? _backgroundFetchTimer;
  bool _isInitialized = false;

  Future<void> start() async {
    if (_isInitialized) return;

    // Wait for native to signal it's ready before trying to start
    _readyChannel.setMethodCallHandler(_handleReadyCall);

    debugPrint('BackgroundService: Waiting for native to be ready...');
  }

  Future<void> _handleReadyCall(MethodCall call) async {
    if (call.method == 'onNativeReady') {
      debugPrint('BackgroundService: Native is ready, starting...');
      await _tryStart();
    }
  }

  Future<void> _tryStart() async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('startBackgroundFetch');
      } else if (Platform.isAndroid) {
        await _channel.invokeMethod('startBackgroundService');
      }
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
      debugPrint('BackgroundService: Started successfully');
    } catch (e) {
      debugPrint('BackgroundService start failed: $e');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onBackgroundFetch':
        await _fetchNewMessages();
        return null;
      case 'onSilentPush':
        final payload = call.arguments as Map<dynamic, dynamic>?;
        if (payload != null) {
          await _handleSilentPush(payload);
        }
        return null;
      default:
        throw PlatformException(
          code: 'NotImplemented',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  Future<void> _fetchNewMessages() async {
    debugPrint('BackgroundService: Checking for new messages...');

    final globalStore = GlobalService.to.globalStore;
    if (globalStore == null) {
      debugPrint('BackgroundService: No global store');
      return;
    }

    // For each account, check for unreads and show notification if needed
    for (final accountId in globalStore.accountIds) {
      final store = globalStore.perAccountSync(accountId);
      if (store != null) {
        await _checkUnreadsForAccount(accountId, store);
      }
    }
  }

  Future<void> _checkUnreadsForAccount(
    int accountId,
    PerAccountStore store,
  ) async {
    final unreads = store.unreads;
    final messagesCount = unreads.countInCombinedFeedNarrow();
    final mentionsCount = unreads.countInMentionsNarrow();

    debugPrint(
      'BackgroundService: Account $accountId has $messagesCount messages, $mentionsCount mentions',
    );

    if (messagesCount > 0) {
      final dms = unreads.dms;
      final streams = unreads.streams;

      String title = 'Zulip';
      String body = '';

      if (dms.isNotEmpty) {
        body = 'You have $messagesCount unread messages';
      } else if (streams.isNotEmpty) {
        final streamId = streams.keys.first;
        final stream = store.channelStore.streams[streamId];
        final topics = streams[streamId]!;
        if (topics.isNotEmpty) {
          final topic = topics.keys.first;
          body =
              'You have unread messages in #${stream?.name ?? "unknown"}/$topic';
        }
      } else {
        body = 'You have $messagesCount unread messages';
      }

      if (mentionsCount > 0) {
        title = 'Zulip ($mentionsCount mentions)';
      }

      // Show local notification
      await LocalNotificationsService().showNotification(
        title: title,
        body: body,
        payload: 'account:$accountId',
      );
    }
  }

  Future<void> _handleSilentPush(Map<dynamic, dynamic> payload) async {
    debugPrint('BackgroundService: Received silent push: $payload');
    await _fetchNewMessages();
  }

  /// Manually trigger background fetch - useful for testing
  Future<void> triggerBackgroundFetch() async {
    debugPrint('BackgroundService: Manual trigger called');
    await _fetchNewMessages();
  }

  void startPeriodicFetch({Duration interval = const Duration(minutes: 15)}) {
    _backgroundFetchTimer?.cancel();
    _backgroundFetchTimer = Timer.periodic(interval, (_) {
      _fetchNewMessages();
    });
    debugPrint(
      'BackgroundService: Started periodic fetch every ${interval.inMinutes} minutes',
    );
  }

  void stopPeriodicFetch() {
    _backgroundFetchTimer?.cancel();
    _backgroundFetchTimer = null;
    debugPrint('BackgroundService: Stopped periodic fetch');
  }

  @override
  void onClose() {
    _backgroundFetchTimer?.cancel();
    super.onClose();
  }
}
