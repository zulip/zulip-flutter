// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class ZulipLocalizationsSl extends ZulipLocalizations {
  ZulipLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get aboutPageTitle => 'O Zulipu';

  @override
  String get aboutPageAppVersion => 'Različica aplikacije';

  @override
  String get aboutPageOpenSourceLicenses => 'Odprtokodne licence';

  @override
  String get aboutPageTapToView => 'Dotaknite se za ogled';

  @override
  String get upgradeWelcomeDialogTitle => 'Dobrodošli v novi aplikaciji Zulip!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Čaka vas znana izkušnja v hitrejši in bolj elegantni obliki.';

  @override
  String get upgradeWelcomeDialogLinkText => 'Preberite objavo na blogu!';

  @override
  String get upgradeWelcomeDialogDismiss => 'Začnimo';

  @override
  String get chooseAccountPageTitle => 'Izberite račun';

  @override
  String get settingsPageTitle => 'Nastavitve';

  @override
  String get switchAccountButton => 'Preklopi račun';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Nalaganje vašega računa na $url traja dlje kot običajno.';
  }

  @override
  String get tryAnotherAccountButton => 'Poskusite z drugim računom';

  @override
  String get chooseAccountPageLogOutButton => 'Odjava';

  @override
  String get logOutConfirmationDialogTitle => 'Se želite odjaviti?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Če boste ta račun želeli uporabljati v prihodnje, boste morali znova vnesti URL svoje organizacije in podatke za prijavo.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Odjavi se';

  @override
  String get chooseAccountButtonAddAnAccount => 'Dodaj račun';

  @override
  String get navButtonAllChannels => 'All channels';

  @override
  String get allChannelsPageTitle => 'All channels';

  @override
  String get allChannelsEmptyPlaceholder =>
      'There are no channels you can view in this organization.';

  @override
  String get profileButtonSendDirectMessage => 'Pošlji neposredno sporočilo';

  @override
  String get errorCouldNotShowUserProfile =>
      'Uporabniškega profila ni mogoče prikazati.';

  @override
  String get permissionsNeededTitle => 'Potrebna so dovoljenja';

  @override
  String get permissionsNeededOpenSettings => 'Odpri nastavitve';

  @override
  String get permissionsDeniedCameraAccess =>
      'Za nalaganje slik v nastavitvah omogočite Zulipu dostop do kamere.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Za nalaganje datotek v nastavitvah omogočite Zulipu dostop do shrambe datotek.';

  @override
  String get actionSheetOptionSubscribe => 'Subscribe';

  @override
  String get subscribeFailedTitle => 'Failed to subscribe';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Označi kanal kot prebran';

  @override
  String get actionSheetOptionCopyChannelLink => 'Copy link to channel';

  @override
  String get actionSheetOptionListOfTopics => 'Seznam tem';

  @override
  String get actionSheetOptionChannelFeed => 'Channel feed';

  @override
  String get actionSheetOptionUnsubscribe => 'Unsubscribe';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Unsubscribe from $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageMaybeCannotResubscribe =>
      'Once you leave this channel, you might not be able to rejoin.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Unsubscribe';

  @override
  String get unsubscribeFailedTitle => 'Failed to unsubscribe';

  @override
  String get actionSheetOptionMuteTopic => 'Utišaj temo';

  @override
  String get actionSheetOptionUnmuteTopic => 'Prekliči utišanje teme';

  @override
  String get actionSheetOptionFollowTopic => 'Sledi temi';

  @override
  String get actionSheetOptionUnfollowTopic => 'Prenehaj slediti temi';

  @override
  String get actionSheetOptionResolveTopic => 'Označi kot razrešeno';

  @override
  String get actionSheetOptionUnresolveTopic => 'Označi kot nerazrešeno';

  @override
  String get errorResolveTopicFailedTitle =>
      'Neuspela označitev teme kot razrešene';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Neuspela označitev teme kot nerazrešene';

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
  String get actionSheetOptionCopyMessageText => 'Kopiraj besedilo sporočila';

  @override
  String get actionSheetOptionCopyMessageLink =>
      'Kopiraj povezavo do sporočila';

  @override
  String get actionSheetOptionMarkAsUnread =>
      'Od tu naprej označi kot neprebrano';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Znova skrij utišano sporočilo';

  @override
  String get actionSheetOptionShare => 'Deli';

  @override
  String get actionSheetOptionQuoteMessage => 'Citiraj sporočilo';

  @override
  String get actionSheetOptionStarMessage => 'Označi sporočilo z zvezdico';

  @override
  String get actionSheetOptionUnstarMessage => 'Odstrani zvezdico s sporočila';

  @override
  String get actionSheetOptionEditMessage => 'Uredi sporočilo';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Označi temo kot prebrano';

  @override
  String get actionSheetOptionCopyTopicLink => 'Copy link to topic';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Nekaj je šlo narobe';

  @override
  String get errorWebAuthOperationalError =>
      'Prišlo je do nepričakovane napake.';

  @override
  String get errorAccountLoggedInTitle => 'Račun je že prijavljen';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Račun $email na $server je že na vašem seznamu računov.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Ni bilo mogoče pridobiti vira sporočila.';

  @override
  String get errorCopyingFailed => 'Kopiranje ni uspelo';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Nalaganje datoteke ni uspelo: $filename';
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
      other: '$num datotek presega',
      few: '$num datoteke presegajo',
      two: '$num datoteki presegata',
      one: '$num datoteka presega',
    );
    String _temp1 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'ne bodo naložene',
      few: 'ne bodo naložene',
      two: 'ne bosta naloženi',
      one: 'ne bo naložena',
    );
    return '$_temp0 omejitev velikosti strežnika ($maxFileUploadSizeMib MiB) in $_temp1:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num datotek je prevelikih',
      few: '$num datoteke so prevelike',
      two: '$num datoteki sta preveliki',
      one: '$num datoteka je prevelika',
    );
    return '\"$_temp0\"';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Neveljaven vnos';

  @override
  String get errorLoginFailedTitle => 'Prijava ni uspela';

  @override
  String get errorMessageNotSent => 'Pošiljanje sporočila ni uspelo';

  @override
  String get errorMessageEditNotSaved => 'Sporočilo ni bilo shranjeno';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Ni se mogoče povezati s strežnikom:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Povezave ni bilo mogoče vzpostaviti';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Zdi se, da to sporočilo ne obstaja.';

  @override
  String get errorQuotationFailed => 'Citiranje ni uspelo';

  @override
  String errorServerMessage(String message) {
    return 'Strežnik je sporočil:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Napaka pri povezovanju z Zulipom. Poskušamo znova…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Napaka pri povezovanju z Zulipom na $serverUrl. Poskusili bomo znova:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Napaka pri obravnavi posodobitve. Povezujemo se znova…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Napaka pri obravnavi posodobitve iz strežnika $serverUrl; poskusili bomo znova.\n\nNapaka: $error\n\nDogodek: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Povezave ni mogoče odpreti';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Povezave ni bilo mogoče odpreti: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Utišanje teme ni uspelo';

  @override
  String get errorUnmuteTopicFailed => 'Preklic utišanja teme ni uspel';

  @override
  String get errorFollowTopicFailed => 'Sledenje temi ni uspelo';

  @override
  String get errorUnfollowTopicFailed => 'Prenehanje sledenja temi ni uspelo';

  @override
  String get errorSharingFailed => 'Deljenje ni uspelo';

  @override
  String get errorStarMessageFailedTitle =>
      'Sporočila ni bilo mogoče označiti z zvezdico';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Sporočilu ni bilo mogoče odstraniti zvezdice';

  @override
  String get errorCouldNotEditMessageTitle => 'Sporočila ni mogoče urediti';

  @override
  String get successLinkCopied => 'Povezava je bila kopirana';

  @override
  String get successMessageTextCopied => 'Besedilo sporočila je bilo kopirano';

  @override
  String get successMessageLinkCopied =>
      'Povezava do sporočila je bila kopirana';

  @override
  String get successTopicLinkCopied => 'Topic link copied';

  @override
  String get successChannelLinkCopied => 'Channel link copied';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Deaktiviranim uporabnikom ne morete pošiljati sporočil.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'Nimate dovoljenja za objavljanje v tem kanalu.';

  @override
  String get composeBoxBannerLabelEditMessage => 'Uredi sporočilo';

  @override
  String get composeBoxBannerButtonCancel => 'Prekliči';

  @override
  String get composeBoxBannerButtonSave => 'Shrani';

  @override
  String get editAlreadyInProgressTitle => 'Urejanje sporočila ni mogoče';

  @override
  String get editAlreadyInProgressMessage =>
      'Urejanje je že v teku. Počakajte, da se konča.';

  @override
  String get savingMessageEditLabel => 'SHRANJEVANJE SPREMEMB…';

  @override
  String get savingMessageEditFailedLabel => 'UREJANJE NI SHRANJENO';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Želite zavreči sporočilo, ki ga pišete?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Ko urejate sporočilo, se prejšnja vsebina polja za pisanje zavrže.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Ko obnovite neodposlano sporočilo, se vsebina, ki je bila prej v polju za pisanje, zavrže.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Zavrzi';

  @override
  String get composeBoxAttachFilesTooltip => 'Pripni datoteke';

  @override
  String get composeBoxAttachMediaTooltip =>
      'Pripni fotografije ali videoposnetke';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Fotografiraj';

  @override
  String get composeBoxGenericContentHint => 'Vnesite sporočilo';

  @override
  String get newDmSheetComposeButtonLabel => 'Napiši';

  @override
  String get newDmSheetScreenTitle => 'Novo neposredno sporočilo';

  @override
  String get newDmFabButtonLabel => 'Novo neposredno sporočilo';

  @override
  String get newDmSheetSearchHintEmpty => 'Dodajte enega ali več uporabnikov';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Dodajte še enega uporabnika…';

  @override
  String get newDmSheetNoUsersFound => 'Ni zadetkov med uporabniki';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Sporočilo @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Skupinsko sporočilo';

  @override
  String get composeBoxSelfDmContentHint => 'Zapišite opombo zase';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Sporočilo $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Pripravljanje…';

  @override
  String get composeBoxSendTooltip => 'Pošlji';

  @override
  String get unknownChannelName => '(neznan kanal)';

  @override
  String get composeBoxTopicHintText => 'Tema';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Vnesite temo (ali pustite prazno za »$defaultTopicName«)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Nalaganje $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(nalaganje sporočila $messageId)';
  }

  @override
  String get unknownUserName => '(neznan uporabnik)';

  @override
  String get dmsWithYourselfPageTitle => 'Neposredna sporočila s samim seboj';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Vi in $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'Neposredna sporočila z $others';
  }

  @override
  String get emptyMessageList => 'There are no messages here.';

  @override
  String get emptyMessageListSearch => 'No search results.';

  @override
  String get messageListGroupYouWithYourself => 'Sporočila sebi';

  @override
  String get contentValidationErrorTooLong =>
      'Dolžina sporočila ne sme presegati 10000 znakov.';

  @override
  String get contentValidationErrorEmpty => 'Ni vsebine za pošiljanje!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Počakajte, da se citat zaključi.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Počakajte, da se nalaganje konča.';

  @override
  String get dialogCancel => 'Prekliči';

  @override
  String get dialogContinue => 'Nadaljuj';

  @override
  String get dialogClose => 'Zapri';

  @override
  String get errorDialogLearnMore => 'Več o tem';

  @override
  String get errorDialogContinue => 'V redu';

  @override
  String get errorDialogTitle => 'Napaka';

  @override
  String get snackBarDetails => 'Podrobnosti';

  @override
  String get lightboxCopyLinkTooltip => 'Kopiraj povezavo';

  @override
  String get lightboxVideoCurrentPosition => 'Trenutni položaj';

  @override
  String get lightboxVideoDuration => 'Trajanje videa';

  @override
  String get loginPageTitle => 'Prijava';

  @override
  String get loginFormSubmitLabel => 'Prijava';

  @override
  String get loginMethodDivider => 'ALI';

  @override
  String signInWithFoo(String method) {
    return 'Prijava z $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Dodaj račun';

  @override
  String get loginServerUrlLabel => 'URL strežnika Zulip';

  @override
  String get loginHidePassword => 'Skrij geslo';

  @override
  String get loginEmailLabel => 'E-poštni naslov';

  @override
  String get loginErrorMissingEmail => 'Vnesite svoj e-poštni naslov.';

  @override
  String get loginPasswordLabel => 'Geslo';

  @override
  String get loginErrorMissingPassword => 'Vnesite svoje geslo.';

  @override
  String get loginUsernameLabel => 'Uporabniško ime';

  @override
  String get loginErrorMissingUsername => 'Vnesite svoje uporabniško ime.';

  @override
  String get topicValidationErrorTooLong =>
      'Dolžina teme ne sme presegati 60 znakov.';

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Teme so v tej organizaciji obvezne.';

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
    return '$url uporablja strežnik Zulip $zulipVersion, ki ni podprt. Najnižja podprta različica je strežnik Zulip $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Vašega računa na $url ni bilo mogoče overiti. Poskusite se znova prijaviti ali uporabite drug račun.';
  }

  @override
  String get errorInvalidResponse => 'Strežnik je poslal neveljaven odgovor.';

  @override
  String get errorNetworkRequestFailed => 'Omrežna zahteva je spodletela';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Strežnik je poslal napačno oblikovan odgovor; stanje HTTP $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Strežnik je poslal napačno oblikovan odgovor; stanje HTTP $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Omrežna zahteva je spodletela: Stanje HTTP $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Videa ni mogoče predvajati.';

  @override
  String get serverUrlValidationErrorEmpty => 'Vnesite URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Vnesite veljaven URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Vnesite URL strežnika, ne vašega e-poštnega naslova.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'URL strežnika se mora začeti s http:// ali https://.';

  @override
  String get spoilerDefaultHeaderText => 'Skrito';

  @override
  String get markAllAsReadLabel => 'Označi vsa sporočila kot prebrana';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num sporočil',
      few: '$num sporočila',
      two: '$num sporočili',
      one: '$num sporočilo',
    );
    return 'Označeno je $_temp0 kot prebrano.';
  }

  @override
  String get markAsReadInProgress => 'Označevanje sporočil kot prebranih…';

  @override
  String get errorMarkAsReadFailedTitle => 'Označevanje kot prebrano ni uspelo';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Označeno je $num sporočil kot neprebranih',
      few: 'Označena so $num sporočila kot neprebrana',
      two: 'Označeni sta $num sporočili kot neprebrani',
      one: 'Označeno je $num sporočilo kot neprebrano',
    );
    return '$_temp0.';
  }

  @override
  String get markAsUnreadInProgress => 'Označevanje sporočil kot neprebranih…';

  @override
  String get errorMarkAsUnreadFailedTitle =>
      'Označevanje kot neprebrano ni uspelo';

  @override
  String get today => 'Danes';

  @override
  String get yesterday => 'Včeraj';

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
  String get userRoleOwner => 'Lastnik';

  @override
  String get userRoleAdministrator => 'Skrbnik';

  @override
  String get userRoleModerator => 'Moderator';

  @override
  String get userRoleMember => 'Član';

  @override
  String get userRoleGuest => 'Gost';

  @override
  String get userRoleUnknown => 'Neznano';

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
  String get inboxPageTitle => 'Nabiralnik';

  @override
  String get inboxEmptyPlaceholder =>
      'V vašem nabiralniku ni neprebranih sporočil. Uporabite spodnje gumbe za ogled združenega prikaza ali seznama kanalov.';

  @override
  String get recentDmConversationsPageTitle => 'Neposredna sporočila';

  @override
  String get recentDmConversationsSectionHeader => 'Neposredna sporočila';

  @override
  String get recentDmConversationsEmptyPlaceholder =>
      'Zaenkrat še nimate neposrednih sporočil! Zakaj ne bi začeli pogovora?';

  @override
  String get combinedFeedPageTitle => 'Združen prikaz';

  @override
  String get mentionsPageTitle => 'Omembe';

  @override
  String get starredMessagesPageTitle => 'Sporočila z zvezdico';

  @override
  String get channelsPageTitle => 'Kanali';

  @override
  String get channelsEmptyPlaceholder => 'Niste še naročeni na noben kanal.';

  @override
  String channelsEmptyPlaceholderWithAllChannelsLink(
    String allChannelsPageTitle,
  ) {
    return 'You’re not subscribed to any channels yet. Try going to <z-link>$allChannelsPageTitle</z-link> and joining some of them.';
  }

  @override
  String get sharePageTitle => 'Share';

  @override
  String get mainMenuMyProfile => 'Moj profil';

  @override
  String get topicsButtonTooltip => 'Teme';

  @override
  String get channelFeedButtonTooltip => 'Sporočila kanala';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers drugim osebam',
      one: '1 drugi osebi',
    );
    return '$senderFullName vam in $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Pripeto';

  @override
  String get unpinnedSubscriptionsLabel => 'Nepripeto';

  @override
  String get notifSelfUser => 'Vi';

  @override
  String get reactedEmojiSelfUser => 'Vi';

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
    return '$typist tipka…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist in $otherTypist tipkata…';
  }

  @override
  String get manyPeopleTyping => 'Več oseb tipka…';

  @override
  String get wildcardMentionAll => 'vsi';

  @override
  String get wildcardMentionEveryone => 'vsi';

  @override
  String get wildcardMentionChannel => 'kanal';

  @override
  String get wildcardMentionStream => 'tok';

  @override
  String get wildcardMentionTopic => 'tema';

  @override
  String get wildcardMentionChannelDescription => 'Obvesti kanal';

  @override
  String get wildcardMentionStreamDescription => 'Obvesti tok';

  @override
  String get wildcardMentionAllDmDescription => 'Obvesti prejemnike';

  @override
  String get wildcardMentionTopicDescription => 'Obvesti udeležence teme';

  @override
  String get messageIsEditedLabel => 'UREJENO';

  @override
  String get messageIsMovedLabel => 'PREMAKNJENO';

  @override
  String get messageNotSentLabel => 'SPOROČILO NI POSLANO';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'TEMA';

  @override
  String get themeSettingDark => 'Temna';

  @override
  String get themeSettingLight => 'Svetla';

  @override
  String get themeSettingSystem => 'Sistemska';

  @override
  String get openLinksWithInAppBrowser =>
      'Odpri povezave v brskalniku znotraj aplikacije';

  @override
  String get pollWidgetQuestionMissing => 'Brez vprašanja.';

  @override
  String get pollWidgetOptionsMissing => 'Ta anketa še nima odgovorov.';

  @override
  String get initialAnchorSettingTitle => 'Odpri tok sporočil pri';

  @override
  String get initialAnchorSettingDescription =>
      'Lahko izberete, ali se tok sporočil odpre pri vašem prvem neprebranem sporočilu ali pri najnovejših sporočilih.';

  @override
  String get initialAnchorSettingFirstUnreadAlways =>
      'Prvo neprebrano sporočilo';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Prvo neprebrano v pogovorih, najnovejše drugje';

  @override
  String get initialAnchorSettingNewestAlways => 'Najnovejše sporočilo';

  @override
  String get markReadOnScrollSettingTitle =>
      'Ob pomikanju označi sporočila kot prebrana';

  @override
  String get markReadOnScrollSettingDescription =>
      'Naj se sporočila ob pomikanju samodejno označijo kot prebrana?';

  @override
  String get markReadOnScrollSettingAlways => 'Vedno';

  @override
  String get markReadOnScrollSettingNever => 'Nikoli';

  @override
  String get markReadOnScrollSettingConversations =>
      'Samo v pogledih pogovorov';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Sporočila bodo samodejno označena kot prebrana samo pri ogledu ene teme ali zasebnega pogovora.';

  @override
  String get experimentalFeatureSettingsPageTitle => 'Eksperimentalne funkcije';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Te možnosti omogočajo funkcije, ki so še v razvoju in niso pripravljene. Morda ne bodo delovale in lahko povzročijo težave v drugih delih aplikacije.\n\nNamen teh nastavitev je eksperimentiranje za uporabnike, ki delajo na razvoju Zulipa.';

  @override
  String get errorNotificationOpenTitle => 'Obvestila ni bilo mogoče odpreti';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Računa, povezanega s tem obvestilom, ni bilo mogoče najti.';

  @override
  String get errorReactionAddingFailedTitle => 'Reakcije ni bilo mogoče dodati';

  @override
  String get errorReactionRemovingFailedTitle =>
      'Reakcije ni bilo mogoče odstraniti';

  @override
  String get errorSharingTitle => 'Failed to share content';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'There is no account logged in. Please log in to an account and try again.';

  @override
  String get emojiReactionsMore => 'več';

  @override
  String get emojiPickerSearchEmoji => 'Iskanje emojijev';

  @override
  String get noEarlierMessages => 'Ni starejših sporočil';

  @override
  String get revealButtonLabel => 'Prikaži sporočilo utišanega pošiljatelja';

  @override
  String get mutedUser => 'Uporabnik je utišan';

  @override
  String get scrollToBottomTooltip => 'Premakni se na konec';

  @override
  String get appVersionUnknownPlaceholder => '(...)';

  @override
  String get zulipAppTitle => 'Zulip';
}
