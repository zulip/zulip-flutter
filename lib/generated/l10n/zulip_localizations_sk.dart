// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class ZulipLocalizationsSk extends ZulipLocalizations {
  ZulipLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get aboutPageTitle => 'O Zulipe';

  @override
  String get aboutPageAppVersion => 'Verzia apliḱácie';

  @override
  String get aboutPageOpenSourceLicenses => 'Licencia open-source';

  @override
  String get aboutPageTapToView => 'Klepnutím zobraziť';

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
  String get chooseAccountPageTitle => 'Zvoliť účet';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get switchAccountButtonTooltip => 'Zmeniť účet';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Načítavanie vášho konta na adrese $url chvílu trvá.';
  }

  @override
  String get tryAnotherAccountButton => 'Skúsiť iný účet';

  @override
  String get chooseAccountPageLogOutButton => 'Odhásiť sa';

  @override
  String get logOutConfirmationDialogTitle => 'Chcete sa odhlásiť?';

  @override
  String get logOutConfirmationDialogMessage =>
      'To use this account in the future, you will have to re-enter the URL for your organization and your account information.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Odhlásiť sa';

  @override
  String get chooseAccountButtonAddAnAccount => 'Pridať účet';

  @override
  String get navButtonAllChannels => 'All channels';

  @override
  String get allChannelsPageTitle => 'All channels';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'There are no channels you can view in this organization.';

  @override
  String get profileButtonSendDirectMessage => 'Poslať priamu správu';

  @override
  String get errorCouldNotShowUserProfile => 'Could not show user profile.';

  @override
  String get permissionsNeededTitle => 'Permissions needed';

  @override
  String get permissionsNeededOpenSettings => 'Otvoriť nastavenia';

  @override
  String get permissionsDeniedCameraAccess =>
      'To upload an image, please grant Zulip additional permissions in Settings.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'To upload files, please grant Zulip additional permissions in Settings.';

  @override
  String get actionSheetOptionSubscribe => 'Subscribe';

  @override
  String get subscribeFailedTitle => 'Failed to subscribe';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Mark channel as read';

  @override
  String get actionSheetOptionCopyChannelLink => 'Copy link to channel';

  @override
  String get actionSheetOptionListOfTopics => 'List of topics';

  @override
  String get actionSheetOptionChannelFeed => 'Channel feed';

  @override
  String get actionSheetOptionUnsubscribe => 'Unsubscribe';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Unsubscribe from $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Once you leave this channel, you will not be able to rejoin.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Unsubscribe';

  @override
  String get unsubscribeFailedTitle => 'Failed to unsubscribe';

  @override
  String get actionSheetOptionPinChannel => 'Pin to top';

  @override
  String get actionSheetOptionUnpinChannel => 'Unpin from top';

  @override
  String get errorPinChannelFailedTitle => 'Failed to pin channel';

  @override
  String get errorUnpinChannelFailedTitle => 'Failed to unpin channel';

  @override
  String get actionSheetOptionMuteTopic => 'Stlmiť tému';

  @override
  String get actionSheetOptionUnmuteTopic => 'Zrušiť ztlmenia témy';

  @override
  String get actionSheetOptionFollowTopic => 'Sledovať tému';

  @override
  String get actionSheetOptionUnfollowTopic => 'Prestať sledovať tému';

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
  String get actionSheetOptionSeeWhoReacted => 'See who reacted';

  @override
  String get seeWhoReactedSheetNoReactions => 'This message has no reactions.';

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
  String get actionSheetOptionCopyMessageText => 'Skopírovať text správy';

  @override
  String get actionSheetOptionCopyMessageLink => 'Skopírovať odkaz do správy';

  @override
  String get actionSheetOptionMarkAsUnread =>
      'Označiť ako neprečítané od tejto správy';

  @override
  String get actionSheetOptionHideMutedMessage => 'Hide muted message again';

  @override
  String get actionSheetOptionShare => 'Zdielať';

  @override
  String get actionSheetOptionQuoteMessage => 'Quote message';

  @override
  String get actionSheetOptionStarMessage => 'Ohviezdičkovať správu';

  @override
  String get actionSheetOptionUnstarMessage => 'Odhviezdičkovať správu';

  @override
  String get actionSheetOptionEditMessage => 'Edit message';

  @override
  String get actionSheetOptionDeleteMessage => 'Delete message';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Delete message?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Deleting a message permanently removes it for everyone.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Delete';

  @override
  String get errorDeleteMessageFailedTitle => 'Failed to delete message';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Mark topic as read';

  @override
  String get actionSheetOptionCopyTopicLink => 'Copy link to topic';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Niečo sa pokazilo';

  @override
  String get errorWebAuthOperationalError => 'Nastala neočakávaná chyba.';

  @override
  String get errorAccountLoggedInTitle => 'Účet je už prihlásený';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'The account $email at $server is already in your list of accounts.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Nepodarilo sa nahrať zdroj správy';

  @override
  String get errorCouldNotLoadMessages => 'Could not load messages.';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Could not access uploaded file';

  @override
  String get errorCopyingFailed => 'Kopírovanie zlyhalo';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Nepodarilo sa nahrať súbor: $filename';
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
    return '$_temp0 príliš veľký';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Nesprávny vstup';

  @override
  String get errorLoginFailedTitle => 'Nepodarilo sa prihlásiť';

  @override
  String get errorMessageNotSent => 'Správa nebola odoslaná';

  @override
  String get errorMessageEditNotSaved => 'Message not saved';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Nepodarilo sa pripojiť na server:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Could not connect';

  @override
  String get errorMessageDoesNotSeemToExist => 'Správa zrejme neexistuje.';

  @override
  String get errorQuotationFailed => 'Nepodarila sa citácia';

  @override
  String errorServerMessage(String message) {
    return 'Odozva od servera:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Chyba pri pripájaní na Zulip. Skúšam znovu…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Nepodarilo sa pripojiť na Zulip server $serverUrl. Skúsim znovu:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Chyba pri obsluhe Zulip udalosti. Pokúšam sa znovu…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Chyba obsluhy Zulip udalosti na serveri $serverUrl; skúsim znovu.\n\nChyba: $error\n\nUdalosť: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Unable to open link';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Link could not be opened: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Nepodarilo sa ztíšiť tému';

  @override
  String get errorUnmuteTopicFailed => 'Nepodarilo sa odtíšiť tému';

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
  String get dialogContinue => 'Pokračovať';

  @override
  String get dialogClose => 'Zavrieť';

  @override
  String get errorDialogLearnMore => 'Learn more';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Chyba';

  @override
  String get snackBarDetails => 'Detail';

  @override
  String get lightboxCopyLinkTooltip => 'Skopírovať odkaz';

  @override
  String get lightboxVideoCurrentPosition => 'Current position';

  @override
  String get lightboxVideoDuration => 'Video duration';

  @override
  String get loginPageTitle => 'Prihlásiť sa';

  @override
  String get loginFormSubmitLabel => 'Prihlásiť sa';

  @override
  String get loginMethodDivider => 'alebo';

  @override
  String get loginMethodDividerSemanticLabel => 'Log-in alternatives';

  @override
  String signInWithFoo(String method) {
    return 'Prihlásiť sa pomocou $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Pridať účet';

  @override
  String get loginServerUrlLabel => 'Adresa vášho Zulip servera';

  @override
  String get loginHidePassword => 'Skryť heslo';

  @override
  String get loginEmailLabel => 'Emailová adresa';

  @override
  String get loginErrorMissingEmail => 'Prosím, vložte váš email.';

  @override
  String get loginPasswordLabel => 'Heslo';

  @override
  String get loginErrorMissingPassword => 'Prosím zadaj heslo.';

  @override
  String get loginUsernameLabel => 'Prihlasovacie meno';

  @override
  String get loginErrorMissingUsername => 'Prosím zadajte prihlasovacie meno.';

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
  String get errorInvalidResponse => 'Server poslal nesprávnu odpoveď';

  @override
  String get errorNetworkRequestFailed => 'Zlyhala sieťová požiadavka';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Server doručil zle naformátovanú odozvu; HTTP status $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Server doručil zle naformátovanú odpoveď; HTTP status $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Zlyhala sieťová požiadavka: HTTP status $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Nepodarilo sa prehrať video';

  @override
  String get serverUrlValidationErrorEmpty => 'Vložte adresu.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Vložte správnu adresu.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Vložte adresu servera, nie email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'Adresa servera musí začínať s http:// or https://.';

  @override
  String get spoilerDefaultHeaderText => 'Vyzradenie';

  @override
  String get markAllAsReadLabel => 'Označiť všetky správy ako prečítané';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num správy',
      one: '1 správu',
    );
    return 'Označiť $_temp0 ako prečítanú.';
  }

  @override
  String get markAsReadInProgress => 'Označiť správy ako prečítané…';

  @override
  String get errorMarkAsReadFailedTitle =>
      'Neodarilo sa označiť správy ako prečítané';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num správ',
      one: '1 správy',
    );
    return 'Označiť $_temp0 ako neprečítané.';
  }

  @override
  String get markAsUnreadInProgress => 'Označiť správy ako neprečítané…';

  @override
  String get errorMarkAsUnreadFailedTitle =>
      'Zlyhalo označenie správ za prečítané';

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
  String get today => 'Dnes';

  @override
  String get yesterday => 'Včera';

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
  String get userRoleOwner => 'Majiteľ';

  @override
  String get userRoleAdministrator => 'Administrátor';

  @override
  String get userRoleModerator => 'Moderátor';

  @override
  String get userRoleMember => 'Člen';

  @override
  String get userRoleGuest => 'Hosť';

  @override
  String get userRoleUnknown => 'Neznáma';

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
  String get recentDmConversationsPageTitle => 'Priama správa';

  @override
  String get recentDmConversationsPageShortLabel => 'DMs';

  @override
  String get recentDmConversationsSectionHeader => 'Direct messages';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'You have no direct messages yet!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Why not start a conversation?';

  @override
  String get combinedFeedPageTitle => 'Zlúčený kanál';

  @override
  String get mentionsPageTitle => 'Spomenutia';

  @override
  String get starredMessagesPageTitle => 'Označené správy';

  @override
  String get channelsPageTitle => 'Kanály';

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
  String get mainMenuMyProfile => 'Môj profil';

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
  String get notifSelfUser => 'Ty';

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
    return '$typist píše…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist a $otherTypist píšu…';
  }

  @override
  String get manyPeopleTyping => 'Niekoľko ludí píše…';

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
  String get navBarFeedLabel => 'Feed';

  @override
  String get navBarMenuLabel => 'Menu';

  @override
  String get messageIsEditedLabel => 'UPRAVENÉ';

  @override
  String get messageIsMovedLabel => 'PRESUNUTÉ';

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
  String get pollWidgetQuestionMissing => 'Bez otázky.';

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
  String get errorNotificationOpenTitle => 'Nepodarilo sa otvoriť oznámenie';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'The account associated with this notification could not be found.';

  @override
  String get errorReactionAddingFailedTitle => 'Nepodarilo sa pridať reakciu';

  @override
  String get errorReactionRemovingFailedTitle => 'Odobranie reakcie zlyhalo';

  @override
  String get errorSharingTitle => 'Failed to share content';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'There is no account logged in. Please log in to an account and try again.';

  @override
  String get emojiReactionsMore => 'viac';

  @override
  String get emojiPickerSearchEmoji => 'Hľadať emotikon';

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
