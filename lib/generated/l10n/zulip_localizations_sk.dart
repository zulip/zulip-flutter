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
  String get chooseAccountPageTitle => 'Zvoliť účet';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get switchAccountButton => 'Zmeniť účet';

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
  String get actionSheetOptionMarkChannelAsRead => 'Mark channel as read';

  @override
  String get actionSheetOptionListOfTopics => 'List of topics';

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
  String get actionSheetOptionMarkTopicAsRead => 'Mark topic as read';

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
  String get today => 'Dnes';

  @override
  String get yesterday => 'Včera';

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
  String get inboxPageTitle => 'Inbox';

  @override
  String get inboxEmptyPlaceholder =>
      'There are no unread messages in your inbox. Use the buttons below to view the combined feed or list of channels.';

  @override
  String get recentDmConversationsPageTitle => 'Priama správa';

  @override
  String get recentDmConversationsSectionHeader => 'Direct messages';

  @override
  String get recentDmConversationsEmptyPlaceholder =>
      'You have no direct messages yet! Why not start the conversation?';

  @override
  String get combinedFeedPageTitle => 'Zlúčený kanál';

  @override
  String get mentionsPageTitle => 'Spomenutia';

  @override
  String get starredMessagesPageTitle => 'Označené správy';

  @override
  String get channelsPageTitle => 'Kanály';

  @override
  String get channelsEmptyPlaceholder =>
      'You are not subscribed to any channels yet.';

  @override
  String get mainMenuMyProfile => 'Môj profil';

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
  String get notifSelfUser => 'Ty';

  @override
  String get reactedEmojiSelfUser => 'You';

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
  String get languageSettingTitle => 'Language';

  @override
  String get languageEn => 'English';

  @override
  String get languagePl => 'Polish';

  @override
  String get languageRu => 'Russian';

  @override
  String get languageUk => 'Ukrainian';

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
  String get errorNotificationOpenTitle => 'Nepodarilo sa otvoriť oznámenie';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'The account associated with this notification could not be found.';

  @override
  String get errorReactionAddingFailedTitle => 'Nepodarilo sa pridať reakciu';

  @override
  String get errorReactionRemovingFailedTitle => 'Odobranie reakcie zlyhalo';

  @override
  String get emojiReactionsMore => 'viac';

  @override
  String get emojiPickerSearchEmoji => 'Hľadať emotikon';

  @override
  String get noEarlierMessages => 'No earlier messages';

  @override
  String get mutedSender => 'Muted sender';

  @override
  String get revealButtonLabel => 'Reveal message for muted sender';

  @override
  String get mutedUser => 'Muted user';

  @override
  String get scrollToBottomTooltip => 'Scroll to bottom';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
