import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:zulip/model/voice_recorder.dart';

import '../fake_async.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceRecordingService', () {
    late VoiceRecordingService service;
    late FakeAudioRecorder fakeRecorder;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (methodCall) async {
          if (methodCall.method == 'getTemporaryDirectory') {
            return 'temp/dir';
          }
          return null;
        },
      );

      fakeRecorder = FakeAudioRecorder();
      service = VoiceRecordingService(recorder: fakeRecorder);
    });

    tearDown(() {
      service.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    test('initial state is idle', () {
      check(service.state).equals(VoiceRecordingState.idle);
      check(service.recordingDuration).equals(Duration.zero);
      check(service.amplitudes).isEmpty();
      check(service.recordingPath).isNull();
    });

    test('startRecording succeeds when permission granted', () async {
      fakeRecorder.permission = true;

      final result = await service.startRecording();
      check(result).isTrue();
      check(service.state).equals(VoiceRecordingState.recording);
      check(service.recordingPath).isNotNull().endsWith('.m4a');
      check(fakeRecorder.recordingState).isTrue();
    });

    test('startRecording fails when permission denied', () async {
      fakeRecorder.permission = false;

      final result = await service.startRecording();
      check(result).isFalse();
      check(service.state).equals(VoiceRecordingState.idle);
      check(fakeRecorder.recordingState).isFalse();
    });

    test('pauseRecording pauses recorder', () async {
      fakeRecorder.permission = true;
      await service.startRecording();
      
      final result = await service.pauseRecording();
      check(result).isTrue();
      check(service.state).equals(VoiceRecordingState.paused);
      check(fakeRecorder.pausedState).isTrue();
    });

    test('resumeRecording resumes recorder', () async {
      fakeRecorder.permission = true;
      await service.startRecording();
      await service.pauseRecording();

      final result = await service.resumeRecording();
      check(result).isTrue();
      check(service.state).equals(VoiceRecordingState.recording);
      check(fakeRecorder.pausedState).isFalse();
      check(fakeRecorder.recordingState).isTrue();
    });

    test('stopRecording returns path and resets state', () async {
      fakeRecorder.permission = true;
      await service.startRecording();

      final path = await service.stopRecording();
      check(path).isNotNull();
      check(service.state).equals(VoiceRecordingState.stopped);
      check(fakeRecorder.recordingState).isFalse();
    });

    test('duration updates during recording', () => awaitFakeAsync((async) async {
      fakeRecorder.permission = true;
      await service.startRecording();

      async.elapse(const Duration(milliseconds: 500));
      check(service.recordingDuration).isGreaterThan(Duration.zero);
      await service.dispose();
    }));

    test('amplitudes update during recording', () => awaitFakeAsync((async) async {
      fakeRecorder.permission = true;
      await service.startRecording();

      async.elapse(const Duration(milliseconds: 200));
      check(service.amplitudes).isNotEmpty();
      await service.dispose();
    }));
  });
}

class FakeAudioRecorder extends Fake implements AudioRecorder {
  bool _permission = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String? currentPath;

  set permission(bool value) => _permission = value;
  
  bool get recordingState => _isRecording;
  bool get pausedState => _isPaused;

  @override
  Future<bool> hasPermission({bool request = false}) async => _permission;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    if (!_permission) throw Exception('No permission');
    _isRecording = true;
    currentPath = path;
  }

  @override
  Future<void> pause() async {
    _isPaused = true;
  }

  @override
  Future<void> resume() async {
    _isPaused = false;
  }

  @override
  Future<String?> stop() async {
    _isRecording = false;
    _isPaused = false;
    return currentPath;
  }

  @override
  Future<void> cancel() async {
    _isRecording = false;
    _isPaused = false;
  }

  @override
  Future<void> dispose() async {
    _isRecording = false;
  }

  @override
  Future<Amplitude> getAmplitude() async {
    return Amplitude(current: -10.0, max: 0.0);
  }

  @override
  Future<bool> isRecording() async => _isRecording;

  @override
  Future<bool> isPaused() async => _isPaused;
}
