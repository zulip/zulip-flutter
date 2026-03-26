import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import 'dialog.dart';
import 'skeleton.dart';

class _VoiceTimelineTrackShape extends RoundedRectSliderTrackShape {
  const _VoiceTimelineTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, parentBox.size.width, trackHeight);
  }
}

class AudioPlayerBottomSheet extends StatefulWidget {
  const AudioPlayerBottomSheet({
    super.key,
    required this.src,
    required this.title,
    this.userName,
    this.userAvatarUrl,
    this.sentTime,
  });

  final Uri src;
  final String title;
  final String? userName;
  final String? userAvatarUrl;
  final DateTime? sentTime;

  @override
  State<AudioPlayerBottomSheet> createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
  static const _playbackSpeeds = <double>[0.5, 1.0, 1.5, 2.0];

  late final AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isTogglingPlayback = false;
  bool _isSliderDragging = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _sliderValue = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      if (_isSliderDragging) return;
      setState(() => _position = position);
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = _duration;
      });
    });

    unawaited(_initialize());
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_playerCompleteSubscription?.cancel());
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setSource(UrlSource(widget.src.toString()));
      final duration = await _audioPlayer.getDuration();
      if (!mounted) return;
      setState(() {
        _duration = duration ?? Duration.zero;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorDialogTitle,
        message: e.toString(),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _togglePlayback() async {
    if (_isTogglingPlayback) return;

    setState(() => _isTogglingPlayback = true);
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      var startPosition = _position;
      final reachedEnd = _duration > Duration.zero && _position >= _duration;
      if (reachedEnd) {
        startPosition = Duration.zero;
        await _audioPlayer.seek(Duration.zero);
        if (mounted) {
          setState(() => _position = Duration.zero);
        }
      }

      final positionBeforeStart = startPosition;
      await _audioPlayer.resume();
      await _audioPlayer.setPlaybackRate(_playbackSpeed);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      final currentPosition = await _audioPlayer.getCurrentPosition();
      final playbackAdvanced = currentPosition != null && currentPosition > positionBeforeStart;
      if (!_isPlaying && !playbackAdvanced) {
        await _audioPlayer.play(
          UrlSource(widget.src.toString()),
          position: startPosition,
        );
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
      }
    } catch (e) {
      if (!mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorDialogTitle,
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingPlayback = false);
      }
    }
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    if (_isPlaying) {
      await _audioPlayer.setPlaybackRate(speed);
    }
  }

  Future<void> _seekTo(Duration newPosition) async {
    await _audioPlayer.seek(newPosition);
    if (!mounted) return;
    setState(() => _position = newPosition);
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final displayPosition = _isSliderDragging ? _sliderValue : _position;
    final maxDuration = _duration > Duration.zero
      ? _duration
      : const Duration(milliseconds: 1);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.95),
              Colors.blue.shade50.withValues(alpha: 0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Username header - enlarged and bold
              if (widget.userName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    widget.userName!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.95),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Voice timeline - modern progress line style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final progressFraction = (displayPosition.inMilliseconds
                                / maxDuration.inMilliseconds)
                            .clamp(0.0, 1.0);
                        final progressWidth = constraints.maxWidth * progressFraction;

                        return SizedBox(
                          height: 24,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                width: progressWidth,
                                height: 6,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(999)),
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF3DB6B1), Color(0xFF007E6E)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6,
                                  trackShape: const _VoiceTimelineTrackShape(),
                                  activeTrackColor: Colors.transparent,
                                  inactiveTrackColor: Colors.transparent,
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                    elevation: 1,
                                    pressedElevation: 2,
                                  ),
                                  overlayColor: const Color(0x33007E6E),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                ),
                                child: Slider(
                                  value: displayPosition.inMilliseconds
                                      .clamp(0, maxDuration.inMilliseconds)
                                      .toDouble(),
                                  max: maxDuration.inMilliseconds.toDouble(),
                                  onChangeStart: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _isSliderDragging = true;
                                          _sliderValue = Duration(milliseconds: value.round());
                                        });
                                      },
                                  onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _sliderValue = Duration(milliseconds: value.round());
                                        });
                                      },
                                  onChangeEnd: _isLoading
                                    ? null
                                    : (value) async {
                                        final newPosition = Duration(milliseconds: value.round());
                                        await _seekTo(newPosition);
                                        if (!mounted) return;
                                        setState(() {
                                          _isSliderDragging = false;
                                          _sliderValue = newPosition;
                                        });
                                      },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Time display
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(displayPosition),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Speed controls - single row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _playbackSpeeds.map((speed) {
                      final selected = _playbackSpeed == speed;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF0066FF) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? const Color(0xFF0066FF) : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading
                                ? null
                                : () {
                                    _setPlaybackSpeed(speed);
                                  },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  child: Text(
                                    speed == speed.roundToDouble()
                                      ? '${speed.toStringAsFixed(0)}x'
                                      : '${speed.toStringAsFixed(1)}x',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                      color: selected 
                                        ? Colors.white
                                        : Colors.black.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),

              // Play/Pause button - centered with #0066ff background
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: IconButton(
                      onPressed: (_isLoading || _isTogglingPlayback) ? null : _togglePlayback,
                      icon: _isLoading
                        ? SkeletonLoader(
                            width: 24,
                            height: 24,
                            shape: BoxShape.circle,
                          )
                        : Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                      iconSize: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
