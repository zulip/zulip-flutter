// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class ZulipLocalizationsHe extends ZulipLocalizations {
  ZulipLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get aboutPageTitle => 'About Zulip';

  @override
  String get aboutPageAppVersion => 'גרסת ישום';

  @override
  String get aboutPageOpenSourceLicenses => 'רישיונות קוד פתוח';

  @override
  String get aboutPageTapToView => 'הקש כדי להציג';

  @override
  String get upgradeWelcomeDialogTitle =>
      'ברוכים הבאים לאפליקציית Zulip החדשה!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'תוכלו למצוא חוויה מוכרת בחבילה מהירה וחלקה יותר.';

  @override
  String get upgradeWelcomeDialogLinkText => 'עיין בפוסט בבלוג ההכרזה!';

  @override
  String get upgradeWelcomeDialogDismiss => 'בא נלך';

  @override
  String get chooseAccountPageTitle => 'בחר חשבון';

  @override
  String get settingsPageTitle => 'הגדרות';

  @override
  String get switchAccountButtonTooltip => 'החלף חשבון';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'החשבון שלך ב- $url לוקח זמן לטעון.';
  }

  @override
  String get tryAnotherAccountButton => 'נסה חשבון אחר';

  @override
  String get chooseAccountPageLogOutButton => 'התנתק';

  @override
  String get logOutConfirmationDialogTitle => 'להתנתק?';

  @override
  String get logOutConfirmationDialogMessage =>
      'כדי להשתמש בחשבון זה בעתיד, יהיה עליך להכניס מחדש את כתובת האתר של הארגון שלך ואת פרטי החשבון שלך.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'התנתק';

  @override
  String get chooseAccountButtonAddAnAccount => 'הוספת חשבון';

  @override
  String get navButtonAllChannels => 'כל הערוצים';

  @override
  String get allChannelsPageTitle => 'כל הערוצים';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'אין ערוצים שתוכלו להציג בארגון זה.';

  @override
  String get profileButtonSendDirectMessage => 'שלח הודעה ישירה';

  @override
  String get errorCouldNotShowUserProfile => 'לא ניתן להציג פרופיל משתמש.';

  @override
  String get permissionsNeededTitle => 'Permissions needed';

  @override
  String get permissionsNeededOpenSettings => 'פתח הגדרות';

  @override
  String get permissionsDeniedCameraAccess =>
      'To upload an image, please grant Zulip additional permissions in Settings.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'To upload files, please grant Zulip additional permissions in Settings.';

  @override
  String get actionSheetOptionSubscribe => 'הרשם';

  @override
  String get subscribeFailedTitle => 'הרישום נכשל';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Mark channel as read';

  @override
  String get actionSheetOptionCopyChannelLink => 'Copy link to channel';

  @override
  String get actionSheetOptionListOfTopics => 'List of topics';

  @override
  String get actionSheetOptionChannelFeed => 'Channel feed';

  @override
  String get actionSheetOptionUnsubscribe => 'בטל רישום';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'בטל רישום ל־$channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'לאחר היציאה מהערוץ, לא תתאפשר הצטרפות מחדש.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'בטל רישום';

  @override
  String get unsubscribeFailedTitle => 'ביטול הרישום נכשל';

  @override
  String get actionSheetOptionPinChannel => 'Pin to top';

  @override
  String get actionSheetOptionUnpinChannel => 'Unpin from top';

  @override
  String get errorPinChannelFailedTitle => 'Failed to pin channel';

  @override
  String get errorUnpinChannelFailedTitle => 'Failed to unpin channel';

  @override
  String get actionSheetOptionMuteTopic => 'השתקת נושא';

  @override
  String get actionSheetOptionUnmuteTopic => 'בטל את ההשתקה של נושא';

  @override
  String get actionSheetOptionFollowTopic => 'עקוב אחר הנושא';

  @override
  String get actionSheetOptionUnfollowTopic => 'בטל מעקב אחר נושא';

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
  String get actionSheetOptionSeeWhoReacted => 'הצג מי הגיב';

  @override
  String get seeWhoReactedSheetNoReactions => 'להודעה זו אין תגובות.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Emoji reactions ($num total)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num votes',
      one: '1 vote',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Votes for $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts => 'View read receipts';

  @override
  String get actionSheetReadReceipts => 'Read receipts';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This message has been <z-link>read</z-link> by $count people:',
      one: 'This message has been <z-link>read</z-link> by $count person:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'No one has read this message yet.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Failed to load read receipts.';

  @override
  String get actionSheetOptionCopyMessageText => 'Copy message text';

  @override
  String get actionSheetOptionCopyMessageLink => 'Copy link to message';

  @override
  String get actionSheetOptionMarkAsUnread => 'Mark as unread from here';

  @override
  String get actionSheetOptionHideMutedMessage => 'Hide muted message again';

  @override
  String get actionSheetOptionShare => 'שתף';

  @override
  String get actionSheetOptionQuoteMessage => 'צטט הודעה';

  @override
  String get actionSheetOptionStarMessage => 'סמן הודעה בכוכב';

  @override
  String get actionSheetOptionUnstarMessage => 'בטל את סימון הודעה';

  @override
  String get actionSheetOptionEditMessage => 'ערוך הודעה';

  @override
  String get actionSheetOptionDeleteMessage => 'מחק הודעה';

  @override
  String get deleteMessageConfirmationDialogTitle => 'האם למחוק את ההודעה?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'מחיקת הודעה מסירה את ההודעה עבור כולם לאלתר.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'מחק';

  @override
  String get errorDeleteMessageFailedTitle => 'מחיקת ההודעה נכשלה';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Mark topic as read';

  @override
  String get actionSheetOptionCopyTopicLink => 'Copy link to topic';

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
  String get errorCouldNotAccessUploadedFileTitle =>
      'Could not access uploaded file';

  @override
  String get errorCopyingFailed => 'העתקה נכשלה';

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
  String get errorLoginInvalidInputTitle => 'קלט לא תקין';

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
  String get composeBoxBannerLabelDeactivatedDmRecipient =>
      'You cannot send messages to deactivated users.';

  @override
  String get composeBoxBannerLabelUnknownDmRecipient =>
      'You cannot send messages to unknown users.';

  @override
  String get composeBoxBannerLabelCannotSendUnspecifiedReason =>
      'You cannot send messages here.';

  @override
  String get composeBoxBannerLabelCannotSendInChannel =>
      'You do not have permission to post in this channel.';

  @override
  String get composeBoxBannerLabelUnsubscribed =>
      'Replies to your messages will not appear automatically.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'New messages will not appear automatically.';

  @override
  String get composeBoxBannerButtonRefresh => 'Refresh';

  @override
  String get composeBoxBannerButtonSubscribe => 'Subscribe';

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
  String get composeBoxSelfDmContentHint => 'Write yourself a note';

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
  String get emptyMessageListCombinedFeed =>
      'There are no messages in your combined feed.';

  @override
  String get emptyMessageListChannelWithoutContentAccess =>
      'You don’t have <z-link>content access</z-link> to this channel.';

  @override
  String get emptyMessageListChannelUnavailable =>
      'This channel doesn’t exist, or you are not allowed to view it.';

  @override
  String get emptyMessageListSelfDmHeader =>
      'You have not sent any direct messages to yourself yet!';

  @override
  String get emptyMessageListSelfDmMessage =>
      'Use this space for personal notes, or to test out Zulip features.';

  @override
  String emptyMessageListDm(String person) {
    return 'You have no direct messages with $person yet.';
  }

  @override
  String emptyMessageListDmDeactivatedUser(String person) {
    return 'You have no direct messages with $person.';
  }

  @override
  String get emptyMessageListDmUnknownUser =>
      'You have no direct messages with this user.';

  @override
  String get emptyMessageListGroupDm =>
      'You have no direct messages with these users yet.';

  @override
  String get emptyMessageListGroupDmDeactivatedUser =>
      'You have no direct messages with these users.';

  @override
  String get emptyMessageListDmStartConversation =>
      'Why not start the conversation?';

  @override
  String get emptyMessageListMentionsHeader =>
      'This view will show messages where you are <z-link>mentioned</z-link>.';

  @override
  String get emptyMessageListMentionsMessage =>
      'To call attention to a message, you can mention a user, a group, topic participants, or all subscribers to a channel. Type @ in the compose box, and choose who you’d like to mention from the list of suggestions.';

  @override
  String get emptyMessageListStarredHeader => 'You have no starred messages.';

  @override
  String emptyMessageListStarredMessage(String button) {
    return '<z-link>Starring</z-link> is a good way to keep track of important messages, such as tasks you need to go back to, or useful references. To star a message, long-press it and tap “$button.”';
  }

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
  String get loginMethodDividerSemanticLabel => 'Log-in alternatives';

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
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength characters',
      one: '1 character',
    );
    return 'Topic length shouldn\'t be greater than $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Topics are required in this organization.';

  @override
  String get errorContentNotInsertedTitle => 'Content not inserted';

  @override
  String get errorContentToInsertIsEmpty =>
      'The file to be inserted is empty or cannot be accessed.';

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
  String markAllAsReadConfirmationDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mark $count+ messages as read?',
      one: 'Mark $count+ messages as read?',
    );
    return '$_temp0';
  }

  @override
  String get markAllAsReadConfirmationDialogTitleNoCount =>
      'Mark messages as read?';

  @override
  String get markAllAsReadConfirmationDialogMessage =>
      'Messages in multiple conversations may be affected.';

  @override
  String get markAllAsReadConfirmationDialogConfirmButton => 'Mark as read';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get userActiveNow => 'Active now';

  @override
  String get userIdle => 'Idle';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Active $_temp0 ago';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return 'Active $_temp0 ago';
  }

  @override
  String get userActiveYesterday => 'Active yesterday';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Active $_temp0 ago';
  }

  @override
  String userActiveDate(String date) {
    return 'Active $date';
  }

  @override
  String get userNotActiveInYear => 'Not active in the last year';

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
  String get inboxEmptyPlaceholderHeader =>
      'There are no unread messages in your inbox.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Use the buttons below to view the combined feed or list of channels.';

  @override
  String get recentDmConversationsPageTitle => 'Direct messages';

  @override
  String get recentDmConversationsSectionHeader => 'Direct messages';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'You have no direct messages yet!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Why not start a conversation?';

  @override
  String get combinedFeedPageTitle => 'Combined feed';

  @override
  String get mentionsPageTitle => 'Mentions';

  @override
  String get starredMessagesPageTitle => 'Starred messages';

  @override
  String get channelsPageTitle => 'Channels';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'You’re not subscribed to any channels yet.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Try going to <z-link>$allChannelsPageTitle</z-link> and joining some of them.';
  }

  @override
  String get shareChooseAccountModalTitle => 'Choose an account';

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
  String get reactionChipsLabel => 'Reactions';

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
  String get navBarMenuLabel => 'Menu';

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
  String get errorSharingTitle => 'Failed to share content';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'There is no account logged in. Please log in to an account and try again.';

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

  @override
  String get topicListEmptyPlaceholderHeader => 'There are no topics here yet.';
}
