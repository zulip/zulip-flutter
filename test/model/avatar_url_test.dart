import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:crypto/crypto.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/json.dart';
import 'package:zulip/model/avatar_url.dart';

void main() {
  const defaultSize = 30;
  const largeSize = 120;

  const userId = 123;
  const email = 'user123@zulip.example';
  final realmUrl = Uri.parse('https://zulip.example/');

  AvatarUrl fromUserData({
    JsonNullable<String>? avatarUrl,
    Uri? resolvedUrl,
    String email = email,
  }) => AvatarUrl.fromUserData(
    avatarUrl: avatarUrl,
    resolvedUrl: resolvedUrl,
    email: email,
    userId: userId,
    realmUrl: realmUrl,
  );

  group('GravatarUrl', () {
    test('server-provided gravatar url', () {
      final url = '${GravatarUrl.origin}/avatar/1234';
      final avatarUrl = fromUserData(
        avatarUrl: JsonNullable(url),
        resolvedUrl: Uri.parse(url),
      );

      check(avatarUrl.get(defaultSize).toString()).equals('$url?s=30');
    });

    test('computed from email when avatar_url is null', () {
      final hash = md5.convert(utf8.encode(email.toLowerCase())).toString();
      final avatarUrl = fromUserData(avatarUrl: const JsonNullable(null));

      check(avatarUrl).isA<GravatarUrl>();
      check(avatarUrl.get(defaultSize).toString())
        .equals('${GravatarUrl.origin}/avatar/$hash?d=identicon&s=30');
    });
  });

  group('FallbackAvatarUrl', () {
    test('standard size when avatar_url omitted', () {
      final avatarUrl = fromUserData();

      check(avatarUrl.get(defaultSize).toString())
        .equals('https://zulip.example/avatar/$userId');
    });

    test('larger size when avatar_url omitted', () {
      final avatarUrl = fromUserData();

      check(avatarUrl.get(largeSize).toString())
        .equals('https://zulip.example/avatar/$userId/medium');
    });
  });

  group('UploadedAvatarUrl', () {
    test('png image', () {
      const url = 'https://zulip.example/image.png';
      final avatarUrl = fromUserData(
        avatarUrl: const JsonNullable(url),
        resolvedUrl: Uri.parse(url),
      );

      check(avatarUrl.get(defaultSize).toString()).equals(url);
    });

    test('png image, larger size', () {
      const url = 'https://zulip.example/image.png';
      final avatarUrl = fromUserData(
        avatarUrl: const JsonNullable(url),
        resolvedUrl: Uri.parse(url),
      );
      final expectedUrl = url.replaceAll('.png', '-medium.png');

      check(avatarUrl.get(largeSize).toString()).equals(expectedUrl);
    });
  });
}
