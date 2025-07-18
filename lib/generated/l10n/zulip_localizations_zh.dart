// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ZulipLocalizationsZh extends ZulipLocalizations {
  ZulipLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get aboutPageTitle => 'About Zulip';

  @override
  String get aboutPageAppVersion => 'App version';

  @override
  String get aboutPageOpenSourceLicenses => 'Open-source licenses';

  @override
  String get aboutPageTapToView => 'Tap to view';

  @override
  String get upgradeWelcomeDialogTitle => 'Welcome to the new Zulip app!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'You’ll find a familiar experience in a faster, sleeker package.';

  @override
  String get upgradeWelcomeDialogLinkText =>
      'Check out the announcement blog post!';

  @override
  String get upgradeWelcomeDialogDismiss => 'Let\'s go';

  @override
  String get chooseAccountPageTitle => 'Choose account';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get switchAccountButton => 'Switch account';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Your account at $url is taking a while to load.';
  }

  @override
  String get tryAnotherAccountButton => 'Try another account';

  @override
  String get chooseAccountPageLogOutButton => 'Log out';

  @override
  String get logOutConfirmationDialogTitle => 'Log out?';

  @override
  String get logOutConfirmationDialogMessage =>
      'To use this account in the future, you will have to re-enter the URL for your organization and your account information.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Log out';

  @override
  String get chooseAccountButtonAddAnAccount => 'Add an account';

  @override
  String get profileButtonSendDirectMessage => 'Send direct message';

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
  String get actionSheetOptionMarkChannelAsRead => 'Mark channel as read';

  @override
  String get actionSheetOptionListOfTopics => 'List of topics';

  @override
  String get actionSheetOptionMuteTopic => 'Mute topic';

  @override
  String get actionSheetOptionUnmuteTopic => 'Unmute topic';

  @override
  String get actionSheetOptionFollowTopic => 'Follow topic';

  @override
  String get actionSheetOptionUnfollowTopic => 'Unfollow topic';

  @override
  String get actionSheetOptionResolveTopic => 'Mark as resolved';

  @override
  String get actionSheetOptionUnresolveTopic => 'Mark as unresolved';

  @override
  String get errorResolveTopicFailedTitle => 'Failed to mark topic as resolved';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Failed to mark topic as unresolved';

  @override
  String get actionSheetOptionCopyMessageText => 'Copy message text';

  @override
  String get actionSheetOptionCopyMessageLink => 'Copy link to message';

  @override
  String get actionSheetOptionMarkAsUnread => 'Mark as unread from here';

  @override
  String get actionSheetOptionHideMutedMessage => 'Hide muted message again';

  @override
  String get actionSheetOptionShare => 'Share';

  @override
  String get actionSheetOptionQuoteMessage => 'Quote message';

  @override
  String get actionSheetOptionStarMessage => 'Star message';

  @override
  String get actionSheetOptionUnstarMessage => 'Unstar message';

  @override
  String get actionSheetOptionEditMessage => 'Edit message';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Mark topic as read';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Something went wrong';

  @override
  String get errorWebAuthOperationalError => 'An unexpected error occurred.';

  @override
  String get errorAccountLoggedInTitle => 'Account already logged in';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'The account $email at $server is already in your list of accounts.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Could not fetch message source.';

  @override
  String get errorCopyingFailed => 'Copying failed';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Failed to upload file: $filename';
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
  String get userRoleOwner => 'Owner';

  @override
  String get userRoleAdministrator => 'Administrator';

  @override
  String get userRoleModerator => 'Moderator';

  @override
  String get userRoleMember => 'Member';

  @override
  String get userRoleGuest => 'Guest';

  @override
  String get userRoleUnknown => 'Unknown';

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

/// The translations for Chinese, as used in China, using the Han script (`zh_Hans_CN`).
class ZulipLocalizationsZhHansCn extends ZulipLocalizationsZh {
  ZulipLocalizationsZhHansCn() : super('zh_Hans_CN');

  @override
  String get aboutPageTitle => '关于 Zulip';

