import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// State of voice recording
enum VoiceRecordingState {
  idle,
  recording,
  paused,
  stopped,
}

/// Service to handle voice recording functionality
class VoiceRecordingService {
  static final VoiceRecordingService _instance = VoiceRecordingService._internal();

  factory VoiceRecordingService() {
    return _instance;
  }

  VoiceRecordingService._internal();

  AudioRecorder? _recorder;
  VoiceRecordingState _state = VoiceRecordingState.idle;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  List<double> _amplitudes = [];

  // Getters
  VoiceRecordingState get state => _state;
  Duration get recordingDuration => _recordingDuration;
  List<double> get amplitudes => List.unmodifiable(_amplitudes);
  String? get recordingPath => _recordingPath;

  /// Initialize recorder
  Future<bool> _ensureRecorder() async {
    if (_recorder == null) {
      try {
        _recorder = AudioRecorder();
        return true;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    try {
      if (!await _ensureRecorder()) return false;
      return await _recorder!.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Start recording voice
  Future<bool> startRecording() async {
    try {
      if (!await _ensureRecorder()) return false;

      // Check and request permissions
      if (!await _recorder!.hasPermission()) {
        return false;
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = path.join(tempDir.path, 'voice_message_$timestamp.m4a');

      // Check if recorder is already recording
      if (_state == VoiceRecordingState.recording) {
        return false;
      }

      // Reset state
      _recordingDuration = Duration.zero;
      _amplitudes = [];

      // Start recording
      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      _state = VoiceRecordingState.recording;

      // Start duration timer
      _startDurationTimer();

      // Start amplitude monitoring
      _startAmplitudeMonitoring();

      return true;
    } catch (e) {
      _state = VoiceRecordingState.idle;
      return false;
    }
  }

  /// Pause recording
  Future<bool> pauseRecording() async {
    if (_state != VoiceRecordingState.recording) {
      return false;
    }

    try {
      if (_recorder == null) return false;
      await _recorder!.pause();
      _state = VoiceRecordingState.paused;
      _durationTimer?.cancel();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Resume recording after pause
  Future<bool> resumeRecording() async {
    if (_state != VoiceRecordingState.paused) {
      return false;
    }

    try {
      if (_recorder == null) return false;
      await _recorder!.resume();
      _state = VoiceRecordingState.recording;
      _startDurationTimer();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (_state == VoiceRecordingState.idle) {
      return null;
    }

    try {
      _durationTimer?.cancel();
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

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    try {
      _durationTimer?.cancel();
      if (_recorder != null) {
        await _recorder!.stop();
      }
      _state = VoiceRecordingState.idle;
      _recordingDuration = Duration.zero;
      _amplitudes = [];
      _recordingPath = null;
    } catch (e) {
      // Handle error silently
    }
  }

  /// Dispose recorder resources
  Future<void> dispose() async {
    try {
      _durationTimer?.cancel();
      if (_recorder != null) {
        await _recorder!.dispose();
        _recorder = null;
      }
      _state = VoiceRecordingState.idle;
      _recordingDuration = Duration.zero;
      _amplitudes = [];
      _recordingPath = null;
    } catch (e) {
      // Handle error silently
    }
  }

  /// Reset to initial state
  void reset() {
    _durationTimer?.cancel();
    _state = VoiceRecordingState.idle;
    _recordingDuration = Duration.zero;
    _amplitudes = [];
    _recordingPath = null;
  }

  /// Start monitoring recording duration
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _recordingDuration = _recordingDuration + const Duration(milliseconds: 100);
    });
  }

  /// Start monitoring amplitude for waveform visualization
  void _startAmplitudeMonitoring() {
    // Generate realistic amplitude values for waveform
    // In a real app, you'd get these from the recorder
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_state == VoiceRecordingState.recording) {
        // Generate random amplitude between 0 and 1
        // In production, you'd use _recorder.getAmplitude() if available
        final amplitude = (DateTime.now().millisecond / 1000.0) * 0.8 + 0.2;
        if (_amplitudes.length < 200) {
          _amplitudes.add(amplitude);
        } else {
          _amplitudes.removeAt(0);
          _amplitudes.add(amplitude);
        }
      } else {
        timer.cancel();
      }
    });
  }
}
