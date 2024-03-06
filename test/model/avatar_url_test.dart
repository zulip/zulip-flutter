import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/avatar_url.dart';

void main() {
  const defaultSize = 30;
  const largeSize = 120;

  group('GravatarUrl', () {
    test('gravatar url', () {
      final url = '${GravatarUrl.origin}/avatar/1234';
      final avatarUrl = AvatarUrl.fromUserData(resolvedUrl: Uri.parse(url));

      check(avatarUrl.get(defaultSize).toString()).equals('$url?s=30');
    });
  });

  group('UploadedAvatarUrl', () {
    test('png image', () {
      const url = 'https://zulip.example/image.png';
      final avatarUrl = AvatarUrl.fromUserData(resolvedUrl: Uri.parse(url));

      check(avatarUrl.get(defaultSize).toString()).equals(url);
    });

    test('png image, larger size', () {
      const url = 'https://zulip.example/image.png';
      final avatarUrl = AvatarUrl.fromUserData(resolvedUrl: Uri.parse(url));
      final expectedUrl = url.replaceAll('.png', '-medium.png');

      check(avatarUrl.get(largeSize).toString()).equals(expectedUrl);
    });
  });
}
