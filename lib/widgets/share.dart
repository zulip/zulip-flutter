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
import '../model/store.dart';
import 'action_sheet.dart';
import 'app.dart';
import 'button.dart';
import 'color.dart';
import 'compose_box.dart';
import 'dialog.dart';
import 'home.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'subscription_list.dart';
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

    if (globalStore.accounts.isEmpty) {
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

    unawaited(navigator.push(
      SharePage.buildRoute(
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

  static MaterialWidgetRoute<void> buildRoute({
    required Iterable<FileToUpload>? sharedFiles,
    required String? sharedText,
  }) {
    return MaterialWidgetRoute(
      // TODO either call [ChooseAccountForShareDialog.show] every time this
      //   page initializes, or else have the [MultiAccountPageController]
      //   default to the last-visited account
      page: MultiAccountPageProvider(
        // So that PageRoot.contextOf can be used for MultiAccountPageProvider.of
        child: PageRoot(
          child: SharePage(sharedFiles: sharedFiles, sharedText: sharedText))));
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
    final selectedAccountId = MultiAccountPageProvider.of(context).selectedAccountId;

    PreferredSizeWidget? bottom;
    if (selectedAccountId != null) {
      bottom = TabBar(
        indicatorColor: designVariables.icon,
        labelColor: designVariables.foreground,
        unselectedLabelColor: designVariables.foreground.withFadedAlpha(0.7),
        splashFactory: NoSplash.splashFactory,
        tabs: [
          Tab(text: zulipLocalizations.channelsPageTitle),
          Tab(text: zulipLocalizations.recentDmConversationsPageTitle),
        ]);
    }

    final Widget? body;
    if (selectedAccountId != null) {
      body = PerAccountStoreWidget(
        accountId: selectedAccountId,
        placeholder: PageBodyEmptyContentPlaceholder(loading: true),
        child: TabBarView(children: [
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
        ]));
    } else {
      body = PageBodyEmptyContentPlaceholder(
        // TODO i18n, choose the right wording
        message: 'No account is selected. Please use the button above to choose one.');
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(zulipLocalizations.sharePageTitle),
          actionsPadding: EdgeInsetsDirectional.only(end: 8),
          actions: [AccountSelectorButton()],
          bottom: bottom),
        body: body));
  }
}

class AccountSelectorButton extends StatelessWidget {
  const AccountSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final pageContext = PageRoot.contextOf(context);
    final controller = MultiAccountPageProvider.of(context);
    final selectedAccountId = controller.selectedAccountId;

    if (selectedAccountId == null) {
      return ZulipWebUiKitButton(
        attention: ZulipWebUiKitButtonAttention.high, // TODO medium looks better?
        label: 'Choose account', // TODO i18n, choose the right text
        onPressed: () => ChooseAccountForShareDialog.show(pageContext));
    } else {
      return ZulipWebUiKitButton(
        attention: ZulipWebUiKitButtonAttention.medium, // TODO low looks better?
        label: 'Change account', // TODO i18n, choose the right text
        buildIcon: (size) => PerAccountStoreWidget(
          accountId: selectedAccountId,
          placeholder: SizedBox.square(dimension: size), // TODO(#1036) realm logo
          child: Builder(builder: (context) {
            final store = PerAccountStoreWidget.of(context);
            return AvatarShape(size: size, borderRadius: 3,
              // TODO get realm logo from `store`
              child: ColoredBox(color: Colors.pink));
          })),
        onPressed: () => ChooseAccountForShareDialog.show(pageContext));
    }
  }
}

/// A dialog offering the list of accounts,
/// for one to be chosen to share to.
class ChooseAccountForShareDialog extends StatelessWidget {
  const ChooseAccountForShareDialog._(this.pageContext);

  final BuildContext pageContext;

  static void show(BuildContext pageContext) async {
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
          child: ChooseAccountForShareDialog._(pageContext));
      }));
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = GlobalStoreWidget.of(context);
    final accountIds = globalStore.accountIds.toList();
    final controller = MultiAccountPageProvider.of(pageContext);
    final content = SliverList.builder(
      itemCount: accountIds.length,
      itemBuilder: (_, index) {
        final accountId = accountIds[index];
        final account = globalStore.getAccount(accountId);
        return _AccountButton(
          account!,
          handlePressed: () => controller.selectAccount(accountId),
          selected: accountId == controller.selectedAccountId);
      });

    return DraggableScrollableModalBottomSheet(
      header: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: BottomSheetHeader(title: 'Choose an account:')),
      contentSliver: SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        sliver: content));
  }
}

class _AccountButton extends MenuButton {
  const _AccountButton(this.account, {
    required this.handlePressed,
    required bool selected,
  }) : _selected = selected;

  final Account account;
  final VoidCallback handlePressed;

  @override
  bool get selected => _selected;
  final bool _selected;

  @override
  IconData? get icon => null;

  @override
  Widget buildLeading(BuildContext context) {
    return AvatarShape(
      size: MenuButton.iconSize,
      borderRadius: 4,
      // TODO(#1036) realm logo
      child: ColoredBox(color: Colors.pink));
  }

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    // TODO(#1036) realm name (and email?)
    return account.email;
  }

  @override
  void onPressed(BuildContext context) {
    handlePressed();
  }
}
