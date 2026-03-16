import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../model/voice_recorder.dart';
import 'waveform_visualizer.dart';

/// Modal for recording voice messages
class VoiceRecordingModal extends StatefulWidget {
  final void Function(String recordingPath)? onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceRecordingModal({
    super.key,
    this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceRecordingModal> createState() => _VoiceRecordingModalState();
}

class _VoiceRecordingModalState extends State<VoiceRecordingModal>
    with WidgetsBindingObserver {
  late VoiceRecordingService _voiceService;
  late AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  String? _recordedPath;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _audioPlayer = AudioPlayer();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _playbackPosition = position);
    });
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _playbackDuration = duration);
    });
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    });
    WidgetsBinding.instance.addObserver(this);
    _startRecording();
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_playerCompleteSubscription?.cancel());
    unawaited(_audioPlayer.dispose());

    WidgetsBinding.instance.removeObserver(this);
    if (_voiceService.state != VoiceRecordingState.stopped &&
        _voiceService.state != VoiceRecordingState.idle) {
      _voiceService.cancelRecording();
    }
    _voiceService.reset();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _voiceService.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final success = await _voiceService.startRecording();
    if (success) {
      setState(() => _isRecording = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start recording')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pauseOrResume() async {
    if (_isPaused) {
      await _voiceService.resumeRecording();
      setState(() => _isPaused = false);
    } else {
      await _voiceService.pauseRecording();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _stopForPreview() async {
    final recordingPath = await _voiceService.stopRecording();
    if (recordingPath != null && mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordedPath = recordingPath;
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        _playbackDuration = Duration.zero;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_recordedPath == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    final reachedEnd =
        _playbackDuration > Duration.zero && _playbackPosition >= _playbackDuration;
    if (reachedEnd || _playbackPosition == Duration.zero) {
      await _audioPlayer.play(DeviceFileSource(_recordedPath!));
      return;
    }

    await _audioPlayer.resume();
  }

  Future<void> _seekPlayback(double sliderValueMs) async {
    final newPosition = Duration(milliseconds: sliderValueMs.round());
    await _audioPlayer.seek(newPosition);
    if (mounted) {
      setState(() => _playbackPosition = newPosition);
    }
  }

  Future<void> _sendPreview() async {
    final path = _recordedPath;
    if (path == null) return;
    await _audioPlayer.stop();
    if (!mounted) return;
    widget.onRecordingComplete?.call(path);
    Navigator.of(context).pop(path);
  }

  Future<void> _cancel() async {
    await _audioPlayer.stop();
    await _voiceService.cancelRecording();
    widget.onCancel?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isMain = false,
  }) {
    final size = isMain ? 64.0 : 48.0;
    final iconSize = isMain ? 32.0 : 24.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            color: color.withValues(alpha: 0.05),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Modal Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Voice Message',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 24),

            // Waveform Visualizer
            if (_isRecording)
              Container(
                height: 60,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF687FE5).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF687FE5).withValues(alpha: 0.1)),
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    if (_voiceService.state == VoiceRecordingState.recording) ...[
                      ValueNotifier(_voiceService.recordingDuration),
                      ValueNotifier(_voiceService.amplitudes),
                    ] else ...[
                      ValueNotifier(Duration.zero),
                      ValueNotifier(<double>[]),
                    ]
                  ]),
                  builder: (context, child) {
                    return WaveformVisualizer(
                      amplitudes: _voiceService.amplitudes,
                      waveColor: const Color(0xFF687FE5),
                      height: 60,
                    );
                  },
                ),
              ),

            if (_isRecording) const SizedBox(height: 24),

            // Duration Display
            StreamBuilder(
              stream: Stream<int>.periodic(
                const Duration(milliseconds: 100),
                (tick) => tick,
              ),
              builder: (context, snapshot) {
                final shownDuration = _recordedPath == null
                    ? _voiceService.recordingDuration
                    : _playbackPosition;
                return Text(
                  _formatDuration(shownDuration),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF687FE5),
                    letterSpacing: 2,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            if (_recordedPath != null)
              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      thumbColor: const Color(0xFF687FE5),
                      activeTrackColor: const Color(0xFF687FE5).withValues(alpha: 0.8),
                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _playbackPosition.inMilliseconds.toDouble().clamp(
                        0,
                        (_playbackDuration.inMilliseconds > 0 ? _playbackDuration.inMilliseconds : 1).toDouble(),
                      ),
                      max: (_playbackDuration.inMilliseconds > 0 ? _playbackDuration.inMilliseconds : 1).toDouble(),
                      onChanged: _seekPlayback,
                    ),
                  ),
                  Text(
                    '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // Status Text
            Text(
              _recordedPath != null
                  ? (_isPlaying ? 'Playing preview...' : 'Preview ready')
                  : _isPaused
                      ? 'Recording paused'
                      : _isRecording
                          ? 'Recording in progress...'
                          : 'Ready to record',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 32),

            // Control Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel / Delete
                _buildIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  onTap: _cancel,
                ),

                const SizedBox(width: 32),

                // Play / Pause / Rec
                if (_isRecording)
                  _buildIconButton(
                    icon: _isPaused ? Icons.mic_none_rounded : Icons.pause_outlined,
                    color: Colors.orange.shade400,
                    onTap: _pauseOrResume,
                    isMain: true,
                  )
                else if (_recordedPath != null)
                  _buildIconButton(
                    icon: _isPlaying ? Icons.pause_outlined : Icons.play_arrow_outlined,
                    color: const Color(0xFF687FE5),
                    onTap: _togglePlayback,
                    isMain: true,
                  )
                else 
                  _buildIconButton(
                    icon: Icons.mic_none_rounded,
                    color: Colors.blueGrey.shade400,
                    onTap: () {},
                    isMain: true,
                  ),

                const SizedBox(width: 32),

                // Stop / Send
                _buildIconButton(
                  icon: _recordedPath == null ? Icons.stop_outlined : Icons.send_outlined,
                  color: _recordedPath == null ? Colors.orange.shade400 : const Color(0xFF34C759),
                  onTap: _recordedPath == null ? _stopForPreview : _sendPreview,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
