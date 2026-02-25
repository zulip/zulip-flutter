import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mime/mime.dart';

import '../api/core.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../host/android_intents.dart';
import '../log.dart';
import '../model/binding.dart';
import '../model/narrow.dart';
import '../model/store.dart';
import 'action_sheet.dart';
import 'app.dart';
import 'compose_box.dart';
import 'dialog.dart';
import 'home.dart';
import 'icons.dart';
import 'image.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'subscription_list.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

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

    // TODO(#1779) allow selecting account, if there are multiple
    final accountId = globalStore.lastVisitedAccount?.id
      ?? globalStore.accountIds.firstOrNull;

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
        // matches on `headerBytes` when we don't have a path/filename.
        // Thankfully we can still do that, by calling lookupMimeType with the
        // empty string as the path. That's a value that doesn't map to any
        // particular type, so the path will be effectively ignored, as desired.
        // Upstream comment:
        //   https://github.com/dart-lang/mime/issues/11#issuecomment-2246824452
        sharedFile.name ?? '',
        headerBytes: List.unmodifiable(
          sharedFile.bytes.take(defaultMagicNumbersMaxLength)));

      final filename =
        sharedFile.name ?? 'unknown.${mimeType?.split('/').last ?? 'bin'}';

      return FileToUpload(
        content: Stream.value(sharedFile.bytes),
        length: sharedFile.bytes.length,
        filename: filename,
        mimeType: mimeType);
    });

    ShareSheet.show(
      pageContext: context,
      initialAccountId: accountId,
      sharedFiles: sharedFiles,
      sharedText: intentSendEvent.extraText);
  }
}

/// The Share-to-Zulip sheet.
///
/// Figma link:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=12853-76543&p=f&t=oBRXWxFjbkz1yeI7-0
class ShareSheet extends StatelessWidget {
  const ShareSheet._({
    required this.sharedFiles,
    required this.sharedText,
  });

  final Iterable<FileToUpload>? sharedFiles;
  final String? sharedText;

  static void show({
    required BuildContext pageContext,
    required int initialAccountId,
    required Iterable<FileToUpload>? sharedFiles,
    required String? sharedText,
  }) async {
    unawaited(showModalBottomSheet<void>(
      context: pageContext,
      // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
      // on my iPhone 13 Pro but is marked as "much slower":
      //   https://api.flutter.dev/flutter/dart-ui/Clip.html
      clipBehavior: Clip.antiAlias,
      useSafeArea: true,
      isScrollControlled: true,
      // The Figma uses designVariables.mainBackground, which we could set
      // here with backgroundColor. Shrug; instead, accept the background color
      // from BottomSheetThemeData, which is similar to that (as of 2025-10-07),
      // for consistency with other bottom sheets.
      builder: (_) {
        return PerAccountStoreWidget(
          accountId: initialAccountId,
          // PageRoot goes under PerAccountStoreWidget, so the provided context
          // can be used for PerAccountStoreWidget.of.
          child: PageRoot(
            child: ShareSheet._(
              sharedFiles: sharedFiles,
              sharedText: sharedText)));
      }));
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
    final globalStore = GlobalStoreWidget.of(context);
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final hasMultipleAccounts = globalStore.accountIds.length > 1;

    Widget mkTabLabel({required String text, required IconData icon}) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: 42),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            Icon(size: 24, icon),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                ).merge(weightVariableTextStyle(context, wght: 500)))),
          ]));
    }

    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Row(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: !hasMultipleAccounts
              ? null
              : () {
                  ChooseAccountForShareModal.show(
                    pageContext: context,
                    selectedAccountId: store.accountId,
                    sharedFiles: sharedFiles,
                    sharedText: sharedText);
                },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 11),
              child: AvatarShape(
                size: 28,
                borderRadius: 4,
                child: RealmContentNetworkImage(
                  store.resolvedRealmIcon,
                  filterQuality: FilterQuality.medium,
                  fit: BoxFit.cover)))),
          Expanded(child: TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            labelColor: designVariables.iconSelected,
            unselectedLabelColor: designVariables.icon,
            // TODO(upstream): The documentation for `indicatorWeight` states
            //   that it is ignored if `indicator` is specified. But that
            //   doesn't seem to be the case in practice, this value affects
            //   the size of the tab label, making the tab label 2px larger
            //   which is also the default value for this argument. See:
            //     https://github.com/flutter/flutter/issues/171951
            //   As a workaround passing a value of zero appears to be working
            //   fine, so use that.
            indicatorWeight: 0,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: designVariables.iconSelected,
                width: 4.0)),
            dividerHeight: 0,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
            tabs: [
              mkTabLabel(
                text: zulipLocalizations.channelsPageTitle,
                icon: ZulipIcons.hash_italic),
              mkTabLabel(
                text: zulipLocalizations.recentDmConversationsPageShortLabel,
                icon: ZulipIcons.two_person),
            ])),
        ]),
        Expanded(child: TabBarView(children: [
          SubscriptionListPageBody(
            showTopicListButtonInActionSheet: false,
            hideChannelsIfUserCantSendMessage: true,
            allowGoToAllChannels: false,
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
        ])),
      ]));
  }
}

