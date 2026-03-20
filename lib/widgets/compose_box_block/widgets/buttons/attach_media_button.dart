import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/binding.dart';
import '../../../compose_box.dart';
import '../../../dialog.dart';
import '../../../icons.dart';
import 'attach_upload_button.dart';

class AttachMediaButton extends AttachUploadsButton {
  const AttachMediaButton({
    super.key,
    required super.controller,
    required super.enabled,
  });

  @override
  IconData get icon => ZulipIcons.image;

  @override
  String tooltip(ZulipLocalizations zulipLocalizations) =>
      zulipLocalizations.composeBoxAttachMediaTooltip;

  // TODO: Вынести в сервис
  Future<Iterable<FileToUpload>> _getFilePickerFiles(
    BuildContext context,
    FileType type,
  ) async {
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

  @override
  Future<Iterable<FileToUpload>> getFiles(BuildContext context) async {
    // TODO(#114): This doesn't give quite the right UI on Android.
    return _getFilePickerFiles(context, FileType.media);
  }
}
