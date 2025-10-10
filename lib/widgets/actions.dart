import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/exception.dart';
import '../api/model/model.dart';
import '../api/model/narrow.dart';
import '../api/route/messages.dart';
import '../api/route/messages.dart' as messages_api;
import '../api/route/channels.dart' as channels_api;
import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import '../model/internal_link.dart';
import '../model/narrow.dart';
import '../model/realm.dart';
import 'dialog.dart';
import 'store.dart';

/// Methods that act through the Zulip API and show feedback in the UI.
///
/// The static methods on this class can be thought of as higher-level wrappers
/// for some of the Zulip API endpoint binding methods in `lib/api/route/`.
/// But they don't belong in `lib/api/`, because they also interact with widgets
/// in order to present success or error feedback to the user through the UI.
abstract final class ZulipAction {
  /// Mark the given narrow as read,
  /// showing feedback to the user on progress or failure.
  ///
  /// This is mostly a wrapper around [updateMessageFlagsStartingFromAnchor];
  /// for details on the UI feedback, see there.
  static Future<void> markNarrowAsRead(BuildContext context, Narrow narrow) async {
    final zulipLocalizations = ZulipLocalizations.of(context);

    final didPass = await updateMessageFlagsStartingFromAnchor(
      context: context,
      // Include `is:unread` in the narrow.  That has a database index, so
      // this can be an important optimization in narrows with a lot of history.
      // The server applies the same optimization within the (deprecated)
      // specialized endpoints for marking messages as read; see
      // `do_mark_stream_messages_as_read` in `zulip:zerver/actions/message_flags.py`.
      apiNarrow: narrow.apiEncode()..add(ApiNarrowIs(IsOperand.unread)),
      // Use [AnchorCode.oldest], because [AnchorCode.firstUnread]
      // will be the oldest non-muted unread message, which would
      // result in muted unreads older than the first unread not
      // being processed.
      anchor: AnchorCode.oldest,
      // [AnchorCode.oldest] is an anchor ID lower than any valid
      // message ID.
      includeAnchor: false,
      op: UpdateMessageFlagsOp.add,
      flag: MessageFlag.read,
      onCompletedMessage: zulipLocalizations.markAsReadComplete,
      progressMessage: zulipLocalizations.markAsReadInProgress,
      onFailedTitle: zulipLocalizations.errorMarkAsReadFailedTitle);

    if (!didPass || !context.mounted) return;
    if (narrow is CombinedFeedNarrow) {
      PerAccountStoreWidget.of(context).unreads.handleAllMessagesReadSuccess();
    }
  }

  /// Mark the given narrow as unread from the given message onward,
  /// showing feedback to the user on progress or failure.
  ///
  /// This is a wrapper around [updateMessageFlagsStartingFromAnchor];
  /// for details on the UI feedback, see there.
  static Future<void> markNarrowAsUnreadFromMessage(
    BuildContext context,
    Message message,
    Narrow narrow,
  ) async {
    final zulipLocalizations = ZulipLocalizations.of(context);
    await updateMessageFlagsStartingFromAnchor(
      context: context,
      apiNarrow: narrow.apiEncode(),
      anchor: NumericAnchor(message.id),
      includeAnchor: true,
      op: UpdateMessageFlagsOp.remove,
      flag: MessageFlag.read,
      onCompletedMessage: zulipLocalizations.markAsUnreadComplete,
      progressMessage: zulipLocalizations.markAsUnreadInProgress,
      onFailedTitle: zulipLocalizations.errorMarkAsUnreadFailedTitle);
  }

