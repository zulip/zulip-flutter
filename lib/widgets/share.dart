import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mime/mime.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../host/android_intents.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/narrow.dart';
import 'app.dart';
import 'color.dart';
import 'compose_box.dart';
import 'dialog.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'subscription_list.dart';
import 'theme.dart';

// Responds to receiving shared content from other apps.
class ShareService {
  const ShareService._();

  static Future<void> start() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        ZulipBinding.instance.androidIntentEvents.listen((event) {
          switch (event) {
            case AndroidIntentSendEvent():
              _handleSend(event);
          }
        });

      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        // Do nothing; we don't support receiving shared content from
        // other apps on these platforms.
        break;
    }
  }

  static Future<void> _handleSend(AndroidIntentSendEvent intentSendEvent) async {
    assert(defaultTargetPlatform == TargetPlatform.android);

    assert(debugLog('intentSendEvent.action: ${intentSendEvent.action}'));
    assert(debugLog('intentSendEvent.extraText: ${intentSendEvent.extraText}'));
    assert(debugLog('intentSendEvent.extraStream?.length: ${intentSendEvent.extraStream?.length}'));

    final navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final globalStore = GlobalStoreWidget.of(context);

    // TODO(#524) use last account used, not the first in the list
    // TODO(#1779) allow selecting account, if there are multiple
    final accountId = globalStore.accounts.firstOrNull?.id;

    if (accountId == null) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorSharingTitle,
        message: zulipLocalizations.errorSharingAccountNotLoggedIn);
      return;
    }

    final sharedFiles = intentSendEvent.extraStream?.map((sharedFile) {
      var mimeType = sharedFile.mimeType;

      // Try to guess the mimeType from file header magic-number.
      mimeType ??= lookupMimeType(
        // Seems like the path shouldn't be required; we still want to look for
        // matches on `headerBytes`. Thankfully we can still do that, by calling
        // lookupMimeType with the empty string as the path. That's a value that
        // doesn't map to any particular type, so the path will be effectively
        // ignored, as desired. Upstream comment:
        //   https://github.com/dart-lang/mime/issues/11#issuecomment-2246824452
        '',
        headerBytes: List.unmodifiable(
          sharedFile.bytes.take(defaultMagicNumbersMaxLength)));

      return FileToUpload(
        content: Stream.value(sharedFile.bytes),
        length: sharedFile.bytes.length,
        filename: sharedFile.name,
        mimeType: mimeType);
    });

    unawaited(navigator.push(
      SharePage.buildRoute(
        accountId: accountId,
        sharedFiles: sharedFiles,
        sharedText: intentSendEvent.extraText)));
  }
}

class SharePage extends StatelessWidget {
  const SharePage({
    super.key,
    required this.sharedFiles,
    required this.sharedText,
  });

  final Iterable<FileToUpload>? sharedFiles;
  final String? sharedText;

  static AccountRoute<void> buildRoute({
    required int accountId,
    required Iterable<FileToUpload>? sharedFiles,
    required String? sharedText,
  }) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      page: SharePage(
        sharedFiles: sharedFiles,
        sharedText: sharedText));
  }

  void _handleNarrowSelect(BuildContext context, Narrow narrow) {
    final messageListPageKey = GlobalKey<MessageListPageState>();

    // Push the message list page, replacing the share page.
    unawaited(Navigator.pushReplacement(context,
      MessageListPage.buildRoute(
        context: context,
        key: messageListPageKey,
        narrow: narrow)));

    // Wait for the message list page to appear in the widget tree.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final messageListPageState = messageListPageKey.currentState;
      if (messageListPageState == null) return; // TODO(log)
      final composeBoxState = messageListPageState.composeBoxState;
      if (composeBoxState == null) return; // TODO(log)

      final composeBoxController = composeBoxState.controller;

      // Focus on the topic input if there is one, else focus on content
      // input, if not already focused.
      composeBoxController.requestFocusIfUnfocused();

      // We can receive both: the file/s and an accompanying text,
      // so first populate the compose box with the text, if there is any.
      if (sharedText case var text?) {
        if (!text.endsWith('\n')) text += '\n';
        composeBoxController.content.insertPadded(text);
      }
      // Then upload the files and populate the content input with their links.
      if (sharedFiles != null) {
        await composeBoxController.uploadFiles(
          context: composeBoxState.context,
          files: sharedFiles!,
          // We handle requesting focus ourselves above.
          shouldRequestFocus: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(zulipLocalizations.sharePageTitle),
          bottom: TabBar(
            indicatorColor: designVariables.icon,
            labelColor: designVariables.foreground,
            unselectedLabelColor: designVariables.foreground.withFadedAlpha(0.7),
            splashFactory: NoSplash.splashFactory,
            tabs: [
              Tab(text: zulipLocalizations.channelsPageTitle),
              Tab(text: zulipLocalizations.recentDmConversationsPageTitle),
            ])),
        body: TabBarView(children: [
          SubscriptionListPageBody(
            showTopicListButtonInActionSheet: false,
            hideChannelsIfUserCantPost: true,
            onChannelSelect: (narrow) => _handleNarrowSelect(context, narrow),
            // TODO(#412) add onTopicSelect, Currently when user lands on the
            //   channel feed page from subscription list page and they tap
            //   on the topic recipient header, the user is brought to the
            //   topic message list, but without the share content. So, we
            //   might want to force the user to choose a topic or start a
            //   new topic from the subscription list page.
          ),
          RecentDmConversationsPageBody(
            hideDmsIfUserCantPost: true,
            onDmSelect: (narrow) => _handleNarrowSelect(context, narrow)),
        ])));
  }
}
