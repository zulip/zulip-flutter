import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/avatar_url.dart';

void main() {
  const defaultSize = 30;
  const largeSize = 120;

  const userId = 123;
  final realmUrl = Uri.parse('https://zulip.example/');

  AvatarUrl fromUserData(Uri? resolvedUrl) => AvatarUrl.fromUserData(
    resolvedUrl: resolvedUrl, userId: userId, realmUrl: realmUrl);

  group('GravatarUrl', () {
    test('gravatar url', () {
      final url = '${GravatarUrl.origin}/avatar/1234';
      final avatarUrl = fromUserData(Uri.parse(url));

      check(avatarUrl.get(defaultSize).toString()).equals('$url?s=30');
    });
  });

  group('FallbackAvatarUrl', () {
    test('standard size', () {
      final avatarUrl = fromUserData(null);

      check(avatarUrl.get(defaultSize).toString())
        .equals('https://zulip.example/avatar/$userId');
    });

    test('larger size', () {
      final avatarUrl = fromUserData(null);

      check(avatarUrl.get(largeSize).toString())
        .equals('https://zulip.example/avatar/$userId/medium');
    });
  });

  group('UploadedAvatarUrl', () {
    test('png image', () {
      const url = 'https://zulip.example/image.png';
      final avatarUrl = fromUserData(Uri.parse(url));

      check(avatarUrl.get(defaultSize).toString()).equals(url);
    });

    test('png image, larger size', () {
      const url = 'https://zulip.example/image.png';
      final avatarUrl = fromUserData(Uri.parse(url));
      final expectedUrl = url.replaceAll('.png', '-medium.png');

      check(avatarUrl.get(largeSize).toString()).equals(expectedUrl);
    });
  });
}
