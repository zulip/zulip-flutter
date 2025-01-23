// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class ZulipLocalizationsNb extends ZulipLocalizations {
  ZulipLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get aboutPageTitle => 'About Zulip';

  @override
  String get aboutPageAppVersion => 'App version';

  @override
  String get aboutPageOpenSourceLicenses => 'Open-source licenses';

  @override
  String get aboutPageTapToView => 'Tap to view';

  @override
  String get chooseAccountPageTitle => 'Choose account';

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
  String get logOutConfirmationDialogMessage => 'To use this account in the future, you will have to re-enter the URL for your organization and your account information.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Log out';

  @override
  String get chooseAccountButtonAddAnAccount => 'Add an account';

  @override
  String get profileButtonSendDirectMessage => 'Send direct message';

  @override
  String get permissionsNeededTitle => 'Permissions needed';

  @override
  String get permissionsNeededOpenSettings => 'Open settings';

  @override
  String get permissionsDeniedCameraAccess => 'To upload an image, please grant Zulip additional permissions in Settings.';

  @override
  String get permissionsDeniedReadExternalStorage => 'To upload files, please grant Zulip additional permissions in Settings.';

  @override
  String get actionSheetOptionMuteTopic => 'Mute topic';

  @override
  String get actionSheetOptionUnmuteTopic => 'Unmute topic';

  @override
  String get actionSheetOptionFollowTopic => 'Follow topic';

  @override
  String get actionSheetOptionUnfollowTopic => 'Unfollow topic';

  @override
  String get actionSheetOptionCopyMessageText => 'Copy message text';

  @override
  String get actionSheetOptionCopyMessageLink => 'Copy link to message';

  @override
  String get actionSheetOptionMarkAsUnread => 'Mark as unread from here';

  @override
  String get actionSheetOptionShare => 'Share';

  @override
  String get actionSheetOptionQuoteAndReply => 'Quote and reply';

  @override
  String get actionSheetOptionStarMessage => 'Star message';

  @override
  String get actionSheetOptionUnstarMessage => 'Unstar message';

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
  String get errorCouldNotFetchMessageSource => 'Could not fetch message source';

  @override
  String get errorCopyingFailed => 'Copying failed';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Failed to upload file: $filename';
  }

  @override
  String errorFilesTooLarge(int num, int maxFileUploadSizeMib, String listMessage) {
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
  String errorLoginCouldNotConnect(String url) {
    return 'Failed to connect to server:\n$url';
  }

  @override
  String get errorLoginCouldNotConnectTitle => 'Could not connect';

  @override
  String get errorMessageDoesNotSeemToExist => 'That message does not seem to exist.';

  @override
  String get errorQuotationFailed => 'Quotation failed';

  @override
  String errorServerMessage(String message) {
    return 'The server said:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort => 'Error connecting to Zulip. Retrying…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Error connecting to Zulip at $serverUrl. Will retry:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle => 'Error handling a Zulip event. Retrying connection…';

  @override
  String errorHandlingEventDetails(String serverUrl, String error, String event) {
    return 'Error handling a Zulip event from $serverUrl; will retry.\n\nError: $error\n\nEvent: $event';
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
  String get successLinkCopied => 'Link copied';

  @override
  String get successMessageTextCopied => 'Message text copied';

  @override
  String get successMessageLinkCopied => 'Message link copied';

  @override
  String get errorBannerDeactivatedDmLabel => 'You cannot send messages to deactivated users.';

  @override
  String get errorBannerCannotPostInChannelLabel => 'You do not have permission to post in this channel.';

  @override
  String get composeBoxAttachFilesTooltip => 'Attach files';

  @override
  String get composeBoxAttachMediaTooltip => 'Attach images or videos';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Take a photo';

  @override
  String get composeBoxGenericContentHint => 'Type a message';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Message @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Message group';

  @override
  String get composeBoxSelfDmContentHint => 'Jot down something';

  @override
  String composeBoxChannelContentHint(String channel, String topic) {
    return 'Message #$channel > $topic';
  }

  @override
  String get composeBoxSendTooltip => 'Send';

  @override
  String get composeBoxUnknownChannelName => '(unknown channel)';

  @override
  String get composeBoxTopicHintText => 'Topic';

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Uploading $filename…';
  }

  @override
  String get unknownUserName => '(unknown user)';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'You and $others';
  }

  @override
  String get messageListGroupYouWithYourself => 'You with yourself';

  @override
  String get contentValidationErrorTooLong => 'Message length shouldn\'t be greater than 10000 characters.';

  @override
  String get contentValidationErrorEmpty => 'You have nothing to send!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress => 'Please wait for the quotation to complete.';

  @override
  String get contentValidationErrorUploadInProgress => 'Please wait for the upload to complete.';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogContinue => 'Continue';

  @override
  String get dialogClose => 'Close';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Error';

  @override
  String get snackBarDetails => 'Details';

  @override
  String get lightboxCopyLinkTooltip => 'Copy link';

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
  String get loginServerUrlInputLabel => 'Your Zulip server URL';

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
  String get topicValidationErrorTooLong => 'Topic length shouldn\'t be greater than 60 characters.';

  @override
  String get topicValidationErrorMandatoryButEmpty => 'Topics are required in this organization.';

  @override
  String get errorInvalidResponse => 'The server sent an invalid response';

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
  String get errorVideoPlayerFailed => 'Unable to play the video';

  @override
  String get serverUrlValidationErrorEmpty => 'Please enter a URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Please enter a valid URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail => 'Please enter the server URL, not your email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme => 'The server URL must start with http:// or https://.';

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
  String get inboxPageTitle => 'Inbox';

  @override
  String get recentDmConversationsPageTitle => 'Direct messages';

  @override
  String get combinedFeedPageTitle => 'Combined feed';

  @override
  String get mentionsPageTitle => 'Mentions';

  @override
  String get starredMessagesPageTitle => 'Starred messages';

  @override
  String get channelsPageTitle => 'Channels';

  @override
  String get mainMenuMyProfile => 'My profile';

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
  String get notifSelfUser => 'You';

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
  String get messageIsEditedLabel => 'EDITED';

  @override
  String get messageIsMovedLabel => 'MOVED';

  @override
  String get pollWidgetQuestionMissing => 'No question.';

  @override
  String get pollWidgetOptionsMissing => 'This poll has no options yet.';

  @override
  String get errorNotificationOpenTitle => 'Failed to open notification';

  @override
  String get errorNotificationOpenAccountMissing => 'The account associated with this notification no longer exists.';

  @override
  String get errorReactionAddingFailedTitle => 'Adding reaction failed';

  @override
  String get errorReactionRemovingFailedTitle => 'Removing reaction failed';

  @override
  String get emojiReactionsMore => 'more';

  @override
  String get emojiPickerSearchEmoji => 'Search emoji';
}
