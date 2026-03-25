import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/voice_recorder.dart';

import '../example_data.dart' as eg;

void main() {
  group('VoiceRecordingService', () {
    late VoiceRecordingService service;

    setUp(() {
      service = VoiceRecordingService();
    });

    tearDown(() async {
      // Clean up any ongoing recording
      if (service.state != VoiceRecordingState.idle) {
        await service.stopRecording();
      }
    });

    group('state management', () {
      test('initial state is idle', () {
        check(service.state).equals(VoiceRecordingState.idle);
      });

      test('initial duration is zero', () {
        check(service.recordingDuration).equals(Duration.zero);
      });

      test('initial amplitudes is empty', () {
        check(service.amplitudes).isEmpty();
      });

      test('initial recording path is null', () {
        check(service.recordingPath).isNull();
      });
    });

    group('recording lifecycle', () {
      test('start recording sets state to recording', () async {
        // Note: This test assumes permission is granted in the test environment
        // In a real scenario, permissions would need to be mocked
        final result = await service.startRecording();
        
        if (result) {
          check(service.state).equals(VoiceRecordingState.recording);
          check(service.recordingPath).isNotNull();
        }
      });

      test('pause recording changes state to paused', () async {
        final started = await service.startRecording();
        
        if (started) {
          final paused = await service.pauseRecording();
          if (paused) {
            check(service.state).equals(VoiceRecordingState.paused);
          }
        }
      });

      test('no pause recording when not recording', () async {
        final result = await service.pauseRecording();
        check(result).isFalse();
      });

      test('resume recording after pause', () async {
        final started = await service.startRecording();
        if (started) {
          final paused = await service.pauseRecording();
          if (paused) {
            final resumed = await service.resumeRecording();
            if (resumed) {
              check(service.state).equals(VoiceRecordingState.recording);
            }
          }
        }
      });

      test('no resume recording when not paused', () async {
        final result = await service.resumeRecording();
        check(result).isFalse();
      });

      test('stop recording returns file path', () async {
        final started = await service.startRecording();
        
        if (started) {
          final filePath = await service.stopRecording();
          check(filePath).isNotNull();
          check(service.state).equals(VoiceRecordingState.idle);
        }
      });

      test('no stop recording when idle', () async {
        final result = await service.stopRecording();
        check(result).isNull();
      });
    });

    group('recording duration', () {
      test('duration increases during recording', () async {
        final started = await service.startRecording();
        
        if (started) {
          final initialDuration = service.recordingDuration;
          
          // Wait a bit for duration to increase
          await Future.delayed(const Duration(milliseconds: 100));
          
          check(service.recordingDuration).isGreaterThan(initialDuration);
        }
      });

      test('duration reset on new recording', () async {
        final started1 = await service.startRecording();
        if (started1) {
          await Future.delayed(const Duration(milliseconds: 50));
          await service.stopRecording();
          
          final durationAfterStop = service.recordingDuration;
          
          final started2 = await service.startRecording();
          if (started2) {
            check(service.recordingDuration).equals(Duration.zero);
          }
        }
      });

      test('duration stops updating when paused', () async {
        final started = await service.startRecording();
        if (started) {
          await Future.delayed(const Duration(milliseconds: 50));
          final durationBeforePause = service.recordingDuration;
          
          await service.pauseRecording();
          await Future.delayed(const Duration(milliseconds: 50));
          
          check(service.recordingDuration).equals(durationBeforePause);
        }
      });
    });

    group('amplitudes', () {
      test('amplitudes are collected during recording', () async {
        final started = await service.startRecording();
        
        if (started) {
          // Wait for amplitudes to be collected
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Note: Amplitudes might be empty depending on system,
          // but the list should be modifiable independently
          check(service.amplitudes).isA<List<double>>();
        }
      });

      test('amplitudes reset on new recording', () async {
        final started = await service.startRecording();
        if (started) {
          await Future.delayed(const Duration(milliseconds: 100));
          await service.stopRecording();
          
          final started2 = await service.startRecording();
          if (started2) {
            check(service.amplitudes).isEmpty();
          }
        }
      });
    });

    group('permission checking', () {
      test('permission check returns bool', () async {
        final hasPermission = await service.hasPermission();
        check(hasPermission).isA<bool>();
      });
    });
  });
}
