// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class ZulipLocalizationsJa extends ZulipLocalizations {
  ZulipLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get aboutPageTitle => 'Zulipについて';

  @override
  String get aboutPageAppVersion => 'アプリのバージョン';

  @override
  String get aboutPageOpenSourceLicenses => 'オープンソースライセンス';

  @override
  String get aboutPageTapToView => 'タップして表示';

  @override
  String get upgradeWelcomeDialogTitle => '新しいZulipアプリへようこそ！';

  @override
  String get upgradeWelcomeDialogMessage =>
      'より速く、洗練されたデザインで、これまでと同じ使い心地をお楽しみいただけます。';

  @override
  String get upgradeWelcomeDialogLinkText => 'お知らせブログ記事をご確認ください！';

  @override
  String get upgradeWelcomeDialogDismiss => 'はじめよう';

  @override
  String get chooseAccountPageTitle => 'アカウントを選択';

  @override
  String get settingsPageTitle => '設定';

  @override
  String get switchAccountButton => 'アカウントを切り替える';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Your account at $url is taking a while to load.';
  }

  @override
  String get tryAnotherAccountButton => 'Try another account';

  @override
  String get chooseAccountPageLogOutButton => 'ログアウト';

  @override
  String get logOutConfirmationDialogTitle => 'ログアウトしますか？';

  @override
  String get logOutConfirmationDialogMessage =>
      'To use this account in the future, you will have to re-enter the URL for your organization and your account information.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Log out';

  @override
  String get chooseAccountButtonAddAnAccount => '新しいアカウントを追加';

  @override
  String get profileButtonSendDirectMessage => 'ダイレクトメッセージを送信';

  @override
  String get errorCouldNotShowUserProfile => 'Could not show user profile.';

  @override
  String get permissionsNeededTitle => 'Permissions needed';

  @override
  String get permissionsNeededOpenSettings => 'Open settings';

  @override
  String get permissionsDeniedCameraAccess =>
      'To upload an image, please grant Zulip additional permissions in Settings.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'To upload files, please grant Zulip additional permissions in Settings.';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'チャンネルを既読にする';

  @override
  String get actionSheetOptionCopyChannelLink => 'Copy link to channel';

  @override
  String get actionSheetOptionListOfTopics => 'トピック一覧';

  @override
  String get actionSheetOptionMuteTopic => 'トピックをミュート';

  @override
  String get actionSheetOptionUnmuteTopic => 'トピックのミュートを解除';

  @override
  String get actionSheetOptionFollowTopic => 'トピックをフォロー';

  @override
  String get actionSheetOptionUnfollowTopic => 'トピックのフォローを解除';

  @override
  String get actionSheetOptionResolveTopic => '解決済みにする';

  @override
  String get actionSheetOptionUnresolveTopic => '未解決にする';

  @override
  String get errorResolveTopicFailedTitle => 'トピックを解決済みにできませんでした';

  @override
  String get errorUnresolveTopicFailedTitle => 'トピックを未解決にできませんでした';

  @override
  String get actionSheetOptionCopyMessageText => 'メッセージ本文をコピー';

  @override
  String get actionSheetOptionCopyMessageLink => 'メッセージへのリンクをコピー';

  @override
  String get actionSheetOptionMarkAsUnread => 'ここから未読にする';

  @override
  String get actionSheetOptionHideMutedMessage => 'ミュートしたメッセージを再び非表示にする';

  @override
  String get actionSheetOptionShare => '共有';

  @override
  String get actionSheetOptionQuoteMessage => 'メッセージを引用';

  @override
  String get actionSheetOptionStarMessage => 'メッセージにスターを付ける';

  @override
  String get actionSheetOptionUnstarMessage => 'メッセージのスターを外す';

  @override
  String get actionSheetOptionEditMessage => 'メッセージを編集';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'トピックを既読にする';

  @override
  String get actionSheetOptionCopyTopicLink => 'Copy link to topic';

  @override
  String get errorWebAuthOperationalErrorTitle => '問題が発生しました';

  @override
  String get errorWebAuthOperationalError => '予期しないエラーが発生しました。';

  @override
  String get errorAccountLoggedInTitle => 'このアカウントはすでにログインしています';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'The account $email at $server is already in your list of accounts.';
  }

  @override
  String get errorCouldNotFetchMessageSource => 'メッセージのソースを取得できませんでした。';

  @override
  String get errorCopyingFailed => 'コピーに失敗しました';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'ファイルのアップロードに失敗しました: $filename';
  }

  @override
  String filenameAndSizeInMiB(String filename, String size) {
    return '$filename: $size MiB';
  }

  @override
  String errorFilesTooLarge(
    int num,
    int maxFileUploadSizeMib,
    String listMessage,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num files are',
      one: 'File is',
    );
    return '$_temp0 larger than the server\'s limit of $maxFileUploadSizeMib MiB and will not be uploaded:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Files',
      one: 'File',
    );
    return '$_temp0 too large';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Invalid input';

  @override
  String get errorLoginFailedTitle => 'Login failed';

  @override
  String get errorMessageNotSent => 'Message not sent';

  @override
  String get errorMessageEditNotSaved => 'Message not saved';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Failed to connect to server:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Could not connect';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'That message does not seem to exist.';

  @override
  String get errorQuotationFailed => 'Quotation failed';

  @override
  String errorServerMessage(String message) {
    return 'The server said:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Error connecting to Zulip. Retrying…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Error connecting to Zulip at $serverUrl. Will retry:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Error handling a Zulip event. Retrying connection…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Error handling a Zulip event from $serverUrl; will retry.\n\nError: $error\n\nEvent: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Unable to open link';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Link could not be opened: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Failed to mute topic';

  @override
  String get errorUnmuteTopicFailed => 'Failed to unmute topic';

  @override
  String get errorFollowTopicFailed => 'Failed to follow topic';

  @override
  String get errorUnfollowTopicFailed => 'Failed to unfollow topic';

  @override
  String get errorSharingFailed => 'Sharing failed';

  @override
  String get errorStarMessageFailedTitle => 'Failed to star message';

  @override
  String get errorUnstarMessageFailedTitle => 'Failed to unstar message';

  @override
  String get errorCouldNotEditMessageTitle => 'Could not edit message';

  @override
  String get successLinkCopied => 'Link copied';

  @override
  String get successMessageTextCopied => 'Message text copied';

  @override
  String get successMessageLinkCopied => 'Message link copied';

  @override
  String get successTopicLinkCopied => 'Topic link copied';

  @override
  String get successChannelLinkCopied => 'Channel link copied';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'You cannot send messages to deactivated users.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'You do not have permission to post in this channel.';

  @override
  String get composeBoxBannerLabelEditMessage => 'Edit message';

  @override
  String get composeBoxBannerButtonCancel => 'Cancel';

  @override
  String get composeBoxBannerButtonSave => 'Save';

  @override
  String get editAlreadyInProgressTitle => 'Cannot edit message';

  @override
  String get editAlreadyInProgressMessage =>
      'An edit is already in progress. Please wait for it to complete.';

  @override
  String get savingMessageEditLabel => 'SAVING EDIT…';

  @override
  String get savingMessageEditFailedLabel => 'EDIT NOT SAVED';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Discard the message you’re writing?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'When you edit a message, the content that was previously in the compose box is discarded.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'When you restore an unsent message, the content that was previously in the compose box is discarded.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Discard';

  @override
  String get composeBoxAttachFilesTooltip => 'Attach files';

  @override
  String get composeBoxAttachMediaTooltip => 'Attach images or videos';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Take a photo';

  @override
  String get composeBoxGenericContentHint => 'Type a message';

  @override
  String get newDmSheetComposeButtonLabel => 'Compose';

  @override
  String get newDmSheetScreenTitle => 'New DM';

  @override
  String get newDmFabButtonLabel => 'New DM';

  @override
  String get newDmSheetSearchHintEmpty => 'Add one or more users';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Add another user…';

  @override
  String get newDmSheetNoUsersFound => 'No users found';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Message @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Message group';

  @override
  String get composeBoxSelfDmContentHint => 'Jot down something';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Message $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Preparing…';

  @override
  String get composeBoxSendTooltip => 'Send';

  @override
  String get unknownChannelName => '(unknown channel)';

  @override
  String get composeBoxTopicHintText => 'Topic';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Enter a topic (skip for “$defaultTopicName”)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Uploading $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(loading message $messageId)';
  }

  @override
  String get unknownUserName => '(unknown user)';

  @override
  String get dmsWithYourselfPageTitle => 'DMs with yourself';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'You and $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'DMs with $others';
  }

  @override
  String get emptyMessageList => 'There are no messages here.';

  @override
  String get emptyMessageListSearch => 'No search results.';

  @override
  String get messageListGroupYouWithYourself => 'Messages with yourself';

  @override
  String get contentValidationErrorTooLong =>
      'Message length shouldn\'t be greater than 10000 characters.';

  @override
  String get contentValidationErrorEmpty => 'You have nothing to send!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Please wait for the quotation to complete.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Please wait for the upload to complete.';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogContinue => 'Continue';

  @override
  String get dialogClose => 'Close';

  @override
  String get errorDialogLearnMore => 'Learn more';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Error';

  @override
  String get snackBarDetails => 'Details';

  @override
  String get lightboxCopyLinkTooltip => 'Copy link';

  @override
  String get lightboxVideoCurrentPosition => 'Current position';

  @override
  String get lightboxVideoDuration => 'Video duration';

  @override
  String get loginPageTitle => 'Log in';

  @override
  String get loginFormSubmitLabel => 'Log in';

  @override
  String get loginMethodDivider => 'OR';

  @override
  String signInWithFoo(String method) {
    return 'Sign in with $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Add an account';

  @override
  String get loginServerUrlLabel => 'Your Zulip server URL';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginErrorMissingEmail => 'Please enter your email.';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginErrorMissingPassword => 'Please enter your password.';

  @override
  String get loginUsernameLabel => 'Username';

  @override
  String get loginErrorMissingUsername => 'Please enter your username.';

  @override
  String get topicValidationErrorTooLong =>
      'Topic length shouldn\'t be greater than 60 characters.';

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Topics are required in this organization.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url is running Zulip Server $zulipVersion, which is unsupported. The minimum supported version is Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Your account at $url could not be authenticated. Please try logging in again or use another account.';
  }

  @override
  String get errorInvalidResponse => 'The server sent an invalid response.';

  @override
  String get errorNetworkRequestFailed => 'Network request failed';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Server gave malformed response; HTTP status $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Server gave malformed response; HTTP status $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Network request failed: HTTP status $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Unable to play the video.';

  @override
  String get serverUrlValidationErrorEmpty => 'Please enter a URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Please enter a valid URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Please enter the server URL, not your email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'The server URL must start with http:// or https://.';

  @override
  String get spoilerDefaultHeaderText => 'Spoiler';

  @override
  String get markAllAsReadLabel => 'Mark all messages as read';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messages',
      one: '1 message',
    );
    return 'Marked $_temp0 as read.';
  }

  @override
  String get markAsReadInProgress => 'Marking messages as read…';

  @override
  String get errorMarkAsReadFailedTitle => 'Mark as read failed';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messages',
      one: '1 message',
    );
    return 'Marked $_temp0 as unread.';
  }

  @override
  String get markAsUnreadInProgress => 'Marking messages as unread…';

  @override
  String get errorMarkAsUnreadFailedTitle => 'Mark as unread failed';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get invisibleMode => 'Invisible mode';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Error turning on invisible mode. Please try again.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Error turning off invisible mode. Please try again.';

  @override
  String get userRoleOwner => 'オーナー';

  @override
  String get userRoleAdministrator => '管理者';

  @override
  String get userRoleModerator => 'モデレータ';

  @override
  String get userRoleMember => 'メンバー';

  @override
  String get userRoleGuest => 'ゲスト';

  @override
  String get userRoleUnknown => '不明';

  @override
  String get statusButtonLabelStatusSet => 'Status';

  @override
  String get statusButtonLabelStatusUnset => 'Set status';

  @override
  String get noStatusText => 'No status text';

  @override
  String get setStatusPageTitle => 'Set status';

  @override
  String get statusClearButtonLabel => 'Clear';

  @override
  String get statusSaveButtonLabel => 'Save';

  @override
  String get statusTextHint => 'Your status';

  @override
  String get userStatusBusy => 'Busy';

  @override
  String get userStatusInAMeeting => 'In a meeting';

  @override
  String get userStatusCommuting => 'Commuting';

  @override
  String get userStatusOutSick => 'Out sick';

  @override
  String get userStatusVacationing => 'Vacationing';

  @override
  String get userStatusWorkingRemotely => 'Working remotely';

  @override
  String get userStatusAtTheOffice => 'At the office';

  @override
  String get updateStatusErrorTitle =>
      'Error updating user status. Please try again.';

  @override
  String get searchMessagesPageTitle => 'Search';

  @override
  String get searchMessagesHintText => 'Search';

  @override
  String get searchMessagesClearButtonTooltip => 'Clear';

  @override
  String get inboxPageTitle => 'Inbox';

  @override
  String get inboxEmptyPlaceholder =>
      'There are no unread messages in your inbox. Use the buttons below to view the combined feed or list of channels.';

  @override
  String get recentDmConversationsPageTitle => 'Direct messages';

  @override
  String get recentDmConversationsSectionHeader => 'Direct messages';

  @override
  String get recentDmConversationsEmptyPlaceholder =>
      'You have no direct messages yet! Why not start the conversation?';

  @override
  String get combinedFeedPageTitle => 'Combined feed';

  @override
  String get mentionsPageTitle => 'Mentions';

  @override
  String get starredMessagesPageTitle => 'Starred messages';

  @override
  String get channelsPageTitle => 'Channels';

  @override
  String get channelsEmptyPlaceholder =>
      'You are not subscribed to any channels yet.';

  @override
  String get mainMenuMyProfile => 'My profile';

  @override
  String get topicsButtonTooltip => 'Topics';

  @override
  String get channelFeedButtonTooltip => 'Channel feed';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers others',
      one: '1 other',
    );
    return '$senderFullName to you and $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Pinned';

  @override
  String get unpinnedSubscriptionsLabel => 'Unpinned';

  @override
  String get notifSelfUser => 'You';

  @override
  String get reactedEmojiSelfUser => 'You';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'You and $otherUsersCount others',
      one: 'You and 1 other',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist is typing…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist and $otherTypist are typing…';
  }

  @override
  String get manyPeopleTyping => 'Several people are typing…';

  @override
  String get wildcardMentionAll => 'all';

  @override
  String get wildcardMentionEveryone => 'everyone';

  @override
  String get wildcardMentionChannel => 'channel';

  @override
  String get wildcardMentionStream => 'stream';

  @override
  String get wildcardMentionTopic => 'topic';

  @override
  String get wildcardMentionChannelDescription => 'Notify channel';

  @override
  String get wildcardMentionStreamDescription => 'Notify stream';

  @override
  String get wildcardMentionAllDmDescription => 'Notify recipients';

  @override
  String get wildcardMentionTopicDescription => 'Notify topic';

  @override
  String get messageIsEditedLabel => 'EDITED';

  @override
  String get messageIsMovedLabel => 'MOVED';

  @override
  String get messageNotSentLabel => 'MESSAGE NOT SENT';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'THEME';

  @override
  String get themeSettingDark => 'Dark';

  @override
  String get themeSettingLight => 'Light';

  @override
  String get themeSettingSystem => 'System';

  @override
  String get openLinksWithInAppBrowser => 'Open links with in-app browser';

  @override
  String get pollWidgetQuestionMissing => 'No question.';

  @override
  String get pollWidgetOptionsMissing => 'This poll has no options yet.';

  @override
  String get initialAnchorSettingTitle => 'Open message feeds at';

  @override
  String get initialAnchorSettingDescription =>
      'You can choose whether message feeds open at your first unread message or at the newest messages.';

  @override
  String get initialAnchorSettingFirstUnreadAlways => 'First unread message';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'First unread message in conversation views, newest message elsewhere';

  @override
  String get initialAnchorSettingNewestAlways => 'Newest message';

  @override
  String get markReadOnScrollSettingTitle => 'Mark messages as read on scroll';

  @override
  String get markReadOnScrollSettingDescription =>
      'When scrolling through messages, should they automatically be marked as read?';

  @override
  String get markReadOnScrollSettingAlways => 'Always';

  @override
  String get markReadOnScrollSettingNever => 'Never';

  @override
  String get markReadOnScrollSettingConversations =>
      'Only in conversation views';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Messages will be automatically marked as read only when viewing a single topic or direct message conversation.';

  @override
  String get experimentalFeatureSettingsPageTitle => 'Experimental features';

  @override
  String get experimentalFeatureSettingsWarning =>
      'These options enable features which are still under development and not ready. They may not work, and may cause issues in other areas of the app.\n\nThe purpose of these settings is for experimentation by people working on developing Zulip.';

  @override
  String get errorNotificationOpenTitle => 'Failed to open notification';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'The account associated with this notification could not be found.';

  @override
  String get errorReactionAddingFailedTitle => 'Adding reaction failed';

  @override
  String get errorReactionRemovingFailedTitle => 'Removing reaction failed';

  @override
  String get emojiReactionsMore => 'more';

  @override
  String get emojiPickerSearchEmoji => 'Search emoji';

  @override
  String get noEarlierMessages => 'No earlier messages';

  @override
  String get revealButtonLabel => 'Reveal message';

  @override
  String get mutedUser => 'Muted user';

  @override
  String get scrollToBottomTooltip => 'Scroll to bottom';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
