import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum VoiceRecordingState {
  idle,
  recording,
  paused,
  stopped,
}

class VoiceRecordingService {
  AudioRecorder? _recorder;
  VoiceRecordingState _state = VoiceRecordingState.idle;

  VoiceRecordingService({AudioRecorder? recorder}) : _recorder = recorder;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  List<double> _amplitudes = [];

  VoiceRecordingState get state => _state;
  Duration get recordingDuration => _recordingDuration;
  List<double> get amplitudes => List.unmodifiable(_amplitudes);
  String? get recordingPath => _recordingPath;

  Future<bool> hasPermission() async {
    try {
      _recorder ??= AudioRecorder();
      return await _recorder!.hasPermission();
    } catch (e) {
      return false;
    }
  }

  Future<bool> startRecording() async {
    try {
      _recorder ??= AudioRecorder();

      if (!await _recorder!.hasPermission()) {
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = path.join(tempDir.path, 'voice_message_$timestamp.m4a');

      if (_state == VoiceRecordingState.recording) {
        return false;
      }

      _recordingDuration = Duration.zero;
      _amplitudes = [];

      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      _state = VoiceRecordingState.recording;
      _startTimers();

      return true;
    } catch (e) {
      _state = VoiceRecordingState.idle;
      return false;
    }
  }

  Future<bool> pauseRecording() async {
    if (_state != VoiceRecordingState.recording) {
      return false;
    }

    try {
      if (_recorder == null) return false;
      await _recorder!.pause();
      _state = VoiceRecordingState.paused;
      _stopTimers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resumeRecording() async {
    if (_state != VoiceRecordingState.paused) {
      return false;
    }

    try {
      if (_recorder == null) return false;
      await _recorder!.resume();
      _state = VoiceRecordingState.recording;
      _startTimers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (_state == VoiceRecordingState.idle) {
      return null;
    }

    try {
      _stopTimers();
      if (_recorder == null) return null;
      final path = await _recorder!.stop();
      _state = VoiceRecordingState.stopped;
      _recordingPath = path;
      return path;
    } catch (e) {
      _state = VoiceRecordingState.idle;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      _stopTimers();
      if (_recorder != null) {
        await _recorder!.stop();
      }
      _resetState();
    } catch (e) {
      // debugPrint('Error canceling recording: $e');
    }
  }

  Future<void> dispose() async {
    try {
      _stopTimers();
      if (_recorder != null) {
        await _recorder!.dispose();
        _recorder = null;
      }
      _resetState();
    } catch (e) {
      // debugPrint('Error disposing recorder: $e');
    }
  }

  void reset() {
    _stopTimers();
    _resetState();
  }

  void _resetState() {
    _state = VoiceRecordingState.idle;
    _recordingDuration = Duration.zero;
    _amplitudes = [];
    _recordingPath = null;
  }

  void _startTimers() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _recordingDuration += const Duration(milliseconds: 100);
    });

    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (_state == VoiceRecordingState.recording && _recorder != null) {
        final amplitude = await _recorder!.getAmplitude();
        final current = amplitude.current;
        // Normalize roughly to 0-1 range for UI usage, typical range is -160 to 0 dB
        final normalized = ((current + 160) / 160).clamp(0.0, 1.0);
        
        if (_amplitudes.length >= 200) {
          _amplitudes.removeAt(0);
        }
        _amplitudes.add(normalized);
      }
    });
  }

  void _stopTimers() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
  }
}