  @override
  String get aboutPageAppVersion => '应用程序版本';

  @override
  String get aboutPageOpenSourceLicenses => '开源许可';

  @override
  String get aboutPageTapToView => '查看更多';

  @override
  String get upgradeWelcomeDialogTitle => '欢迎来到新的 Zulip 应用！';

  @override
  String get upgradeWelcomeDialogMessage => '您将会得到到更快，更流畅的体验。';

  @override
  String get upgradeWelcomeDialogLinkText => '来看看最新的公告吧！';

  @override
  String get upgradeWelcomeDialogDismiss => '开始吧';

  @override
  String get chooseAccountPageTitle => '选择账号';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get switchAccountButton => '切换账号';

  @override
  String tryAnotherAccountMessage(Object url) {
    return '您在 $url 的账号加载时间过长。';
  }

  @override
  String get tryAnotherAccountButton => '尝试另一个账号';

  @override
  String get chooseAccountPageLogOutButton => '登出';

  @override
  String get logOutConfirmationDialogTitle => '登出？';

  @override
  String get logOutConfirmationDialogMessage => '下次登入此账号时，您将需要重新输入组织网址和账号信息。';

  @override
  String get logOutConfirmationDialogConfirmButton => '登出';

  @override
  String get chooseAccountButtonAddAnAccount => '添加一个账号';

  @override
  String get profileButtonSendDirectMessage => '发送私信';

  @override
  String get errorCouldNotShowUserProfile => '无法显示用户个人资料。';

  @override
  String get permissionsNeededTitle => '需要额外权限';

  @override
  String get permissionsNeededOpenSettings => '打开设置';

  @override
  String get permissionsDeniedCameraAccess => '上传图片前，请在设置授予 Zulip 相应的权限。';

  @override
  String get permissionsDeniedReadExternalStorage =>
      '上传文件前，请在设置授予 Zulip 相应的权限。';

  @override
  String get actionSheetOptionMarkChannelAsRead => '标记频道为已读';

  @override
  String get actionSheetOptionListOfTopics => '话题列表';

  @override
  String get actionSheetOptionMuteTopic => '静音话题';

  @override
  String get actionSheetOptionUnmuteTopic => '取消静音话题';

  @override
  String get actionSheetOptionFollowTopic => '关注话题';

  @override
  String get actionSheetOptionUnfollowTopic => '取消关注话题';

  @override
  String get actionSheetOptionResolveTopic => '标记为已解决';

  @override
  String get actionSheetOptionUnresolveTopic => '标记为未解决';

  @override
  String get errorResolveTopicFailedTitle => '未能将话题标记为解决';

  @override
  String get errorUnresolveTopicFailedTitle => '未能将话题标记为未解决';

  @override
  String get actionSheetOptionCopyMessageText => '复制消息文本';

  @override
  String get actionSheetOptionCopyMessageLink => '复制消息链接';

  @override
  String get actionSheetOptionMarkAsUnread => '从这里标为未读';

  @override
  String get actionSheetOptionHideMutedMessage => '再次隐藏静音消息';

  @override
  String get actionSheetOptionShare => '分享';

  @override
  String get actionSheetOptionQuoteMessage => '引用消息';

  @override
  String get actionSheetOptionStarMessage => '添加星标消息标记';

  @override
  String get actionSheetOptionUnstarMessage => '取消星标消息标记';

  @override
  String get actionSheetOptionEditMessage => '编辑消息';

  @override
  String get actionSheetOptionMarkTopicAsRead => '将话题标为已读';

  @override
  String get errorWebAuthOperationalErrorTitle => '出现了一些问题';

  @override
  String get errorWebAuthOperationalError => '发生了未知的错误。';