  /// Add or remove the given flag from the anchor to the end of the narrow,
  /// showing feedback to the user on progress or failure.
  ///
  /// This has the semantics of [updateMessageFlagsForNarrow]
  /// (see https://zulip.com/api/update-message-flags-for-narrow)
  /// with `numBefore: 0` and infinite `numAfter`.  It operates by calling that
  /// endpoint with a finite `numAfter` as a batch size, in a loop.
  ///
  /// If the operation requires more than one batch, the user is shown progress
  /// feedback through [SnackBar], using [progressMessage] and [onCompletedMessage].
  /// If the operation fails, the user is shown an error dialog box with title
  /// [onFailedTitle].
  ///
  /// Returns true just if the operation finished successfully.
  static Future<bool> updateMessageFlagsStartingFromAnchor({
    required BuildContext context,
    required List<ApiNarrowElement> apiNarrow,
    required Anchor anchor,
    required bool includeAnchor,
    required UpdateMessageFlagsOp op,
    required MessageFlag flag,
    required String Function(int) onCompletedMessage,
    required String progressMessage,
    required String onFailedTitle,
  }) async {
    try {
      final store = PerAccountStoreWidget.of(context);
      final connection = store.connection;
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Compare web's `mark_all_as_read` in web/src/unread_ops.js
      // and zulip-mobile's `markAsUnreadFromMessage` in src/action-sheets/index.js .
      int responseCount = 0;
      int updatedCount = 0;
      while (true) {
        final result = await updateMessageFlagsForNarrow(connection,
          anchor: anchor,
          includeAnchor: includeAnchor,
          // There is an upper limit of 5000 messages per batch
          // (numBefore + numAfter <= 5000) enforced on the server.
          // See `update_message_flags_in_narrow` in zerver/views/message_flags.py .
          // zulip-mobile uses `numAfter` of 5000, but web uses 1000
          // for more responsive feedback. See zulip@f0d87fcf6.
          numBefore: 0,
          numAfter: 1000,
          narrow: apiNarrow,
          op: op,
          flag: flag);
        if (!context.mounted) {
          scaffoldMessenger.clearSnackBars();
          return false;
        }
        responseCount++;
        updatedCount += result.updatedCount;

        if (result.foundNewest) {
          if (responseCount > 1) {
            // We previously showed an in-progress [SnackBar], so say we're done.
            // There may be a backlog of [SnackBar]s accumulated in the queue
            // so be sure to clear them out here.
            scaffoldMessenger
              ..clearSnackBars()
              ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating,
                  content: Text(onCompletedMessage(updatedCount))));
          }
          return true;
        }

        if (result.lastProcessedId == null) {
          final zulipLocalizations = ZulipLocalizations.of(context);
          // No messages were in the range of the request.
          // This should be impossible given that `foundNewest` was false
          // (and that our `numAfter` was positive.)
          showErrorDialog(context: context,
            title: onFailedTitle,
            message: zulipLocalizations.errorInvalidResponse);
          return false;
        }
        anchor = NumericAnchor(result.lastProcessedId!);
        includeAnchor = false;

        // The task is taking a while, so tell the user we're working on it.
        // TODO: Ideally we'd have a progress widget here that showed up based
        //   on actual time elapsed -- so it could appear before the first
        //   batch returns, if that takes a while -- and that then stuck
        //   around continuously until the task ends. For now we use a
        //   series of [SnackBar]s, which may feel a bit janky.
        //   There is complexity in tracking the status of each [SnackBar],
        //   due to having no way to determine which is currently active,
        //   or if there is an active one at all.  Resetting the [SnackBar] here
        //   results in the same message popping in and out and the user experience
        //   is better for now if we allow them to run their timer through
        //   and clear the backlog later.
        scaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating,
          content: Text(progressMessage)));
      }
    } catch (e) {
      if (!context.mounted) return false;
      final zulipLocalizations = ZulipLocalizations.of(context);
      final message = switch (e) {
        ZulipApiException() => zulipLocalizations.errorServerMessage(e.message),
        _ => e.toString(), // TODO(#741): extract user-facing message better
      };
      showErrorDialog(context: context,
        title: onFailedTitle,
        message: message);
      return false;
    }
  }

  /// Fetch and return the raw Markdown content for [messageId],
  /// showing an error dialog on failure.
  static Future<String?> fetchRawContentWithFeedback({
    required BuildContext context,
    required int messageId,
    required String errorDialogTitle,
  }) async {
    Message? fetchedMessage;
    String? errorMessage;
    // TODO, supported by reusable code:
    // - (?) Retry with backoff on plausibly transient errors.
    // - If request(s) take(s) a long time, show snackbar with cancel
    //   button, like "Still working on quote-and-reply…".
    //   On final failure or success, auto-dismiss the snackbar.
    final zulipLocalizations = ZulipLocalizations.of(context);
    try {
      fetchedMessage = (await getMessage(PerAccountStoreWidget.of(context).connection,
        messageId: messageId,
        applyMarkdown: false,
        allowEmptyTopicName: true,
      )).message;
    } catch (e) {
      switch (e) {
        case ZulipApiException(code: 'BAD_REQUEST'):
          // Servers use this code when the message doesn't exist, according to
          // the example in the doc: https://zulip.com/api/get-message
          errorMessage = zulipLocalizations.errorMessageDoesNotSeemToExist;
        case ZulipApiException():
          errorMessage = e.message;
        // TODO specific messages for common errors, like network errors
        //   (support with reusable code)
        default:
          errorMessage = zulipLocalizations.errorCouldNotFetchMessageSource;
      }
    }

    if (!context.mounted) return null;

    if (fetchedMessage == null) {
      assert(errorMessage != null);
      // TODO(?) give no feedback on error conditions we expect to
      //   flag centrally in event polling, like invalid auth,
      //   user/realm deactivated. (Support with reusable code.)
      showErrorDialog(context: context,
        title: errorDialogTitle, message: errorMessage);
    }

    return fetchedMessage?.content;
  }

  /// Fetch and parse a URL from [messages_api.getFileTemporaryUrl];
  /// on failure, show an error dialog and return null.
  static Future<Uri?> getFileTemporaryUrl(BuildContext context, UserUploadLink link) async {
    final zulipLocalizations = ZulipLocalizations.of(context);

    String? resultUrl;
    try {
      final store = PerAccountStoreWidget.of(context);
      resultUrl = (await messages_api.getFileTemporaryUrl(store.connection,
        realmId: link.realmId, filename: link.path)).url;
    } catch (e) {
      if (!context.mounted) return null;
      final errorMessage = switch (e) {
        ZulipApiException() => e.message,
        // TODO specific messages for common errors, like network errors
        //   (support with reusable code)
        _ => null,
      };
      showErrorDialog(context: context,
        title: zulipLocalizations.errorCouldNotAccessUploadedFileTitle,
        message: errorMessage);
      return null;
    }
    if (!context.mounted) return null;

    final tempUrl = PerAccountStoreWidget.of(context).tryResolveUrl(resultUrl);
    if (tempUrl == null) {
      showErrorDialog(context: context,
        title: zulipLocalizations.errorCouldNotAccessUploadedFileTitle,
        message: zulipLocalizations.errorInvalidResponse);
      return null;
    }

    return tempUrl;
  }

  static Future<void> subscribeToChannel(BuildContext context, {
    required int channelId,
  }) async {
    final store = PerAccountStoreWidget.of(context);
    final channel = store.streams[channelId];
    if (channel == null || channel is Subscription) return; // TODO could give feedback

    try {
      await channels_api.subscribeToChannel(store.connection, subscriptions: [channel.name]);
    } catch (e) {
      if (!context.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      final title = ZulipLocalizations.of(context).subscribeFailedTitle;
      showErrorDialog(context: context, title: title, message: errorMessage);
    }
  }

  /// Unsubscribe from a channel, possibly after a confirmation dialog,
  /// showing an error dialog on failure.
  ///
  /// A confirmation dialog is shown if the user would not have permission
  /// to resubscribe.
  /// If [alwaysAsk] is true (the default),
  /// a confirmation dialog is shown unconditionally.
  static Future<void> unsubscribeFromChannel(BuildContext context, {
    required int channelId,
    bool alwaysAsk = true,
  }) async {
    final store = PerAccountStoreWidget.of(context);
    final subscription = store.subscriptions[channelId];
    if (subscription == null) return; // TODO could give feedback

    // TODO(future) check if the self-user is a guest and the channel is not web-public
    final couldResubscribe = !subscription.inviteOnly
      || store.selfHasPermissionForGroupSetting(subscription.canSubscribeGroup,
           GroupSettingType.stream, 'can_subscribe_group');
    final zulipLocalizations = ZulipLocalizations.of(context);
    if (!couldResubscribe) {
      // TODO(#1788) warn if org would lose content access (nobody can subscribe)

      final dialog = showSuggestedActionDialog(context: context,
        title: zulipLocalizations.unsubscribeConfirmationDialogTitle('#${subscription.name}'),
        message: zulipLocalizations.unsubscribeConfirmationDialogMessageCannotResubscribe,
        destructiveActionButton: true,
        actionButtonText: zulipLocalizations.unsubscribeConfirmationDialogConfirmButton);
      if (await dialog.result != true) return;
      if (!context.mounted) return;
    } else if (alwaysAsk) {
      final dialog = showSuggestedActionDialog(context: context,
        title: zulipLocalizations.unsubscribeConfirmationDialogTitle('#${subscription.name}'),
        actionButtonText: zulipLocalizations.unsubscribeConfirmationDialogConfirmButton);
      if (await dialog.result != true) return;
      if (!context.mounted) return;
    }

    try {
      await channels_api.unsubscribeFromChannel(PerAccountStoreWidget.of(context).connection,
        subscriptions: [subscription.name]);
    } catch (e) {
      if (!context.mounted) return;

      String? errorMessage;
      switch (e) {
        case ZulipApiException():
          errorMessage = e.message;
          // TODO(#741) specific messages for common errors, like network errors
          //   (support with reusable code)
        default:
      }

      final title = ZulipLocalizations.of(context).unsubscribeFailedTitle;
      showErrorDialog(context: context, title: title, message: errorMessage);
    }
  }
}

