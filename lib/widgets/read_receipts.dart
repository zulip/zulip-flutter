import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:styled_text/styled_text.dart';

import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'action_sheet.dart';
import 'actions.dart';
import 'color.dart';
import 'inset_shadow.dart';
import 'profile.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

/// Opens a bottom sheet showing who has read the message.
void showReadReceiptsSheet(BuildContext pageContext, {required int messageId}) {
  final accountId = PerAccountStoreWidget.accountIdOf(pageContext);

  showModalBottomSheet<void>(
    context: pageContext,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) {
      return PerAccountStoreWidget(
        accountId: accountId,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 16),
          child: ReadReceipts(messageId: messageId)));
    });
}

class ReadReceipts extends StatefulWidget {
  const ReadReceipts({super.key, required this.messageId});

  final int messageId;

  @override
  State<ReadReceipts> createState() => _ReadReceiptsState();
}

class _ReadReceiptsState extends State<ReadReceipts> {
  List<int> userIds = [];
  FetchStatus status = FetchStatus.loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    tryFetchReadReceipts();
  }

  Future<void> tryFetchReadReceipts() async {
    final store = PerAccountStoreWidget.of(context);
    try {
      final result = await getReadReceipts(store.connection, messageId: widget.messageId);
      // TODO(i18n): add locale-aware sorting
      userIds = result.userIds.sortedByCompare(
        (id) => store.userDisplayName(id),
        (nameA, nameB) => nameA.toLowerCase().compareTo(nameB.toLowerCase()),
      );
      status = FetchStatus.success;
    } catch (e) {
      status = FetchStatus.error;
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReadReceiptsHeader(receiptCount: userIds.length, status: status),
          Expanded(child: _ReadReceiptsUserList(userIds: userIds, status: status)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const BottomSheetDismissButton(style: BottomSheetDismissButtonStyle.close))
        ]));
  }
}

enum FetchStatus { loading, success, error }

class _ReadReceiptsHeader extends StatelessWidget {
  const _ReadReceiptsHeader({required this.receiptCount, required this.status});

  final int receiptCount;
  final FetchStatus status;

  @override
  Widget build(BuildContext context) {
    final localizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(18, 16, 18, 8),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(localizations.actionSheetReadReceipts,
            style: TextStyle(
              fontSize: 20,
              height: 20 / 20,
              color: designVariables.title,
            ).merge(weightVariableTextStyle(context, wght: 600))),
          if (status == FetchStatus.success && receiptCount > 0)
            StyledText(
              text: localizations.actionSheetReadReceiptsReadCount(receiptCount),
              tags: {
                'link': StyledTextActionTag((_, attrs) {
                    PlatformActions.launchUrl(context, Uri.parse(attrs['href']!));
                  },
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: designVariables.link,
                    decorationColor: designVariables.link),
                )},
              style: TextStyle(fontSize: 17, height: 22 / 17,
                color: designVariables.textMessage)),
        ]));
  }
}

class _ReadReceiptsUserList extends StatelessWidget {
  const _ReadReceiptsUserList({required this.userIds, required this.status});

  final List<int> userIds;
  final FetchStatus status;

  @override
  Widget build(BuildContext context) {
    final localizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    return Center(
      child: switch(status) {
        FetchStatus.loading => CircularProgressIndicator(),
        FetchStatus.error   => BottomSheetInfoText(
          text: localizations.actionSheetReadReceiptsErrorReadCount,
          textAlign: TextAlign.center),
        FetchStatus.success => userIds.isEmpty
          ? BottomSheetInfoText(
              text: localizations.actionSheetReadReceiptsZeroReadCount,
              textAlign: TextAlign.center)
          : InsetShadowBox(
              top: 8, bottom: 8,
              color: designVariables.bgContextMenu,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: userIds.length,
                itemBuilder: (context, index) =>
                  ReadReceiptsUserItem(userId: userIds[index])))
      });
  }
}


// TODO: deduplicate the code with [ViewReactionsUserItem]
@visibleForTesting
class ReadReceiptsUserItem extends StatelessWidget {
  const ReadReceiptsUserItem({super.key, required this.userId});

  final int userId;

  void _onPressed(BuildContext context) {
    // Dismiss the action sheet.
    Navigator.pop(context);

    Navigator.push(context,
      ProfilePage.buildRoute(context: context, userId: userId));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    return InkWell(
      onTap: () => _onPressed(context),
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateColor.resolveWith((states) =>
        states.any((e) => e == WidgetState.pressed)
          ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
          : Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(spacing: 8, children: [
          Avatar(
            size: 32,
            borderRadius: 3,
            backgroundColor: designVariables.bgContextMenu,
            userId: userId),
          Flexible(
            child: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                height: 17 / 17,
                color: designVariables.textMessage,
              ).merge(weightVariableTextStyle(context, wght: 500)),
              store.userDisplayName(userId))),
        ])));
  }
}