  @override
  String get errorAccountLoggedInTitle => '已经登入该账号';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return '在 $server 的账号 $email 已经在您的账号列表了。';
  }

  @override
  String get errorCouldNotFetchMessageSource => '未能获取原始消息。';

  @override
  String get errorCopyingFailed => '未能复制消息文本';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return '未能上传文件：$filename';
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
      other: '$num 个您上传的文件',
    );
    return '$_temp0大小超过了该组织 $maxFileUploadSizeMib MiB 的限制：\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    return '文件过大';
  }

  @override
  String get errorLoginInvalidInputTitle => '输入的信息不正确';

  @override
  String get errorLoginFailedTitle => '未能登入';

  @override
  String get errorMessageNotSent => '未能发送消息';

  @override
  String get errorMessageEditNotSaved => '未能保存消息编辑';

  @override
  String errorLoginCouldNotConnect(String url) {
    return '未能连接到服务器：\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => '未能连接';

  @override
  String get errorMessageDoesNotSeemToExist => '找不到此消息。';

  @override
  String get errorQuotationFailed => '未能引用消息';

  @override
  String errorServerMessage(String message) {
    return '服务器：\n\n$message';
  }

  @override
  String get errorConnectingToServerShort => '未能连接到 Zulip. 重试中…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return '未能连接到在 $serverUrl 的 Zulip 服务器。即将重连：\n\n$error';
  }

  @override
  String get errorHandlingEventTitle => '处理 Zulip 事件时发生了一些问题。即将重连…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return '处理来自 $serverUrl 的 Zulip 事件时发生了一些问题。即将重连。\n\n错误：$error\n\n事件：$event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => '未能打开链接';

  @override
  String errorCouldNotOpenLink(String url) {
    return '未能打开此链接：$url';
  }

  @override
  String get errorMuteTopicFailed => '未能静音话题';

  @override
  String get errorUnmuteTopicFailed => '未能取消静音话题';

  @override
  String get errorFollowTopicFailed => '未能关注话题';

  @override
  String get errorUnfollowTopicFailed => '未能取消关注话题';

  @override
  String get errorSharingFailed => '分享失败';

  @override
  String get errorStarMessageFailedTitle => '未能添加星标消息标记';

  @override
  String get errorUnstarMessageFailedTitle => '未能取消星标消息标记';

  @override
  String get errorCouldNotEditMessageTitle => '未能编辑消息';

  @override
  String get successLinkCopied => '已复制链接';

  @override
  String get successMessageTextCopied => '已复制消息文本';

  @override
  String get successMessageLinkCopied => '已复制消息链接';

  @override
  String get errorBannerDeactivatedDmLabel => '您不能向被停用的用户发送消息。';

  @override
  String get errorBannerCannotPostInChannelLabel => '您没有足够的权限在此频道发送消息。';

  @override
  String get composeBoxBannerLabelEditMessage => '编辑消息';

  @override
  String get composeBoxBannerButtonCancel => '取消';

  @override
  String get composeBoxBannerButtonSave => '保存';

  @override
  String get editAlreadyInProgressTitle => '未能编辑消息';

  @override
  String get editAlreadyInProgressMessage => '已有正在被编辑的消息。请在其完成后重试。';

  @override
  String get savingMessageEditLabel => '保存中…';

  @override
  String get savingMessageEditFailedLabel => '编辑失败';

  @override
  String get discardDraftConfirmationDialogTitle => '放弃您正在撰写的消息？';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      '当您编辑消息时，文本框中已有的内容将会被清空。';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      '当您恢复未能发送的消息时，文本框已有的内容将会被清空。';

  @override
  String get discardDraftConfirmationDialogConfirmButton => '清空';

  @override
  String get composeBoxAttachFilesTooltip => '上传文件';

  @override
  String get composeBoxAttachMediaTooltip => '上传图片或视频';

  @override
  String get composeBoxAttachFromCameraTooltip => '拍摄照片';

  @override
  String get composeBoxGenericContentHint => '撰写消息';

  @override
  String get newDmSheetComposeButtonLabel => '撰写消息';

  @override
  String get newDmSheetScreenTitle => '发起私信';

  @override
  String get newDmFabButtonLabel => '发起私信';

  @override
  String get newDmSheetSearchHintEmpty => '添加一个或多个用户';

  @override
  String get newDmSheetSearchHintSomeSelected => '添加更多用户…';

  @override
  String get newDmSheetNoUsersFound => '没有用户';

  @override
  String composeBoxDmContentHint(String user) {
    return '发送私信给 @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => '发送私信到群组';

  @override
  String get composeBoxSelfDmContentHint => '向自己撰写消息';

  @override
  String composeBoxChannelContentHint(String destination) {
    return '发送消息到 $destination';
  }

  @override
  String get preparingEditMessageContentInput => '准备编辑消息…';

  @override
  String get composeBoxSendTooltip => '发送';

  @override
  String get unknownChannelName => '（未知频道）';

  @override
  String get composeBoxTopicHintText => '话题';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return '输入话题（默认为“$defaultTopicName”）';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return '正在上传 $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '（加载消息 $messageId）';
  }

  @override
  String get unknownUserName => '（未知用户）';

  @override
  String get dmsWithYourselfPageTitle => '与自己的私信';

  @override
  String messageListGroupYouAndOthers(String others) {
    return '您和$others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return '与$others的私信';
  }

  @override
  String get messageListGroupYouWithYourself => '与自己的私信';

  @override
  String get contentValidationErrorTooLong => '消息的长度不能超过10000个字符。';

  @override
  String get contentValidationErrorEmpty => '发送的消息不能为空！';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress => '请等待引用消息完成。';

  @override
  String get contentValidationErrorUploadInProgress => '请等待上传完成。';

  @override
  String get dialogCancel => '取消';

  @override
  String get dialogContinue => '继续';

  @override
  String get dialogClose => '关闭';

  @override
  String get errorDialogLearnMore => '更多信息';

  @override
  String get errorDialogContinue => '好的';

  @override
  String get errorDialogTitle => '错误';

  @override
  String get snackBarDetails => '详情';

  @override
  String get lightboxCopyLinkTooltip => '复制链接';

  @override
  String get lightboxVideoCurrentPosition => '当前进度';

  @override
  String get lightboxVideoDuration => '视频时长';

  @override
  String get loginPageTitle => '登入';

  @override
  String get loginFormSubmitLabel => '登入';

  @override
  String get loginMethodDivider => '或';

  @override
  String signInWithFoo(String method) {
    return '使用$method登入';
  }

  @override
  String get loginAddAnAccountPageTitle => '添加账号';

  @override
  String get loginServerUrlLabel => 'Zulip 服务器网址';

  @override
  String get loginHidePassword => '隐藏密码';

  @override
  String get loginEmailLabel => '电子邮箱地址';

  @override
  String get loginErrorMissingEmail => '请输入电子邮箱地址。';

  @override
  String get loginPasswordLabel => '密码';

  @override
  String get loginErrorMissingPassword => '请输入密码。';

  @override
  String get loginUsernameLabel => '用户名';

  @override
  String get loginErrorMissingUsername => '请输入用户名。';

  @override
  String get topicValidationErrorTooLong => '话题长度不应该超过 60 个字符。';

  @override
  String get topicValidationErrorMandatoryButEmpty => '话题在该组织为必填项。';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url 运行的 Zulip 服务器版本 $zulipVersion 过低。该客户端只支持 $minSupportedZulipVersion 及以后的服务器版本。';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return '您在 $url 的账号无法被登入。请重试或者使用另外的账号。';
  }

  @override
  String get errorInvalidResponse => '服务器的回复不合法。';

  @override
  String get errorNetworkRequestFailed => '网络请求失败';

  @override
  String errorMalformedResponse(int httpStatus) {
    return '服务器的回复不合法；HTTP 状态码 $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return '服务器的回复不合法；HTTP 状态码 $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return '网络请求失败；HTTP 状态码 $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => '未能播放视频。';

  @override
  String get serverUrlValidationErrorEmpty => '请输入网址。';

  @override
  String get serverUrlValidationErrorInvalidUrl => '请输入正确的网址。';

  @override
  String get serverUrlValidationErrorNoUseEmail => '请输入服务器网址，而不是您的电子邮件。';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      '服务器网址必须以 http:// 或 https:// 开头。';

  @override
  String get spoilerDefaultHeaderText => '剧透';

  @override
  String get markAllAsReadLabel => '将所有消息标为已读';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num 条消息',
    );
    return '已将 $_temp0标为已读。';
  }

  @override
  String get markAsReadInProgress => '正在将消息标为已读…';

  @override
  String get errorMarkAsReadFailedTitle => '未能将消息标为已读';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num 条消息',
    );
    return '已将 $_temp0标为未读。';
  }

  @override
  String get markAsUnreadInProgress => '正在将消息标为未读…';

  @override
  String get errorMarkAsUnreadFailedTitle => '未能将消息标为未读';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get userRoleOwner => '所有者';

  @override
  String get userRoleAdministrator => '管理员';

  @override
  String get userRoleModerator => '版主';

  @override
  String get userRoleMember => '成员';

  @override
  String get userRoleGuest => '访客';

  @override
  String get userRoleUnknown => '未知';

  @override
  String get inboxPageTitle => '收件箱';

  @override
  String get inboxEmptyPlaceholder => '您的收件箱中没有未读消息。您可以通过底部导航栏访问综合消息或者频道列表。';

  @override
  String get recentDmConversationsPageTitle => '私信';

  @override
  String get recentDmConversationsSectionHeader => '私信';

  @override
  String get recentDmConversationsEmptyPlaceholder => '您还没有任何私信消息！何不开启一个新对话？';

  @override
  String get combinedFeedPageTitle => '综合消息';

  @override
  String get mentionsPageTitle => '被提及消息';

  @override
  String get starredMessagesPageTitle => '星标消息';

  @override
  String get channelsPageTitle => '频道';

  @override
  String get channelsEmptyPlaceholder => '您还没有订阅任何频道。';

  @override
  String get mainMenuMyProfile => '个人资料';

  @override
  String get topicsButtonTooltip => '话题';

  @override
  String get channelFeedButtonTooltip => '频道订阅';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers 个用户',
    );
    return '$senderFullName向您和其他 $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => '置顶';

  @override
  String get unpinnedSubscriptionsLabel => '未置顶';

  @override
  String get notifSelfUser => '您';

  @override
  String get reactedEmojiSelfUser => '您';

  @override
  String onePersonTyping(String typist) {
    return '$typist正在输入…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist和$otherTypist正在输入…';
  }

  @override
  String get manyPeopleTyping => '多个用户正在输入…';

  @override
  String get wildcardMentionAll => '所有人';

  @override
  String get wildcardMentionEveryone => '所有人';

  @override
  String get wildcardMentionChannel => '频道';

  @override
  String get wildcardMentionStream => '频道';

  @override
  String get wildcardMentionTopic => '话题';

  @override
  String get wildcardMentionChannelDescription => '通知频道';

  @override
  String get wildcardMentionStreamDescription => '通知频道';

  @override
  String get wildcardMentionAllDmDescription => '通知收件人';

  @override
  String get wildcardMentionTopicDescription => '通知话题';

  @override
  String get messageIsEditedLabel => '已编辑';

  @override
  String get messageIsMovedLabel => '已移动';

  @override
  String get messageNotSentLabel => '消息未发送';

  @override
  String pollVoterNames(String voterNames) {
    return '（$voterNames）';
  }

  @override
  String get themeSettingTitle => '主题';

  @override
  String get themeSettingDark => '暗色';

  @override
  String get themeSettingLight => '浅色';

  @override
  String get themeSettingSystem => '系统';

  @override
  String get openLinksWithInAppBrowser => '使用内置浏览器打开链接';

  @override
  String get pollWidgetQuestionMissing => '无问题。';

  @override
  String get pollWidgetOptionsMissing => '该投票还没有任何选项。';

  @override
  String get initialAnchorSettingTitle => '设置消息起始位置于';

  @override
  String get initialAnchorSettingDescription => '您可以将消息的起始位置设置为第一条未读消息或者最新消息。';

  @override
  String get initialAnchorSettingFirstUnreadAlways => '第一条未读消息';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      '在单个话题或私信的第一条未读消息；在其他情况下的最新消息';

  @override
  String get initialAnchorSettingNewestAlways => '最新消息';

  @override
  String get markReadOnScrollSettingTitle => '滑动时将消息标为已读';

  @override
  String get markReadOnScrollSettingDescription => '在滑动浏览消息时，是否自动将它们标记为已读？';

  @override
  String get markReadOnScrollSettingAlways => '总是';

  @override
  String get markReadOnScrollSettingNever => '从不';

  @override
  String get markReadOnScrollSettingConversations => '只在对话视图';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      '只将在同一个话题或私聊中的消息自动标记为已读。';

  @override
  String get experimentalFeatureSettingsPageTitle => '实验功能';

  @override
  String get experimentalFeatureSettingsWarning =>
      '以下选项能够启用开发中的功能。它们暂不完善，并可能造成其他的一些问题。\n\n这些选项的目的是为了帮助开发者进行实验。';

  @override
  String get errorNotificationOpenTitle => '未能打开消息提醒';

  @override
  String get errorNotificationOpenAccountNotFound => '未能找到关联该消息提醒的账号。';

  @override
  String get errorReactionAddingFailedTitle => '未能添加表情符号';

  @override
  String get errorReactionRemovingFailedTitle => '未能移除表情符号';

  @override
  String get emojiReactionsMore => '更多';

  @override
  String get emojiPickerSearchEmoji => '搜索表情符号';

  @override
  String get noEarlierMessages => '没有更早的消息了';

  @override
  String get revealButtonLabel => '显示静音用户发送的消息';

  @override
  String get mutedUser => '静音用户';

  @override
  String get scrollToBottomTooltip => '拖动到最底';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}

