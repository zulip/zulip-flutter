import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
    assert(debugLog('intentSendEvent.extraStream: [${intentSendEvent.extraStream?.join(',')}]'));

    NavigatorState navigator = await ZulipApp.navigator;
    final context = navigator.context;
    assert(context.mounted);
    if (!context.mounted) return; // TODO(linter): this is impossible as there's no actual async gap, but the use_build_context_synchronously lint doesn't see that

    final globalStore = GlobalStoreWidget.of(context);

    // TODO(#524) choose initial account as last one used
    // TODO(#1779) allow selecting account, if there are multiple
    final initialAccountId = globalStore.accounts.firstOrNull?.id;

    if (initialAccountId == null) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorSharingTitle,
        message: zulipLocalizations.errorSharingAccountNotLoggedIn);
      return;
    }

    unawaited(navigator.push(
      SharePage.buildRoute(
        accountId: initialAccountId,
        sharedFiles: intentSendEvent.extraStream?.map((sharedFile) {
          return FileToUpload(
            content: Stream.value(sharedFile.bytes),
            length: sharedFile.bytes.length,
            filename: sharedFile.name,
            mimeType: sharedFile.mimeType);
        }),
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
    final messageListPageStateKey = GlobalKey<MessageListPageState>();

    // Push the message list page, replacing the share page.
    unawaited(Navigator.pushReplacement(context,
      MessageListPage.buildRoute(
        key: messageListPageStateKey,
        context: context,
        narrow: narrow)));

    // Wait for the message list page to accommodate in the widget tree from the route.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final messageListPageState = messageListPageStateKey.currentState;
      if (messageListPageState == null) return; // TODO(log)
      final composeBoxState = messageListPageState.composeBoxState;
      if (composeBoxState == null) return; // TODO(log)

      final composeBoxController = composeBoxState.controller;

      // Try to focus on the topic compose box if there is one,
      // else focus on content compose box, if not already focused.
      if (composeBoxController is StreamComposeBoxController) {
        if (!composeBoxController.topicFocusNode.hasFocus) {
          composeBoxController.topicFocusNode.requestFocus();
        }
      } else {
        if (!composeBoxController.contentFocusNode.hasFocus) {
          composeBoxController.contentFocusNode.requestFocus();
        }
      }

      // We can receive both: the file/s and an accompanying text,
      // so first populate the compose box with the text, if there is any.
      if (sharedText case var text?) {
        if (!text.endsWith('\n')) text += '\n';

        // If there are any shared files, add a separator new line.
        if (sharedFiles != null) text += '\n';

        // Populate the text.
        final contentController = composeBoxController.content;
        contentController.value =
          contentController.value
            .replaced(contentController.insertionIndex(), text);
      }
      // Then upload the files and populate the compose box with their links.
      if (sharedFiles != null) {
        await composeBoxState.uploadFiles(
          files: sharedFiles!,
          // We handle requesting focus ourselves above.
          contentFocusNode: null);
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
        body: SafeArea(
          child: TabBarView(children: [
            SubscriptionListPageBody(
              disableChannelActionSheet: true,
              hideChannelsIfUserCantPost: true,
              onChannelSelect: _handleNarrowSelect),
            RecentDmConversationsPageBody(
              hideDmsIfUserCantPost: true,
              onDmSelect: _handleNarrowSelect),
          ]))));
  }
}
