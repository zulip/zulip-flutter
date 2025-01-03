import 'dart:async';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player/video_player.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/lightbox.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../test_images.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

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

  group('_ImageLightboxPage', () {
    final src = Uri.parse('https://chat.example/lightbox-image.png');

    Future<void> setupPage(WidgetTester tester, {
      Message? message,
      required Uri? thumbnailUrl,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      // ZulipApp instead of TestZulipApp because we need the navigator to push
      // the lightbox route. The lightbox page works together with the route;
      // it takes the route's entrance animation.
      await tester.pumpWidget(const ZulipApp());
      await tester.pump();
      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(getImageLightboxRoute(
        accountId: eg.selfAccount.id,
        message: message ?? eg.streamMessage(),
        src: src,
        thumbnailUrl: thumbnailUrl,
        originalHeight: null,
        originalWidth: null,
      )));
      await tester.pump(); // per-account store
      await tester.pump(const Duration(milliseconds: 301)); // nav transition
    }

    testWidgets('shows image', (tester) async {
      prepareBoringImageHttpClient();
      await setupPage(tester, thumbnailUrl: null);

      final image = tester.widget<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      check(image.src).equals(src);

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('app bar shows sender name and date', (tester) async {
      prepareBoringImageHttpClient();
      final timestamp = DateTime.parse("2024-07-23 23:12:24").millisecondsSinceEpoch ~/ 1000;
      final message = eg.streamMessage(sender: eg.otherUser, timestamp: timestamp);
      await setupPage(tester, message: message, thumbnailUrl: null);

      // We're looking for a RichText, in the app bar, with both the
      // sender's name and the timestamp.
      final labelTextWidget = tester.widget<RichText>(
        find.descendant(of: find.byType(AppBar).last,
          matching: find.textContaining(findRichText: true,
            eg.otherUser.fullName)));
      check(labelTextWidget.text.toPlainText())
        .contains('Jul 23, 2024 23:12:24');

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('app bar shows sender avatar', (tester) async {
      prepareBoringImageHttpClient();
      final message = eg.streamMessage(sender: eg.otherUser);
      await setupPage(tester, message: message, thumbnailUrl: null);

      final avatar = tester.widget<Avatar>(find.byType(Avatar));
      check(avatar.userId).equals(message.senderId);

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('header and footer hidden and shown by tapping image', (tester) async {
      prepareBoringImageHttpClient();
      final message = eg.streamMessage(sender: eg.otherUser);
      await setupPage(tester, message: message, thumbnailUrl: null);

      tester.widget(find.byType(AppBar));
      tester.widget(find.byType(BottomAppBar));

      await tester.tap(find.byType(ZulipApp));
      await tester.pump();
      check(tester.widgetList(find.byType(AppBar))).isEmpty();
      check(tester.widgetList(find.byType(BottomAppBar))).isEmpty();

      await tester.tap(find.byType(ZulipApp));
      await tester.pump();
      tester.widget(find.byType(AppBar));
      tester.widget(find.byType(BottomAppBar));

      debugNetworkImageHttpClientProvider = null;
    });

    // TODO test _CopyLinkButton
    // TODO test thumbnail gets shown, then gets replaced when main image loads
    // TODO test image is scaled down to fit, but not up
    // TODO test image doesn't change size when header and footer hidden/shown
    // TODO test image doesn't show in inset area by default, but does if user zooms/pans it there
    //
    // A draft version of some of those desired tests:
    //   https://github.com/zulip/zulip-flutter/commit/ec4078d459da749f16511b826c5f7c398b0fb874
    // Discussion related to that draft:
    //   https://github.com/zulip/zulip-flutter/pull/833#discussion_r1688762292
    //   https://github.com/zulip/zulip-flutter/pull/833#pullrequestreview-2200433626
    //   https://github.com/zulip/zulip-flutter/pull/833#issuecomment-2251782337
  });

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
        addTearDown(testBinding.reset);
        await tester.pumpWidget(TestZulipApp(
          child: VideoDurationLabel(duration)));
        await tester.pump();
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

    /// Find the position shown by the slider, and check the label agrees.
    Duration findSliderPosition(WidgetTester tester) {
      final sliderValue = tester.widget<Slider>(find.byType(Slider)).value;
      final result = Duration(milliseconds: sliderValue.toInt());
      check(tester.widget<RichText>(
          find.descendant(of: find.bySemanticsLabel('Current position'),
          matching: find.byType(RichText))).text.toPlainText())
        .equals(VideoDurationLabel.formatDuration(result));
      return result;
    }

    /// Check the slider and label show position [slider],
    /// and the actual position of the video controller is [video].
    void checkPositions(WidgetTester tester, {
      required Duration slider,
      required Duration video,
    }) {
      check(findSliderPosition(tester)).equals(slider);
      check(platform.position).equals(video);
    }

    /// Like [checkPositions], but expressed in units of [kTestVideoDuration].
    void checkPositionsRelative(WidgetTester tester, {
      required double slider,
      required double video,
    }) {
      checkPositions(tester,
        slider: kTestVideoDuration * slider,
        video: kTestVideoDuration * video);
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

      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: VideoLightboxPage(
          routeEntranceAnimation: kAlwaysCompleteAnimation,
          message: eg.streamMessage(),
          src: videoSrc)));
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

    testWidgets('toggles wakelock when playing state changes', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();
      check(TestZulipBinding.instance.wakelockEnabled).isTrue();

      await tester.tap(find.byIcon(Icons.pause_circle_rounded));
      check(platform.isPlaying).isFalse();
      check(TestZulipBinding.instance.wakelockEnabled).isFalse();

      // re-render to update player controls
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      check(platform.isPlaying).isTrue();
      check(TestZulipBinding.instance.wakelockEnabled).isTrue();
    });

    testWidgets('disables wakelock when disposed', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();
      check(TestZulipBinding.instance.wakelockEnabled).isTrue();

      // Replace current page with empty container,
      // disposing the previous page.
      await tester.pumpWidget(Container());

      check(TestZulipBinding.instance.wakelockEnabled).isFalse();
    });

    testWidgets('video advances over time and stops playing when it ends', (tester) async {
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();

      await tester.pump(kTestVideoDuration * 0.5);
      platform.pumpEvents();
      checkPositionsRelative(tester, slider: 0.5, video: 0.5);
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
      checkPositionsRelative(tester, slider: 1.0, video: 1.0);
      check(platform.isCompleted).isTrue(); // completed
      check(platform.isPlaying).isFalse(); // stopped playing

      // After the video ended.
      await tester.pump(const Duration(milliseconds: 500));
      platform.pumpEvents();
      checkPositionsRelative(tester, slider: 1.0, video: 1.0);
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
      checkPositionsRelative(tester, slider: 0.0, video: 0.0);

      await gesture.moveBy(trackLength * 0.2);
      await tester.pump();
      checkPositionsRelative(tester, slider: 0.2, video: 0.0);

      await gesture.moveBy(trackLength * 0.4);
      await tester.pump();
      checkPositionsRelative(tester, slider: 0.6, video: 0.0);

      await gesture.moveBy(trackLength * -0.2);
      await tester.pump();
      checkPositionsRelative(tester, slider: 0.4, video: 0.0);

      await gesture.up();
      await tester.pump();
      checkPositionsRelative(tester, slider: 0.4, video: 0.4);

      // Verify seekTo is called only once.
      check(platform.callLog.where((v) => v == 'seekTo').length).equals(1);
    });

    testWidgets('ensure slider doesn\'t flicker right after it is moved', (tester) async {
      // Regression test for a potential bug that we successfully avoided
      // but is described in the comment quoted here:
      //   https://github.com/zulip/zulip-flutter/pull/587#discussion_r1596190776
      await setupPage(tester, videoSrc: Uri.parse(kTestVideoUrl));
      check(platform.isPlaying).isTrue();

      final (trackStartPos, trackLength) = calculateSliderDimensions(tester);

      final gesture = await tester.startGesture(trackStartPos);
      await tester.pump();
      checkPositionsRelative(tester, slider: 0.0, video: 0.0);

      await gesture.moveBy(trackLength * 0.5);
      await tester.pump();
      checkPositionsRelative(tester, slider: 0.5, video: 0.0);

      await gesture.up();
      await tester.pump();
      checkPositionsRelative(tester, slider: 0.5, video: 0.5);

      // The video_player plugin only reports a new position every 500ms, alas:
      //   https://github.com/zulip/zulip-flutter/pull/694#discussion_r1635506000
      const videoPlayerPollIntervalMs = 500;
      const frameTimeMs = 10; // 100fps
      const maxIterations = 1 + videoPlayerPollIntervalMs ~/ frameTimeMs;

      // The slider may stay in place for several frames.
      // But find when it first moves again…
      int iterations = 0;
      Duration position = findSliderPosition(tester);
      final basePosition = position;
      while (true) {
        if (++iterations > maxIterations) break;
        await tester.pump(const Duration(milliseconds: frameTimeMs));
        position = findSliderPosition(tester);
        if (position != basePosition) break;
      }
      // … and check the movement is forward, and corresponds to the video.
      check(position).isGreaterThan(basePosition);
      check(platform.position).equals(position);
    });
  });
}