/// The translations for Chinese, as used in Taiwan, using the Han script (`zh_Hant_TW`).
class ZulipLocalizationsZhHantTw extends ZulipLocalizationsZh {
  ZulipLocalizationsZhHantTw() : super('zh_Hant_TW');

  @override
  String get aboutPageTitle => '關於 Zulip';

  @override
  String get aboutPageAppVersion => 'App 版本';

  @override
  String get aboutPageOpenSourceLicenses => '開源授權條款';

  @override
  String get aboutPageTapToView => '點選查看';

  @override
  String get upgradeWelcomeDialogTitle => '歡迎使用新 Zulip 應用程式！';

  @override
  String get chooseAccountPageTitle => '選取帳號';

  @override
  String get settingsPageTitle => '設定';

  @override
  String get switchAccountButton => '切換帳號';

  @override
  String tryAnotherAccountMessage(Object url) {
    return '你在 $url 的帳號載入的比較久';
  }

  @override
  String get tryAnotherAccountButton => '請嘗試別的帳號';

  @override
  String get chooseAccountPageLogOutButton => '登出';

  @override
  String get logOutConfirmationDialogTitle => '登出？';

  @override
  String get logOutConfirmationDialogConfirmButton => '登出';

  @override
  String get chooseAccountButtonAddAnAccount => '增添帳號';

