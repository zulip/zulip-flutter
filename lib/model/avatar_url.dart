import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The size threshold above which is "medium" size for an avatar.
///
/// This is in physical pixels, i.e. image pixels:
/// the server serves the default avatar size as a 100x100 px image,
/// so a display size above that in physical pixels
/// calls for the "medium" 500x500 px variant.
///
/// This is DEFAULT_AVATAR_SIZE in zerver/lib/thumbnail.py.
const defaultUploadSizePx = 100;

abstract class AvatarUrl {
  /// The right [AvatarUrl] subclass for the given user data.
  ///
  /// [resolvedUrl] is the user's `avatar_url` resolved against the realm URL,
  /// or null if the server omitted the field; see `user_avatar_url_field_optional`
  /// at https://zulip.com/api/register-queue#parameter-client_capabilities .
  ///
  /// For a user whose `avatar_url` is null,
  /// meaning a Gravatar to be computed by the client,
  /// use [GravatarUrl.fromEmail] instead.
  factory AvatarUrl.fromUserData({
    required Uri? resolvedUrl,
    required int userId,
    required Uri realmUrl,
  }) {
    if (resolvedUrl == null) {
      return FallbackAvatarUrl(realmUrl: realmUrl, userId: userId);
    } else if (resolvedUrl.toString().startsWith(GravatarUrl.origin)) {
      return GravatarUrl(resolvedUrl: resolvedUrl);
    } else {
      return UploadedAvatarUrl(resolvedUrl: resolvedUrl);
    }
  }

  Uri get(int sizePhysicalPx);
}

class GravatarUrl implements AvatarUrl {
  GravatarUrl({required Uri resolvedUrl}) : standardUrl = resolvedUrl;

  /// The Gravatar URL for the given email address.
  ///
  /// This is for a user whose `avatar_url` the server sent as null,
  /// as it does when we pass true for `client_gravatar`:
  ///   https://zulip.com/api/register-queue#parameter-client_gravatar
  ///
  /// See `GravatarURL.fromEmail` in zulip-mobile's src/utils/avatar.js.
  factory GravatarUrl.fromEmail(String email) {
    final hash = md5.convert(utf8.encode(email.toLowerCase()));
    return GravatarUrl(
      resolvedUrl: Uri.parse('$origin/avatar/$hash?d=identicon'));
  }

  static String origin = 'https://secure.gravatar.com';

  Uri standardUrl;

  @override
  Uri get(int sizePhysicalPx) {
    return standardUrl.replace(queryParameters: {
      ...standardUrl.queryParameters,
      's': sizePhysicalPx.toString(),
    });
  }
}

/// The fallback avatar URL, `/avatar/{user_id}` on the realm,
/// for a user whose `avatar_url` field the server omitted.
///
/// The server may omit the field at its discretion
/// when we pass true for `user_avatar_url_field_optional`
/// in the register request:
///   https://zulip.com/api/register-queue#parameter-client_capabilities
/// The fallback endpoint redirects to the user's actual avatar.
/// Its API documentation is pending, in an unmerged PR
/// (as of 2026-07-10):
///   https://github.com/zulip/zulip/pull/32495
///
/// Requests to this endpoint require auth,
/// but the redirect may point off-realm (to Gravatar, or S3-style storage),
/// where auth headers must not be sent.
/// Happily `dart:io`'s HttpClient handles that correctly:
/// it drops sensitive headers, like Authorization,
/// on cross-origin redirects.
class FallbackAvatarUrl implements AvatarUrl {
  FallbackAvatarUrl({required Uri realmUrl, required int userId})
    : standardUrl = realmUrl.resolve('/avatar/$userId');

  final Uri standardUrl;

  @override
  Uri get(int sizePhysicalPx) {
    if (sizePhysicalPx > defaultUploadSizePx) {
      return standardUrl.replace(path: '${standardUrl.path}/medium');
    }

    return standardUrl;
  }
}

class UploadedAvatarUrl implements AvatarUrl {
  UploadedAvatarUrl({required Uri resolvedUrl}) : standardUrl = resolvedUrl;

  Uri standardUrl;

  @override
  Uri get(int sizePhysicalPx) {
    if (sizePhysicalPx > defaultUploadSizePx) {
      return standardUrl.replace(
        path: standardUrl.path.replaceFirst(RegExp(r'(?:\.png)?$'), "-medium.png"));
    }

    return standardUrl;
  }
}
