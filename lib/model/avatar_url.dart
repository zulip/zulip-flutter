/// The size threshold above which is "medium" size for an avatar.
///
/// This is DEFAULT_AVATAR_SIZE in zerver/lib/upload.py.
const defaultUploadSizePx = 100;

abstract class AvatarUrl {
  factory AvatarUrl.fromUserData({required Uri resolvedUrl}) {
    // TODO(#255): handle computing gravatars
    // TODO(#254): handle computing fallback avatar
    if (resolvedUrl.toString().startsWith(GravatarUrl.origin)) {
      return GravatarUrl(resolvedUrl: resolvedUrl);
    } else {
      return UploadedAvatarUrl(resolvedUrl: resolvedUrl);
    }
  }

  Uri get(int sizePhysicalPx);
}

class GravatarUrl implements AvatarUrl {
  GravatarUrl({required Uri resolvedUrl}) : standardUrl = resolvedUrl;

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