  @override
  String get profileButtonSendDirectMessage => '發送私訊';

  @override
  String get permissionsNeededTitle => '需要的權限';

  @override
  String get permissionsNeededOpenSettings => '開啟設定';

  @override
  String get actionSheetOptionMarkChannelAsRead => '標註頻道為已讀';

  @override
  String get actionSheetOptionListOfTopics => '話題列表';

  @override
  String get actionSheetOptionMuteTopic => '靜音話題';

  @override
  String get actionSheetOptionUnmuteTopic => '取消靜音話題';

  @override
  String get actionSheetOptionFollowTopic => '跟隨話題';

  @override
  String get actionSheetOptionUnfollowTopic => '取消跟隨話題';

  @override
  String get actionSheetOptionResolveTopic => '標註為已解決';

  @override
  String get actionSheetOptionUnresolveTopic => '標註為未解決';

  @override
  String get errorResolveTopicFailedTitle => '無法標註話題為已解決';

  @override
  String get errorUnresolveTopicFailedTitle => '無法標註話題為未解決';

  @override
  String get actionSheetOptionCopyMessageText => '複製訊息文字';

  @override
  String get actionSheetOptionCopyMessageLink => '複製訊息連結';

  @override
  String get actionSheetOptionMarkAsUnread => '從這裡開始標註為未讀';

