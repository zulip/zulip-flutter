import 'dart:async';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player/video_player.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/widgets/lightbox.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import 'dialog_checks.dart';

const kTestVideoUrl = "https://a/video.mp4";
const kTestUnsupportedVideoUrl = "https://a/unsupported.mp4";
const kTestVideoDuration = Duration(seconds: 10);

class FakeVideoPlayerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements VideoPlayerPlatform {
  static final FakeVideoPlayerPlatform instance = FakeVideoPlayerPlatform();

  static void registerWith() {
    VideoPlayerPlatform.instance = instance;
  }

  static const int _kTextureId = 0xffffffff;

  StreamController<VideoEvent> _streamController = StreamController<VideoEvent>();
  bool _hasError = false;
  Duration _lastSetPosition = Duration.zero;
  Stopwatch? _stopwatch;

  List<String> get callLog => _callLog;
  final List<String> _callLog = [];

  bool get initialized => _initialized;
  bool _initialized = false;

  bool get isCompleted => _isCompleted;
  bool _isCompleted = false;

  bool get isPlaying => _stopwatch?.isRunning ?? false;

  Duration get position {
    assert(_stopwatch != null);
    final pos = _stopwatch!.elapsed + _lastSetPosition;
    return pos >= kTestVideoDuration ? kTestVideoDuration : pos;
  }

  void reset() {
    _streamController.close();
    _streamController = StreamController<VideoEvent>();
    _hasError = false;
    _lastSetPosition = Duration.zero;
    _stopwatch?.stop();
    _stopwatch?.reset();
    _callLog.clear();
    _initialized = false;
    _isCompleted = false;
  }

  // This helper function explicitly dispatches events that are
  // automatically dispatched by the platform video player in
  // a real implementation:
  //  https://github.com/flutter/packages/blob/260102b64c0fac9c66b7574035421fa6c09f5f89/packages/video_player/video_player_android/android/src/main/java/io/flutter/plugins/videoplayer/VideoPlayer.java#L189
  void pumpEvents() {
    if (position >= kTestVideoDuration) {
      if (!_isCompleted) {
        _isCompleted = true;
        _streamController.add(VideoEvent(
          eventType: VideoEventType.completed,
        ));
      }

      if (isPlaying) {
        _stopwatch?.stop();
        _streamController.add(VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: false,
        ));
      }
    }
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {
    if (_hasError) {
      assert(!initialized);
      assert(textureId == VideoPlayerController.kUninitializedTextureId);
      return;
    }

    assert(initialized);
    assert(textureId == _kTextureId);
  }

  @override
  Future<int?> create(DataSource dataSource) async  {
    assert(!initialized);
    if (dataSource.uri == kTestUnsupportedVideoUrl) {
      _hasError = true;
      _streamController.addError(
        PlatformException(
          code: "VideoError",
          message: "Failed to load video: Cannot Open"));
      return null;
    }

    _stopwatch = clock.stopwatch();
    _initialized = true;
    _streamController.add(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: kTestVideoDuration,
      size: const Size(100, 100),
      rotationCorrection: 0,
    ));
    return _kTextureId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    assert(textureId == _kTextureId);
    return _streamController.stream;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {
    assert(textureId == _kTextureId);
    assert(!looping);
  }

  @override
  Future<void> play(int textureId) async {
    assert(textureId == _kTextureId);
    _stopwatch?.start();
    _streamController.add(VideoEvent(
      eventType: VideoEventType.isPlayingStateUpdate,
      isPlaying: true,
    ));
  }

  @override
  Future<void> pause(int textureId) async {
    assert(textureId == _kTextureId);
    _stopwatch?.stop();
    _streamController.add(VideoEvent(
      eventType: VideoEventType.isPlayingStateUpdate,
      isPlaying: false,
    ));
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    assert(textureId == _kTextureId);
  }

  @override
  Future<void> seekTo(int textureId, Duration pos) async {
    _callLog.add('seekTo');
    assert(textureId == _kTextureId);

    _lastSetPosition = pos >= kTestVideoDuration ? kTestVideoDuration : pos;
    _stopwatch?.reset();
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    assert(textureId == _kTextureId);
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    assert(textureId == _kTextureId);
    return position;
  }

  @override
  Widget buildView(int textureId) {
    assert(textureId == _kTextureId);
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

    // A helper to verify that expected positions matches the actual
    // positions of Slider, current position indicator label and the
    // video controller position. Where the video controller position
    // can differ from Slider and the position indicator label, hence the
    // need for two different expected position inputs (slider & video).
    void checkPositions(WidgetTester tester, {
      required Duration slider,
      required Duration video,
    }) {
      check(tester.widget<Slider>(find.byType(Slider)).value.toInt())
        .equals(slider.inMilliseconds);
      check(tester.widget<RichText>(
          find.descendant(of: find.bySemanticsLabel('Current position'),
          matching: find.byType(RichText))).text.toPlainText())
        .equals(VideoDurationLabel.formatDuration(slider));

      check(platform.position).equals(video);
    }

    (Offset, Offset) calculateSliderDimensions(WidgetTester tester) {
      const padding = 24.0;
      final rect = tester.getRect(find.byType(Slider));
      final trackStartPos = rect.centerLeft + const Offset(padding, 0);
      final trackLength = Offset(rect.width - padding - padding, 0);
      return (trackStartPos, trackLength);
    }

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
      await tester.pump(); // global store
      await tester.pump(); // per-account store
      await tester.pump(); // video controller initialization
    }

