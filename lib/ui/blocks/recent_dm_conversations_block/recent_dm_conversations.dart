import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../get/app_pages.dart';
import '../../../get/services/domains/unreads/unreads_service.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/store_service.dart';
import '../../../model/narrow.dart';
import '../../../model/recent_dm_conversations.dart';
import '../../../model/unreads.dart';
import '../../utils/page.dart';
import 'widgets/recent_dm_conversations_item.dart';

typedef OnDmSelectCallback = void Function(DmNarrow narrow);

// Блок сообщений (на гл странице)
class RecentDmConversationsPageBody extends StatefulWidget {
  const RecentDmConversationsPageBody({
    super.key,
    this.hideDmsIfUserCantPost = false,
    this.onDmSelect,
  });

  // TODO refactor this widget to avoid reuse of the whole page,
  //   avoiding the need for these flags, callback, and the below
  //   handling of safe-area at this level of abstraction.
  //   See discussion:
  //     https://github.com/zulip/zulip-flutter/pull/1774#discussion_r2249032503
  final bool hideDmsIfUserCantPost;

  /// Callback to invoke when the user selects a DM conversation from the list.
  ///
  /// If null, the default behavior is to navigate to the DM conversation.
  final OnDmSelectCallback? onDmSelect;

  @override
  State<RecentDmConversationsPageBody> createState() =>
      _RecentDmConversationsPageBodyState();
}

class _RecentDmConversationsPageBodyState
    extends State<RecentDmConversationsPageBody> {
  RecentDmConversationsView? _model;
  Unreads? _unreadsModel;

  @override
  void initState() {
    super.initState();
    ever(StoreService.to.currentStore, (_) => _onStoreChanged());
    _initFromStore();
  }

  void _onStoreChanged() {
    _model?.removeListener(_modelChanged);
    _unreadsModel?.removeListener(_modelChanged);
    _initFromStore();
  }

  void _initFromStore() {
    _model = StoreService.to.requireStore.recentDmConversationsView
      ..addListener(_modelChanged);
    _unreadsModel = UnreadsService.to.unreads?..addListener(_modelChanged);
  }

  @override
  void dispose() {
    _model?.removeListener(_modelChanged);
    _unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [_model] and [_unreadsModel].
    });
  }

  void _handleDmSelect(DmNarrow narrow) {
    if (widget.onDmSelect case final onDmSelect?) {
      onDmSelect(narrow);
    } else {
      Get.toNamed<dynamic>(
        AppRoutes.messageList,
        arguments: {'narrow': narrow},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final zulipLocalizations = ZulipLocalizations.of(context);
    final sorted = _model!.sorted;

    // This value will be zero when this page is used in the context of
    // home-page, see comment on `bottom: false` arg in use of `SafeArea`
    // below.
    final bottomInsets = MediaQuery.paddingOf(context).bottom;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        if (sorted.isEmpty)
          PageBodyEmptyContentPlaceholder(
            header:
                zulipLocalizations.recentDmConversationsEmptyPlaceholderHeader,
            message:
                zulipLocalizations.recentDmConversationsEmptyPlaceholderMessage,
          )
        else
          SafeArea(
            // Don't pad the bottom here; we want the list content to do that.
            //
            // When this page is used in the context of the home page, this
            // param and the below use of `MediaQuery.paddingOf(context).bottom`
            // via `bottomInsets` would be noop, because
            // `Scaffold.bottomNavigationBar` in the home page handles that for
            // us. But this page is also used for share-to-zulip page, so we
            // need this to be handled here.
            //
            // Other *PageBody widgets don't handle this because they aren't
            // (re-)used outside the context of the home page.
            bottom: false,
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: bottomInsets + 90),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final narrow = sorted[index];
                if (store.shouldMuteDmConversation(narrow)) {
                  // Filter out conversations where everyone is muted.
                  // TODO should we offer a "spam folder"-style summary screen
                  //   for these conversations we're filtering out?
                  return SizedBox.shrink();
                }
                if (widget.hideDmsIfUserCantPost) {
                  // TODO(#791) handle other cases where user can't post
                  final hasDeactivatedUser = narrow.otherRecipientIds.any(
                    (id) => !(store.getUser(id)?.isActive ?? true),
                  );
                  if (hasDeactivatedUser) {
                    return SizedBox.shrink();
                  }
                }
                return RecentDmConversationsItem(
                  narrow: narrow,
                  unreadCount: _unreadsModel!.countInDmNarrow(narrow),
                  onDmSelect: _handleDmSelect,
                );
              },
            ),
          ),
        // Positioned(
        //   bottom: bottomInsets + 21,
        //   child: NewDmButton(onDmSelect: _handleDmSelectForNewDms),
        // ),
      ],
    );
  }
}
