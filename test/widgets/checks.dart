import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/realm.dart';

import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/all_channels.dart';
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/channel_colors.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/emoji.dart';
import 'package:zulip/widgets/emoji_reaction.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/login.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/profile.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/unread_count_badge.dart';
import 'package:zulip/widgets/user.dart';

extension ChannelColorSwatchChecks on Subject<ChannelColorSwatch> {
  Subject<Color> get base => has((s) => s.base, 'base');
  Subject<Color> get unreadCountBadgeBackground => has((s) => s.unreadCountBadgeBackground, 'unreadCountBadgeBackground');
  Subject<Color> get iconOnPlainBackground => has((s) => s.iconOnPlainBackground, 'iconOnPlainBackground');
  Subject<Color> get iconOnBarBackground => has((s) => s.iconOnBarBackground, 'iconOnBarBackground');
  Subject<Color> get barBackground => has((s) => s.barBackground, 'barBackground');
}

extension ComposeBoxStateChecks on Subject<ComposeBoxState> {
  Subject<ComposeBoxController> get controller => has((c) => c.controller, 'controller');
}

extension ComposeBoxControllerChecks on Subject<ComposeBoxController> {
  Subject<ComposeContentController> get content => has((c) => c.content, 'content');
  Subject<FocusNode> get contentFocusNode => has((c) => c.contentFocusNode, 'contentFocusNode');
}

extension StreamComposeBoxControllerChecks on Subject<StreamComposeBoxController> {
  Subject<ComposeTopicController> get topic => has((c) => c.topic, 'topic');
  Subject<FocusNode> get topicFocusNode => has((c) => c.topicFocusNode, 'topicFocusNode');
}

extension EditMessageComposeBoxControllerChecks on Subject<EditMessageComposeBoxController> {
  Subject<int> get messageId => has((c) => c.messageId, 'messageId');
  Subject<String?> get originalRawContent => has((c) => c.originalRawContent, 'originalRawContent');
}

extension ComposeContentControllerChecks on Subject<ComposeContentController> {
  Subject<List<ContentValidationError>> get validationErrors => has((c) => c.validationErrors, 'validationErrors');
}

extension RealmContentNetworkImageChecks on Subject<RealmContentNetworkImage> {
  Subject<Uri> get src => has((i) => i.src, 'src');
  // TODO others
}

extension AvatarImageChecks on Subject<AvatarImage> {
  Subject<int> get userId => has((i) => i.userId, 'userId');
}

extension AvatarShapeChecks on Subject<AvatarShape> {
  Subject<double> get size => has((i) => i.size, 'size');
  Subject<double> get borderRadius => has((i) => i.borderRadius, 'borderRadius');
  Subject<Widget> get child => has((i) => i.child, 'child');
}

extension MessageListPageChecks on Subject<MessageListPage> {
  Subject<Narrow> get initNarrow => has((x) => x.initNarrow, 'initNarrow');
  Subject<int?> get initAnchorMessageId => has((x) => x.initAnchorMessageId, 'initAnchorMessageId');
}

extension WidgetRouteChecks<T> on Subject<WidgetRoute<T>> {
  Subject<Widget> get page => has((x) => x.page, 'page');
}

extension AccountRouteChecks<T> on Subject<AccountRoute<T>> {
  Subject<int> get accountId => has((x) => x.accountId, 'accountId');
}

extension LoginPageChecks on Subject<LoginPage> {
  Subject<GetServerSettingsResult> get serverSettings => has((x) => x.serverSettings, 'serverSettings');
}

extension ProfilePageChecks on Subject<ProfilePage> {
  Subject<int> get userId => has((x) => x.userId, 'userId');
}

extension PerAccountStoreWidgetChecks on Subject<PerAccountStoreWidget> {
  Subject<int> get accountId => has((x) => x.accountId, 'accountId');
  Subject<Widget> get child => has((x) => x.child, 'child');
}

extension UnreadCountBadgeChecks on Subject<UnreadCountBadge> {
  Subject<int> get count => has((b) => b.count, 'count');
  Subject<int?> get channelIdForBackground => has((b) => b.channelIdForBackground, 'channelIdForBackground');
}

extension UnicodeEmojiWidgetChecks on Subject<UnicodeEmojiWidget> {
  Subject<UnicodeEmojiDisplay> get emojiDisplay => has((x) => x.emojiDisplay, 'emojiDisplay');
}

extension EmojiPickerListEntryChecks on Subject<EmojiPickerListEntry> {
  Subject<EmojiCandidate> get emoji => has((x) => x.emoji, 'emoji');
}

extension AllChannelsListEntryChecks on Subject<AllChannelsListEntry> {
  Subject<ZulipStream> get channel => has((x) => x.channel, 'channel');
}

extension ToggleChecks on Subject<Toggle> {
  Subject<bool> get value => has((x) => x.value, 'value');
}
