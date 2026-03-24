import 'dart:async';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../model/binding.dart';
import '../../compose_box.dart';
import '../../../../widgets/dialog.dart';
import '../../../../values/icons.dart';
import 'attach_upload_button.dart';

class AttachFromCameraButton extends AttachUploadsButton {
  const AttachFromCameraButton({
    super.key,
    required super.controller,
    required super.enabled,
  });

  @override
  IconData get icon => ZulipIcons.camera;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
      zulipLocalizations.composeBoxAttachFromCameraTooltip;

  @override
  Future<Iterable<FileToUpload>> getFiles(BuildContext context) async {
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
