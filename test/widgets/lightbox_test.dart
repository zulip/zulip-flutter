import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player/video_player.dart';
import 'package:zulip/widgets/lightbox.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';

class FakeVideoPlayerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements VideoPlayerPlatform {
  static const int _textureId = 0xffffffff;

  static StreamController<VideoEvent> _streamController = StreamController<VideoEvent>();
  static bool initialized = false;
  static bool isPlaying = false;

  static void registerWith() {
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  }

  static void reset() {
    _streamController.close();
    _streamController = StreamController<VideoEvent>();
    initialized = false;
    isPlaying = false;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {
    assert(initialized);
    assert(textureId == _textureId);
    initialized = false;
  }

  @override
  Future<int?> create(DataSource dataSource) async  {
    assert(!initialized);
    initialized = true;
    _streamController.add(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 1),
      size: const Size(0, 0),
      rotationCorrection: 0,
    ));
    return _textureId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    assert(textureId == _textureId);
    return _streamController.stream;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {
    assert(textureId == _textureId);
    assert(!looping);
  }

  @override
  Future<void> play(int textureId) async {
    assert(textureId == _textureId);
    isPlaying = true;
    _streamController.add(VideoEvent(
      eventType: VideoEventType.isPlayingStateUpdate,
      isPlaying: true,
    ));
  }

  @override
  Future<void> pause(int textureId) async {
    assert(textureId == _textureId);
    isPlaying = false;
    _streamController.add(VideoEvent(
      eventType: VideoEventType.isPlayingStateUpdate,
      isPlaying: false,
    ));
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    assert(textureId == _textureId);
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    assert(textureId == _textureId);
  }

  @override
  Widget buildView(int textureId) {
    assert(textureId == _textureId);
    return const SizedBox(width: 100, height: 100);
  }
}

void main() {
  TestZulipBinding.ensureInitialized();

  group("VideoLightboxPage", () {
    FakeVideoPlayerPlatform.registerWith();

    Future<void> setupPage(WidgetTester tester, {
      required Uri videoSrc,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      addTearDown(FakeVideoPlayerPlatform.reset);

      await tester.pumpWidget(GlobalStoreWidget(child: MaterialApp(
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        home: PerAccountStoreWidget(
          accountId: eg.selfAccount.id,
          child: VideoLightboxPage(
            routeEntranceAnimation: kAlwaysCompleteAnimation,
            message: eg.streamMessage(),
            src: videoSrc)))));
      await tester.pumpAndSettle();
    }

    testWidgets('shows a VideoPlayer, and video is playing', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse('https://a/b.mp4'));

      check(FakeVideoPlayerPlatform.initialized).isTrue();
      check(FakeVideoPlayerPlatform.isPlaying).isTrue();

      await tester.ensureVisible(find.byType(VideoPlayer));
    });

    testWidgets('toggles between play and pause', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse('https://a/b.mp4'));
      check(FakeVideoPlayerPlatform.isPlaying).isTrue();

      await tester.tap(find.byIcon(Icons.pause_circle_rounded));
      check(FakeVideoPlayerPlatform.isPlaying).isFalse();

      // re-render to update player controls
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      check(FakeVideoPlayerPlatform.isPlaying).isTrue();
    });
  });
}