/// Methods that act through platform APIs and show feedback in the UI.
///
/// The static methods on this class can be thought of as higher-level wrappers
/// for some of the platform binding methods in [ZulipBinding].
/// But they don't belong there, because they also interact with widgets
/// in order to present success or error feedback to the user through the UI.
abstract final class PlatformActions {
  /// Copies [data] to the clipboard and shows a popup on success.
  ///
  /// Must have a [Scaffold] ancestor.
  ///
  /// On newer Android the popup is defined and shown by the platform. On older
  /// Android and on iOS, shows a [Snackbar] with [successContent].
  ///
  /// In English, the text in [successContent] should be short, should start with
  /// a capital letter, and should have no ending punctuation: "{noun} copied".
  static void copyWithPopup({
    required BuildContext context,
    required ClipboardData data,
    required Widget successContent,
  }) async {
    await Clipboard.setData(data);
    final deviceInfo = await ZulipBinding.instance.deviceInfo;

    if (!context.mounted) return;

    final shouldShowSnackbar = switch (deviceInfo) {
      // Android 13+ shows its own popup on copying to the clipboard,
      // so we suppress ours, following the advice at:
      //   https://developer.android.com/develop/ui/views/touch-and-input/copy-paste#duplicate-notifications
      // TODO(android-sdk-33): Simplify this and dartdoc
      AndroidDeviceInfo(:var sdkInt) => sdkInt <= 32,
      _                              => true,
    };
    if (shouldShowSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: successContent));
    }
  }

  /// Opens a URL with [ZulipBinding.launchUrl], with an error dialog on failure.
  static Future<void> launchUrl(BuildContext context, Uri url) async {
    final globalSettings = GlobalStoreWidget.settingsOf(context);

    bool launched = false;
    String? errorMessage;
    try {
      launched = await ZulipBinding.instance.launchUrl(url,
        mode: globalSettings.getUrlLaunchMode(url));
    } on PlatformException catch (e) {
      errorMessage = e.message;
    }
    if (!launched) { // TODO(log)
      if (!context.mounted) return;

      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(context: context,
        title: zulipLocalizations.errorCouldNotOpenLinkTitle,
        message: [
          zulipLocalizations.errorCouldNotOpenLink(url.toString()),
          if (errorMessage != null) errorMessage,
        ].join("\n\n"));
    }
  }
}