class ChooseAccountForShareModal extends StatefulWidget {
  const ChooseAccountForShareModal._({
    required this.sharedFiles,
    required this.sharedText,
  });

  final Iterable<FileToUpload>? sharedFiles;
  final String? sharedText;

  static void show({
    required BuildContext pageContext,
    required int selectedAccountId,
    required Iterable<FileToUpload>? sharedFiles,
    required String? sharedText,
  }) async {
    unawaited(showModalBottomSheet<void>(
      context: pageContext,
      // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
      // on my iPhone 13 Pro but is marked as "much slower":
      //   https://api.flutter.dev/flutter/dart-ui/Clip.html
      clipBehavior: Clip.antiAlias,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          minimum: const EdgeInsets.only(bottom: 16),
          child: ChooseAccountForShareModal._(
            sharedFiles: sharedFiles,
            sharedText: sharedText));
      }));
  }

  @override
  State<ChooseAccountForShareModal> createState() => _ChooseAccountForShareModalState();
}

class _ChooseAccountForShareModalState extends State<ChooseAccountForShareModal> {
  bool _hasUpdatedAccountsOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final globalStore = GlobalStoreWidget.of(context);

    if (_hasUpdatedAccountsOnce) return;
    _hasUpdatedAccountsOnce = true;

    globalStore.refreshRealmMetadata();
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = GlobalStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final accounts = List<Account>.unmodifiable(globalStore.accounts);

    // TODO(#1038) align the design of this dialog to other
    //   choose account dialogs
    final content = SliverList.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final accountId = account.id;

        final resolvedRealmIconUrl =
          account.realmIcon == null
            ? null
            : account.realmUrl.resolveUri(account.realmIcon!);

        return ListTile(
          onTap: () {
            // First change home page account to the selected account.
            HomePage.navigate(context, accountId: accountId);
            // Then push a new share dialog for the selected account.
            ShareSheet.show(
              pageContext: context,
              initialAccountId: accountId,
              sharedFiles: widget.sharedFiles,
              sharedText: widget.sharedText);
          },
          splashColor: Colors.transparent,
          leading: AvatarShape(
            size: 56,
            borderRadius: 4,
            child: resolvedRealmIconUrl == null
              ? const SizedBox.shrink()
              : Image.network(
                  resolvedRealmIconUrl.toString(),
                  headers: userAgentHeader(),
                  filterQuality: FilterQuality.medium,
                  fit: BoxFit.cover)),
          title: Text(account.realmName ?? account.realmUrl.toString()),
          subtitle: Text(account.email));
      });

    return DraggableScrollableModalBottomSheet(
      header: BottomSheetHeader(
        title: zulipLocalizations.shareChooseAccountModalTitle,
        outerVerticalPadding: true),
      contentSliver: content);
  }
}