    testWidgets('shows a VideoPlayer, and video is playing', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));

      check(platform.initialized).isTrue();
      check(platform.isPlaying).isTrue();

      await tester.ensureVisible(find.byType(VideoPlayer));
    });

    testWidgets('toggles between play and pause', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();

      await tester.tap(find.byIcon(Icons.pause_circle_rounded));
      check(platform.isPlaying).isFalse();

      // re-render to update player controls
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      check(platform.isPlaying).isTrue();
    });

    testWidgets('unsupported video shows an error dialog', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestUnsupportedVideoUrl));
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorDialogTitle,
        expectedMessage: zulipLocalizations.errorVideoPlayerFailed)));
    });

    testWidgets('video advances over time and stops playing when it ends', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();

      await tester.pump(kTestVideoDuration * 0.5);
      platform.pumpEvents();
      checkPositions(tester,
        slider: kTestVideoDuration * 0.5,
        video: kTestVideoDuration * 0.5);
      check(platform.isCompleted).isFalse();
      check(platform.isPlaying).isTrue();

      // Near the end of the video.
      await tester.pump((kTestVideoDuration * 0.5) - const Duration(milliseconds: 500));
      platform.pumpEvents();
      checkPositions(tester,
        slider: kTestVideoDuration - const Duration(milliseconds: 500),
        video: kTestVideoDuration - const Duration(milliseconds: 500));
      check(platform.isCompleted).isFalse();
      check(platform.isPlaying).isTrue();

      // At exactly the end of the video.
      await tester.pump(const Duration(milliseconds: 500));
      platform.pumpEvents();
      checkPositions(tester,
        slider: kTestVideoDuration,
        video: kTestVideoDuration);
      check(platform.isCompleted).isTrue(); // completed
      check(platform.isPlaying).isFalse(); // stopped playing

      // After the video ended.
      await tester.pump(const Duration(milliseconds: 500));
      platform.pumpEvents();
      checkPositions(tester,
        slider: kTestVideoDuration,
        video: kTestVideoDuration);
      check(platform.isCompleted).isTrue();
      check(platform.isPlaying).isFalse();
    });

    testWidgets('ensure \'seekTo\' is called only once', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();

      final (trackStartPos, trackLength) = calculateSliderDimensions(tester);

      // Verify the actually displayed current position at each
      // gesture increments.
      final gesture = await tester.startGesture(trackStartPos);
      await tester.pump();
      checkPositions(tester,
        slider: Duration.zero,
        video: Duration.zero);

      await gesture.moveBy(trackLength * 0.2);
      await tester.pump();
      checkPositions(tester,
        slider: kTestVideoDuration * 0.2,
        video: Duration.zero);

      await gesture.moveBy(trackLength * 0.4);
      await tester.pump();
      checkPositions(tester,
        slider: kTestVideoDuration * 0.6,
        video: Duration.zero);

      await gesture.moveBy(-trackLength * 0.2);
      await tester.pump();
      checkPositions(tester,
        slider: kTestVideoDuration * 0.4,
        video: Duration.zero);

      await gesture.up();
      await tester.pump();
      checkPositions(tester,
        slider: kTestVideoDuration * 0.4,
        video: kTestVideoDuration * 0.4);

      // Verify seekTo is called only once.
      check(platform.callLog.where((v) => v == 'seekTo').length).equals(1);
    });

    testWidgets('ensure slider doesn\'t flicker right after it is moved', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();

      final (trackStartPos, trackLength) = calculateSliderDimensions(tester);

      final gesture = await tester.startGesture(trackStartPos);
      await tester.pump();
      checkPositions(tester,
        slider: Duration.zero,
        video: Duration.zero);

      await gesture.moveBy(trackLength * 0.5);
      await tester.pump();
      checkPositions(tester,
        slider: kTestVideoDuration * 0.5,
        video: Duration.zero);

      await gesture.up();
      await tester.pump();
      checkPositions(tester,
        slider: kTestVideoDuration * 0.5,
        video: kTestVideoDuration * 0.5);

      final basePosition = kTestVideoDuration * 0.5;
      Duration actualElapsed = basePosition;
      Duration lastPolled = basePosition;
      while (true) {
        if (lastPolled >= (basePosition + (const Duration(milliseconds: 500) * 4))) {
          // 4 iterations of slider updates
          break;
        }

        const frameTime = Duration(milliseconds: 10); // 100fps
        await tester.pump(frameTime);
        actualElapsed += frameTime;

        // Periodic timer interval at which video_player plugin notifies
        // of position events is 500ms.
        if (actualElapsed.inMilliseconds % 500 == 0) {
          lastPolled += const Duration(milliseconds: 500);
        }
        checkPositions(tester,
          slider: lastPolled,
          video: actualElapsed);
      }
    });
  });
}