  @override
  String get actionSheetOptionHideMutedMessage => '再次隱藏已靜音的話題';

  @override
  String get actionSheetOptionShare => '分享';

  @override
  String get actionSheetOptionQuoteMessage => '引述訊息';

  @override
  String get actionSheetOptionStarMessage => '收藏訊息';

  @override
  String get actionSheetOptionUnstarMessage => '取消收藏訊息';

  @override
  String get actionSheetOptionEditMessage => '編輯訊息';

  @override
  String get actionSheetOptionMarkTopicAsRead => '標註話題為已讀';

  @override
  String get errorWebAuthOperationalErrorTitle => '出錯了';

  @override
  String get errorWebAuthOperationalError => '出現了意外的錯誤。';

  @override
  String get errorAccountLoggedInTitle => '帳號已經登入了';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return '在 $server 的帳號 $email 已經存在帳號清單中。';
  }

  @override
  String get errorCopyingFailed => '複製失敗';

  @override
  String get errorLoginFailedTitle => '登入失敗';

  @override
  String errorLoginCouldNotConnect(String url) {
    return '無法連線到伺服器:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => '無法連線';

  @override
  String get errorMessageDoesNotSeemToExist => '該訊息似乎不存在。';

  @override
  String get errorQuotationFailed => '引述失敗';

  @override
  String get errorCouldNotOpenLinkTitle => '無法開啟連結';

  @override
  String errorCouldNotOpenLink(String url) {
    return '無法開啟連結: $url';
  }

  @override
  String get errorMuteTopicFailed => '無法靜音話題';

  @override
  String get errorUnmuteTopicFailed => '無法取消靜音話題';

  @override
  String get errorFollowTopicFailed => '無法跟隨話題';

  @override
  String get errorUnfollowTopicFailed => '無法取消跟隨話題';

  @override
  String get errorSharingFailed => '分享失敗。';

  @override
  String get errorStarMessageFailedTitle => '無法收藏訊息';

  @override
  String get errorUnstarMessageFailedTitle => '無法取消收藏訊息';

  @override
  String get errorCouldNotEditMessageTitle => '無法編輯訊息';

  @override
  String get successLinkCopied => '已複製連結';

  @override
  String get successMessageTextCopied => '已複製訊息文字';

  @override
  String get successMessageLinkCopied => '已複製訊息連結';

  @override
  String get composeBoxBannerLabelEditMessage => '編輯訊息';

  @override
  String get composeBoxBannerButtonCancel => '取消';

  @override
  String get editAlreadyInProgressTitle => '無法編輯訊息';

  @override
  String get composeBoxAttachFilesTooltip => '附加檔案';

  @override
  String get composeBoxAttachMediaTooltip => '附加圖片或影片';

  @override
  String get newDmSheetScreenTitle => '新增私訊';

  @override
  String get newDmFabButtonLabel => '新增私訊';

  @override
  String get newDmSheetSearchHintEmpty => '增添一個或多個使用者';

  @override
  String get newDmSheetSearchHintSomeSelected => '增添其他使用者…';

  @override
  String composeBoxDmContentHint(String user) {
    return '訊息 @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => '訊息群組';

  @override
  String composeBoxChannelContentHint(String destination) {
    return '訊息 $destination';
  }

  @override
  String get composeBoxTopicHintText => '話題';

  @override
  String composeBoxUploadingFilename(String filename) {
    return '正在上傳 $filename…';
  }

  @override
  String get contentValidationErrorQuoteAndReplyInProgress => '請等待引述完成。';

  @override
  String get contentValidationErrorUploadInProgress => '請等待上傳完成。';

  @override
  String get dialogCancel => '取消';

  @override
  String get dialogContinue => '繼續';

  @override
  String get dialogClose => '關閉';

  @override
  String get errorDialogLearnMore => '了解更多';

  @override
  String get errorDialogTitle => '錯誤';

  @override
  String get lightboxCopyLinkTooltip => '複製連結';

  @override
  String get loginPageTitle => '登入';

  @override
  String get loginFormSubmitLabel => '登入';

  @override
  String signInWithFoo(String method) {
    return '使用 $method 登入';
  }

  @override
  String get loginAddAnAccountPageTitle => '增添帳號';

  @override
  String get loginServerUrlLabel => '您的 Zulip 伺服器網址';

  @override
  String get loginHidePassword => '隱藏密碼';

  @override
  String get loginEmailLabel => '電子郵件地址';

  @override
  String get loginErrorMissingEmail => '請輸入您的電子郵件地址。';

  @override
  String get loginPasswordLabel => '密碼';

  @override
  String get loginErrorMissingPassword => '請輸入您的密碼。';

  @override
  String get loginUsernameLabel => '使用者名稱';

  @override
  String get loginErrorMissingUsername => '請輸入您的使用者名稱。';

  @override
  String get errorInvalidResponse => '伺服器傳送了無效的請求。';

  @override
  String get errorNetworkRequestFailed => '網路請求失敗';

  @override
  String get errorVideoPlayerFailed => '無法播放影片。';

  @override
  String get serverUrlValidationErrorEmpty => '請輸入網址。';

  @override
  String get serverUrlValidationErrorInvalidUrl => '請輸入有效的網址。';

  @override
  String get serverUrlValidationErrorNoUseEmail => '請輸入伺服器網址，而非您的電子郵件。';

  @override
  String get spoilerDefaultHeaderText => '劇透';

  @override
  String get markAllAsReadLabel => '標註所有訊息為已讀';

  @override
  String get markAsUnreadInProgress => '正在標註訊息為未讀…';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get userRoleOwner => '擁有者';

  @override
  String get userRoleAdministrator => '管理員';

  @override
  String get userRoleModerator => '版主';

  @override
  String get userRoleMember => '成員';

  @override
  String get userRoleGuest => '訪客';

  @override
  String get searchMessagesPageTitle => '搜尋';

  @override
  String get searchMessagesHintText => '搜尋';

  @override
  String get searchMessagesClearButtonTooltip => '清除';

  @override
  String get inboxPageTitle => '收件匣';

  @override
  String get recentDmConversationsPageTitle => '私人訊息';

  @override
  String get recentDmConversationsSectionHeader => '私人訊息';

  @override
  String get combinedFeedPageTitle => '綜合饋給';

  @override
  String get mentionsPageTitle => '提及';

  @override
  String get channelsPageTitle => '頻道';

  @override
  String get topicsButtonTooltip => '話題';

  @override
  String get channelFeedButtonTooltip => '頻道饋給';

  @override
  String get pinnedSubscriptionsLabel => '已釘選';

  @override
  String get unpinnedSubscriptionsLabel => '未釘選';

  @override
  String get wildcardMentionChannel => 'channel';

  @override
  String get wildcardMentionTopic => 'topic';

  @override
  String get wildcardMentionChannelDescription => '通知頻道';

  @override
  String get wildcardMentionTopicDescription => '通知話題';

  @override
  String get themeSettingTitle => '主題';

  @override
  String get themeSettingDark => '深色主題';

  @override
  String get themeSettingLight => '淺色主題';

  @override
  String get themeSettingSystem => '系統主題';

  @override
  String get initialAnchorSettingFirstUnreadAlways => '第一則未讀訊息';

  @override
  String get initialAnchorSettingNewestAlways => '最新訊息';

  @override
  String get experimentalFeatureSettingsPageTitle => '實驗性功能';

  @override
  String get errorNotificationOpenTitle => '無法開啟通知';

  @override
  String get emojiReactionsMore => '更多';

  @override
  String get emojiPickerSearchEmoji => '搜尋表情符號';

  @override
  String get mutedUser => '已靜音的使用者';
}
