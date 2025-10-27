import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../api/route/messages.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'action_sheet.dart';
import 'actions.dart';
import 'color.dart';
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

/// The read-receipts sheet.
///
/// Figma link:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=11367-20647&t=lSnHudU6l7NWx0Fa-0
class ReadReceipts extends StatefulWidget {
  const ReadReceipts({super.key, required this.messageId});

  final int messageId;

  @override
  State<ReadReceipts> createState() => _ReadReceiptsState();
}

class _ReadReceiptsState extends State<ReadReceipts> with PerAccountStoreAwareStateMixin<ReadReceipts> {
  List<int> userIds = [];
  FetchStatus status = FetchStatus.loading;

  @override
  void onNewStore() {
    tryFetchReadReceipts(context);
  }

  Future<void> tryFetchReadReceipts(BuildContext context) async {
    final store = PerAccountStoreWidget.of(context);
    try {
      final result = await getReadReceipts(store.connection, messageId: widget.messageId);

      if (!context.mounted) return;
      final storeNow = PerAccountStoreWidget.of(context);
      if (!identical(store, storeNow)) return;

      // TODO(i18n): add locale-aware sorting
      userIds = result.userIds.sortedByCompare(
        store.userDisplayName,
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
    final zulipLocalizations = ZulipLocalizations.of(context);
    final receiptCount = userIds.length;

    final content = switch (status) {
      FetchStatus.loading => SliverToBoxAdapter(
        child: BottomSheetEmptyContentPlaceholder(loading: true)),
      FetchStatus.error   => SliverToBoxAdapter(
        child: BottomSheetEmptyContentPlaceholder(
          message: zulipLocalizations.actionSheetReadReceiptsErrorReadCount)),
      FetchStatus.success => userIds.isEmpty
        ? SliverToBoxAdapter(
            child: BottomSheetEmptyContentPlaceholder(
              message: zulipLocalizations.actionSheetReadReceiptsZeroReadCount))
        : SliverList.builder(
            itemCount: receiptCount,
            itemBuilder: (_, index) => ReadReceiptsUserItem(userId: userIds[index])),
    };

    return DraggableScrollableModalBottomSheet(
      header: _ReadReceiptsHeader(receiptCount: receiptCount, status: status),
      contentSliver: content);
  }
}

enum FetchStatus { loading, success, error }

class _ReadReceiptsHeader extends StatelessWidget {
  const _ReadReceiptsHeader({required this.receiptCount, required this.status});

  final int receiptCount;
  final FetchStatus status;

  static const _helpCenterRelativeUrl = '/help/read-receipts';

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);

    WidgetBuilderFromTextStyle? headerMessageBuilder;
    if (status == FetchStatus.success && receiptCount > 0) {
      headerMessageBuilder = (TextStyle style) => TextWithLink(
        onTap: () {
          PlatformActions.launchUrl(context, PerAccountStoreWidget.of(context)
            .tryResolveUrl(_helpCenterRelativeUrl)!);
        },
        style: style,
        markup: zulipLocalizations.actionSheetReadReceiptsReadCount(receiptCount));
    }

    return BottomSheetHeader(
      outerVerticalPadding: true,
      title: zulipLocalizations.actionSheetReadReceipts,
      buildMessage: headerMessageBuilder);
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
      overlayColor: WidgetStateColor.fromMap({
        WidgetState.pressed: designVariables.contextMenuItemBg.withFadedAlpha(0.20),
      }),
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
