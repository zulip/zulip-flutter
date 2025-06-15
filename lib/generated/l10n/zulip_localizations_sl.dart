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
  String get actionSheetOptionMarkChannelAsRead => 'Označi kanal kot prebran';

  @override
  String get actionSheetOptionListOfTopics => 'Seznam tem';

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
  String get actionSheetOptionQuoteMessage => 'Quote message';

  @override
  String get actionSheetOptionStarMessage => 'Označi sporočilo z zvezdico';

  @override
  String get actionSheetOptionUnstarMessage => 'Odstrani zvezdico s sporočila';

  @override
  String get actionSheetOptionEditMessage => 'Uredi sporočilo';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Označi temo kot prebrano';

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
      one: 'Dve datoteki presegata',
    );
    String _temp1 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'ne bodo naložene',
      few: 'ne bodo naložene',
      one: 'ne bosta naloženi',
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
      one: 'Dve datoteki sta preveliki',
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
      'When you restore an unsent message, the content that was previously in the compose box is discarded.';

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
      one: '2 sporočili',
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
      one: 'Označeni sta 2 sporočili kot neprebrani',
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
  String get mainMenuMyProfile => 'Moj profil';

  @override
  String get topicsButtonLabel => 'TEME';

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
  String get pollWidgetQuestionMissing => 'Brez vprašanja.';

  @override
  String get pollWidgetOptionsMissing => 'Ta anketa še nima odgovorov.';

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
  String get emojiReactionsMore => 'več';

  @override
  String get emojiPickerSearchEmoji => 'Iskanje emojijev';

  @override
  String get noEarlierMessages => 'Ni starejših sporočil';

  @override
  String get mutedSender => 'Utišan pošiljatelj';

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
