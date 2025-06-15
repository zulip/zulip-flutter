// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class ZulipLocalizationsIt extends ZulipLocalizations {
  ZulipLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get aboutPageTitle => 'Su Zulip';

  @override
  String get aboutPageAppVersion => 'Versione app';

  @override
  String get aboutPageOpenSourceLicenses => 'Licenze open-source';

  @override
  String get aboutPageTapToView => 'Tap per visualizzare';

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
  String get chooseAccountPageTitle => 'Scegli account';

  @override
  String get settingsPageTitle => 'Impostazioni';

  @override
  String get switchAccountButton => 'Cambia account';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Il caricamento dell\'account su $url sta richiedendo un po\' di tempo.';
  }

  @override
  String get tryAnotherAccountButton => 'Prova un altro account';

  @override
  String get chooseAccountPageLogOutButton => 'Esci';

  @override
  String get logOutConfirmationDialogTitle => 'Disconnettersi?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Per utilizzare questo account in futuro, bisognerà reinserire l\'URL della propria organizzazione e le informazioni del proprio account.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Esci';

  @override
  String get chooseAccountButtonAddAnAccount => 'Aggiungi un account';

  @override
  String get profileButtonSendDirectMessage => 'Invia un messaggio diretto';

  @override
  String get errorCouldNotShowUserProfile =>
      'Impossibile mostrare il profilo utente.';

  @override
  String get permissionsNeededTitle => 'Permessi necessari';

  @override
  String get permissionsNeededOpenSettings => 'Apri le impostazioni';

  @override
  String get permissionsDeniedCameraAccess =>
      'Per caricare un\'immagine, bisogna concedere a Zulip autorizzazioni aggiuntive nelle Impostazioni.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Per caricare file, bisogna concedere a Zulip autorizzazioni aggiuntive nelle Impostazioni.';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Segna il canale come letto';

  @override
  String get actionSheetOptionListOfTopics => 'Elenco degli argomenti';

  @override
  String get actionSheetOptionMuteTopic => 'Silenzia argomento';

  @override
  String get actionSheetOptionUnmuteTopic => 'Riattiva argomento';

  @override
  String get actionSheetOptionFollowTopic => 'Segui argomento';

  @override
  String get actionSheetOptionUnfollowTopic => 'Non seguire più l\'argomento';

  @override
  String get actionSheetOptionResolveTopic => 'Segna come risolto';

  @override
  String get actionSheetOptionUnresolveTopic => 'Segna come irrisolto';

  @override
  String get errorResolveTopicFailedTitle =>
      'Impossibile contrassegnare l\'argomento come risolto';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Impossibile contrassegnare l\'argomento come irrisolto';

  @override
  String get actionSheetOptionCopyMessageText => 'Copia il testo del messaggio';

  @override
  String get actionSheetOptionCopyMessageLink =>
      'Copia il collegamento al messaggio';

  @override
  String get actionSheetOptionMarkAsUnread => 'Segna come non letto da qui';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Nascondi nuovamente il messaggio disattivato';

  @override
  String get actionSheetOptionShare => 'Condividi';

  @override
  String get actionSheetOptionQuoteMessage => 'Quote message';

  @override
  String get actionSheetOptionStarMessage => 'Metti una stella al messaggio';

  @override
  String get actionSheetOptionUnstarMessage => 'Togli la stella dal messaggio';

  @override
  String get actionSheetOptionEditMessage => 'Modifica messaggio';

  @override
  String get actionSheetOptionMarkTopicAsRead =>
      'Segna l\'argomento come letto';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Qualcosa è andato storto';

  @override
  String get errorWebAuthOperationalError =>
      'Si è verificato un errore imprevisto.';

  @override
  String get errorAccountLoggedInTitle => 'Account già registrato';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'L\'account $email su $server è già presente nell\'elenco account.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Impossibile recuperare l\'origine del messaggio.';

  @override
  String get errorCopyingFailed => 'Copia non riuscita';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Impossibile caricare il file: $filename';
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
  String get errorLoginInvalidInputTitle => 'Ingresso non valido';

  @override
  String get errorLoginFailedTitle => 'Accesso non riuscito';

  @override
  String get errorMessageNotSent => 'Messaggio non inviato';

  @override
  String get errorMessageEditNotSaved => 'Messaggio non salvato';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Impossibile connettersi al server:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Impossibile connettersi';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Quel messaggio sembra non esistere.';

  @override
  String get errorQuotationFailed => 'Citazione non riuscita';

  @override
  String errorServerMessage(String message) {
    return 'Il server ha detto:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Errore di connessione a Zulip. Nuovo tentativo…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Errore durante la connessione a Zulip su $serverUrl. Verrà effettuato un nuovo tentativo:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Errore nella gestione di un evento Zulip. Nuovo tentativo di connessione…';

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
  String get topicsButtonLabel => 'TOPICS';

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
      'First unread message in single conversations, newest message elsewhere';

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
