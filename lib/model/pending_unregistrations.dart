import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../api/core.dart';
import '../api/exception.dart';
import '../api/route/account.dart';
import '../log.dart';
import '../notifications/receive.dart';

class PendingUnregistration {
  final Uri realmUrl;
  final int zulipFeatureLevel;
  final String email;
  final String apiKey;
  final int? deviceId;
  final String? token;
  // If true, attempt to unregister legacy push token.
  final bool possibleLegacyPushToken;

  PendingUnregistration({
    required this.realmUrl,
    required this.zulipFeatureLevel,
    required this.email,
    required this.apiKey,
    this.deviceId,
    this.token,
    required this.possibleLegacyPushToken,
  });

  Map<String, dynamic> toJson() => {
    'realmUrl': realmUrl.toString(),
    'zulipFeatureLevel': zulipFeatureLevel,
    'email': email,
    'apiKey': apiKey,
    'deviceId': deviceId,
    'token': token,
    'possibleLegacyPushToken': possibleLegacyPushToken,
  };

  factory PendingUnregistration.fromJson(Map<String, dynamic> json) =>
    PendingUnregistration(
      realmUrl: Uri.parse(json['realmUrl'] as String),
      zulipFeatureLevel: json['zulipFeatureLevel'] as int,
      email: json['email'] as String,
      apiKey: json['apiKey'] as String,
      deviceId: json['deviceId'] as int?,
      token: json['token'] as String?,
      possibleLegacyPushToken: json['possibleLegacyPushToken'] as bool? ?? false,
    );
}

class PendingUnregistrationsStore {
  static const _filename = 'pending_unregistrations.json';

  static Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _filename));
  }

  static Future<List<PendingUnregistration>> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.map((e) => PendingUnregistration.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      assert(debugLog("Failed to load pending unregistrations: $e"));
      return [];
    }
  }

  static Future<void> _save(List<PendingUnregistration> items) async {
    try {
      final file = await _file;
      final content = jsonEncode(items.map((e) => e.toJson()).toList());
      await file.writeAsString(content);
    } catch (e) {
      assert(debugLog("Failed to save pending unregistrations: $e"));
    }
  }

  static Future<void> add(PendingUnregistration request) async {
    final items = await _load();
    items.add(request);
    await _save(items);
  }

  static Future<void> flushAll() async {
    final items = await _load();
    if (items.isEmpty) return;

    final remaining = <PendingUnregistration>[];

    for (final request in items) {
      bool success = false;
      try {
        final connection = ApiConnection.live(
          realmUrl: request.realmUrl,
          zulipFeatureLevel: request.zulipFeatureLevel,
          email: request.email,
          apiKey: request.apiKey,
        );

        try {
          if (request.possibleLegacyPushToken && request.token != null) {
            await NotificationService.unregisterToken(connection, token: request.token!);
          }
          if (request.deviceId != null && request.zulipFeatureLevel >= 470) {
            await removeClientDevice(connection, deviceId: request.deviceId!);
          }
          success = true; // both succeeded
        } finally {
          connection.close();
        }
      } catch (e) {
        if (e is http.ClientException || e is SocketException || e is NetworkException) {
          assert(debugLog("Offline flush failed for ${request.email}: $e"));
        } else {
          // Possibly an Api request exception like "Invalid API Key" if the
          // account has since been deactivated on the server.
          // Don't retry these forever; drop the request.
          success = true; 
        }
      }

      if (!success) {
        remaining.add(request);
      }
    }

    if (remaining.length != items.length) {
      await _save(remaining);
    }
  }
}
