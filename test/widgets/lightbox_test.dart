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
  static final FakeVideoPlayerPlatform instance = FakeVideoPlayerPlatform();

  static void registerWith() {
    VideoPlayerPlatform.instance = instance;
  }

  static const int _textureId = 0xffffffff;

  StreamController<VideoEvent> _streamController = StreamController<VideoEvent>();

  bool get initialized => _initialized;
  bool _initialized = false;

  bool get isPlaying => _isPlaying;
  bool _isPlaying = false;

  void reset() {
    _streamController.close();
    _streamController = StreamController<VideoEvent>();
    _initialized = false;
    _isPlaying = false;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {
    assert(_initialized);
    assert(textureId == _textureId);
    _initialized = false;
  }

  @override
  Future<int?> create(DataSource dataSource) async  {
    assert(!_initialized);
    _initialized = true;
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
    _isPlaying = true;
    _streamController.add(VideoEvent(
      eventType: VideoEventType.isPlayingStateUpdate,
      isPlaying: true,
    ));
  }

  @override
  Future<void> pause(int textureId) async {
    assert(textureId == _textureId);
    _isPlaying = false;
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

  group('VideoDurationLabel', () {
    const cases = [
      (Duration(milliseconds: 1),    '00:00',     '1ms'),
      (Duration(milliseconds: 900),  '00:00',     '900ms'),
      (Duration(milliseconds: 1000), '00:01',     '1000ms'),
      (Duration(seconds: 59),        '00:59',     '59s'),
      (Duration(seconds: 60),        '01:00',     '60s'),
      (Duration(minutes: 59),        '59:00',     '59m'),
      (Duration(minutes: 60),        '01:00:00',  '60m'),
      (Duration(hours: 23),          '23:00:00',  '23h'),
      (Duration(hours: 24),          '24:00:00',  '24h'),
      (Duration(hours: 25),          '25:00:00',  '25h'),
      (Duration(hours: 100),         '100:00:00', '100h'),
    ];

    for (final (duration, expected, title) in cases) {
      testWidgets('with $title shows $expected', (tester) async {
        await tester.pumpWidget(MaterialApp(home: VideoDurationLabel(duration)));
        final text = tester.widget<Text>(find.byType(Text));
        check(text.data)
          ..equals(VideoDurationLabel.formatDuration(duration))
          ..equals(expected);
      });
    }
  });

  group("VideoLightboxPage", () {
    FakeVideoPlayerPlatform.registerWith();
    final platform = FakeVideoPlayerPlatform.instance;

    Future<void> setupPage(WidgetTester tester, {
      required Uri videoSrc,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      addTearDown(platform.reset);

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

      check(platform.initialized).isTrue();
      check(platform.isPlaying).isTrue();

      await tester.ensureVisible(find.byType(VideoPlayer));
    });

    testWidgets('toggles between play and pause', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse('https://a/b.mp4'));
      check(platform.isPlaying).isTrue();

      await tester.tap(find.byIcon(Icons.pause_circle_rounded));
      check(platform.isPlaying).isFalse();

      // re-render to update player controls
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      check(platform.isPlaying).isTrue();
    });
  });
}
