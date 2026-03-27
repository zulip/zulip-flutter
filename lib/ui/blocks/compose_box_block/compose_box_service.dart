import 'dart:async';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/binding.dart';
import '../../widgets/dialog.dart';
import 'compose_box.dart';

class ComposeBoxService {
  static Future<Iterable<FileToUpload>> pickFiles(
    BuildContext context, {
    FileType type = FileType.any,
  }) async {
    FilePickerResult? result;
    try {
      result = await ZulipBinding.instance.pickFiles(
        allowMultiple: true,
        withReadStream: true,
        type: type,
      );
    } catch (e) {
      if (!context.mounted) return [];
      final zulipLocalizations = ZulipLocalizations.of(context);
      if (e is PlatformException && e.code == 'read_external_storage_denied') {
        // Observed on Android. If Android's error message tells us whether the
        // user has checked "Don't ask again", it seems the library doesn't pass
        // that on to us. So just always prompt to check permissions in settings.
        // If the user hasn't checked "Don't ask again", they can always dismiss
        // our prompt and retry, and the permissions request will reappear,
        // letting them grant permissions and complete the upload.
        final dialog = showSuggestedActionDialog(
          context: context,
          title: zulipLocalizations.permissionsNeededTitle,
          message: zulipLocalizations.permissionsDeniedReadExternalStorage,
          actionButtonText: zulipLocalizations.permissionsNeededOpenSettings,
        );
        if (await dialog.result == true) {
          unawaited(AppSettings.openAppSettings());
        }
      } else {
        showErrorDialog(
          context: context,
          title: zulipLocalizations.errorDialogTitle,
          message: e.toString(),
        );
      }
      return [];
    }
    if (result == null) {
      return []; // User cancelled; do nothing
    }

    return result.files.map((f) {
      assert(
        f.readStream != null,
      ); // We passed `withReadStream: true` to pickFiles.
      final mimeType = lookupMimeType(
        // Seems like the path shouldn't be required; we still want to look for
        // matches on `headerBytes`. Thankfully we can still do that, by calling
        // lookupMimeType with the empty string as the path. That's a value that
        // doesn't map to any particular type, so the path will be effectively
        // ignored, as desired. Upstream comment:
        //   https://github.com/dart-lang/mime/issues/11#issuecomment-2246824452
        f.path ?? '',
        headerBytes: f.bytes?.take(defaultMagicNumbersMaxLength).toList(),
      );
      return FileToUpload(
        content: f.readStream!,
        length: f.size,
        filename: f.name,
        mimeType: mimeType,
      );
    });
  }

static Future<Iterable<FileToUpload>> pickMedia(
    BuildContext context, {
    FileType type = FileType.media,
  }) async {
    FilePickerResult? result;
    try {
      result = await ZulipBinding.instance.pickFiles(
        allowMultiple: true,
        withReadStream: true,
        type: type,
      );
    } catch (e) {
      if (!context.mounted) return [];
      final zulipLocalizations = ZulipLocalizations.of(context);
      if (e is PlatformException && e.code == 'read_external_storage_denied') {
        // Observed on Android. If Android's error message tells us whether the
        // user has checked "Don't ask again", it seems the library doesn't pass
        // that on to us. So just always prompt to check permissions in settings.
        // If the user hasn't checked "Don't ask again", they can always dismiss
        // our prompt and retry, and the permissions request will reappear,
        // letting them grant permissions and complete the upload.
        final dialog = showSuggestedActionDialog(
          context: context,
          title: zulipLocalizations.permissionsNeededTitle,
          message: zulipLocalizations.permissionsDeniedReadExternalStorage,
          actionButtonText: zulipLocalizations.permissionsNeededOpenSettings,
        );
        if (await dialog.result == true) {
          unawaited(AppSettings.openAppSettings());
        }
      } else {
        showErrorDialog(
          context: context,
          title: zulipLocalizations.errorDialogTitle,
          message: e.toString(),
        );
      }
      return [];
    }
    if (result == null) {
      return []; // User cancelled; do nothing
    }

    return result.files.map((f) {
      assert(
        f.readStream != null,
      ); // We passed `withReadStream: true` to pickFiles.
      final mimeType = lookupMimeType(
        // Seems like the path shouldn't be required; we still want to look for
        // matches on `headerBytes`. Thankfully we can still do that, by calling
        // lookupMimeType with the empty string as the path. That's a value that
        // doesn't map to any particular type, so the path will be effectively
        // ignored, as desired. Upstream comment:
        //   https://github.com/dart-lang/mime/issues/11#issuecomment-2246824452
        f.path ?? '',
        headerBytes: f.bytes?.take(defaultMagicNumbersMaxLength).toList(),
      );
      return FileToUpload(
        content: f.readStream!,
        length: f.size,
        filename: f.name,
        mimeType: mimeType,
      );
    });
  }


  static Future<Iterable<FileToUpload>> openCamera(BuildContext context) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final XFile? result;
    try {
      // Ideally we'd open a platform interface that lets you choose between
      // taking a photo and a video. `image_picker` doesn't yet have that
      // option: https://github.com/flutter/flutter/issues/89159
      // so just stick with images for now. We could add another button for
      // videos, but we don't want too many buttons.
      result = await ZulipBinding.instance.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );
    } catch (e) {
      if (!context.mounted) return [];
      if (e is PlatformException && e.code == 'camera_access_denied') {
        // iOS has a quirk where it will only request the native
        // permission-request alert once, the first time the app wants to
        // use a protected resource. After that, the only way the user can
        // grant it is in Settings.
        final dialog = showSuggestedActionDialog(
          context: context,
          title: zulipLocalizations.permissionsNeededTitle,
          message: zulipLocalizations.permissionsDeniedCameraAccess,
          actionButtonText: zulipLocalizations.permissionsNeededOpenSettings,
        );
        if (await dialog.result == true) {
          unawaited(AppSettings.openAppSettings());
        }
      } else {
        showErrorDialog(
          context: context,
          title: zulipLocalizations.errorDialogTitle,
          message: e.toString(),
        );
      }
      return [];
    }
    if (result == null) {
      return []; // User cancelled; do nothing
    }
    final length = await result.length();

    List<int>? headerBytes;
    try {
      headerBytes = await result
          .openRead(
            0,
            // Despite its dartdoc, [XFile.openRead] can throw if `end` is greater
            // than the file's length. We can *probably* trust our `length` to be
            // accurate, but it's nontrivial to verify. If it's inaccurate, we'd
            // rather sacrifice this part of the MIME lookup than throw the whole
            // upload. So, the try/catch.
            min(defaultMagicNumbersMaxLength, length),
          )
          .expand((l) => l)
          .toList();
    } catch (e) {
      // TODO(log)
    }
    return [
      FileToUpload(
        content: result.openRead(),
        length: length,
        filename: result.name,
        mimeType:
            result.mimeType ??
            lookupMimeType(result.path, headerBytes: headerBytes),
      ),
    ];
  }
}
