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
    return 'Nalaganje vašega računa iz $url traja dlje kot običajno.';
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
  String get navButtonAllChannels => 'Vsi kanali';

  @override
  String get allChannelsPageTitle => 'Vsi kanali';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'V tej organizaciji ni kanalov, do katerih imate dostop.';

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
  String get actionSheetOptionSubscribe => 'Naroči se';

  @override
  String get subscribeFailedTitle => 'Naročnina ni uspela';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Označi kanal kot prebran';

  @override
  String get actionSheetOptionCopyChannelLink => 'Kopiraj povezavo do kanala';

  @override
  String get actionSheetOptionListOfTopics => 'Seznam tem';

  @override
  String get actionSheetOptionChannelFeed => 'Vir kanala';

  @override
  String get actionSheetOptionUnsubscribe => 'Prekliči naročnino';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Odjava iz $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Ko zapustite kanal, se ne boste več mogli pridružiti nazaj.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Prekliči naročnino';

  @override
  String get unsubscribeFailedTitle => 'Preklic naročnine ni uspel';

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
  String get actionSheetOptionSeeWhoReacted => 'Poglej, kdo se je odzval';

  @override
  String get seeWhoReactedSheetNoReactions => 'To sporočilo nima odzivov.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Odzivi z emodžiji (skupaj $num)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num glasov',
      few: '$num glasovi',
      two: '2 glasa',
      one: '1 glas',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Glasovi za $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts => 'Poglej potrdila o branju';

  @override
  String get actionSheetReadReceipts => 'Potrdila o branju';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'To sporočilo je <z-link>prebralo</z-link> $count oseb:',
      few: 'To sporočilo so <z-link>prebrale</z-link> $count osebe:',
      two: 'To sporočilo sta <z-link>prebrali</z-link> $count osebi:',
      one: 'To sporočilo je <z-link>prebrala</z-link> $count oseba:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Tega sporočila še nihče ni prebral.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Nalaganje potrdil o branju ni uspelo.';

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
  String get actionSheetOptionDeleteMessage => 'Izbriši sporočilo';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Izbrišem sporočilo?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Brisanje sporočila ga trajno odstrani za vse.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Izbriši';

  @override
  String get errorDeleteMessageFailedTitle => 'Sporočila se ne da izbrisati';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Označi temo kot prebrano';

  @override
  String get actionSheetOptionCopyTopicLink => 'Kopiraj povezavo do teme';

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
  String get errorCouldNotAccessUploadedFileTitle =>
      'Dostop do naložene datoteke ni mogoč';

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
  String get successTopicLinkCopied => 'Povezava do teme kopirana';

  @override
  String get successChannelLinkCopied => 'Povezava do kanala kopirana';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Deaktiviranim uporabnikom ne morete pošiljati sporočil.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'Nimate dovoljenja za objavljanje v tem kanalu.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Nova sporočila se ne bodo prikazala samodejno.';

  @override
  String get composeBoxBannerButtonRefresh => 'Osveži';

  @override
  String get composeBoxBannerButtonSubscribe => 'Naroči se';

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
  String get composeBoxSelfDmContentHint => 'Zapišite si opombo';

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
  String get emptyMessageList => 'Tukaj ni sporočil.';

  @override
  String get emptyMessageListSearch => 'Ni zadetkov iskanja.';

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
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength znakov',
      one: '1 znaka',
    );
    return 'Dolžina teme ne sme presegati $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Teme so v tej organizaciji obvezne.';

  @override
  String get errorContentNotInsertedTitle => 'Vsebina ni vstavljena';

  @override
  String get errorContentToInsertIsEmpty =>
      'Datoteka za vstavljanje je prazna ali nedostopna.';

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
  String get userActiveNow => 'Trenutno aktiven';

  @override
  String get userIdle => 'Nedejaven';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutami',
      few: '$minutes minutami',
      two: '$minutes minutama',
      one: '1 minuto',
    );
    return 'Aktiven pred $_temp0';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours urami',
      few: '$hours urami',
      two: '$hours urama',
      one: '1 uro',
    );
    return 'Aktiven pred $_temp0';
  }

  @override
  String get userActiveYesterday => 'Aktiven včeraj';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dnevi',
      few: '$days dnevi',
      two: '$days dnevoma',
      one: '1 dnevom',
    );
    return 'Aktiven pred $_temp0';
  }

  @override
  String userActiveDate(String date) {
    return 'Nazadnje aktiven $date';
  }

  @override
  String get userNotActiveInYear => 'Ni bil aktiven v zadnjem letu';

  @override
  String get invisibleMode => 'Nevidni način';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Napaka pri vklopu nevidnega načina. Poskusite znova.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Napaka pri izklopu nevidnega načina. Poskusite znova.';

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
  String get statusButtonLabelStatusUnset => 'Nastavi status';

  @override
  String get noStatusText => 'Brez statusa';

  @override
  String get setStatusPageTitle => 'Nastavi status';

  @override
  String get statusClearButtonLabel => 'Počisti';

  @override
  String get statusSaveButtonLabel => 'Shrani';

  @override
  String get statusTextHint => 'Vaš status';

  @override
  String get userStatusBusy => 'Zaposlen';

  @override
  String get userStatusInAMeeting => 'Na sestanku';

  @override
  String get userStatusCommuting => 'Na poti v službo';

  @override
  String get userStatusOutSick => 'Na bolniški';

  @override
  String get userStatusVacationing => 'Na dopustu';

  @override
  String get userStatusWorkingRemotely => 'Delo na daljavo';

  @override
  String get userStatusAtTheOffice => 'V pisarni';

  @override
  String get updateStatusErrorTitle =>
      'Napaka pri posodabljanju statusa uporabnika. Poskusite znova.';

  @override
  String get searchMessagesPageTitle => 'Iskanje';

  @override
  String get searchMessagesHintText => 'Išči';

  @override
  String get searchMessagesClearButtonTooltip => 'Počisti';

  @override
  String get inboxPageTitle => 'Nabiralnik';

  @override
  String get inboxEmptyPlaceholderHeader => 'Ni neprebranih sporočil.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Uporabite spodnje gumbe za ogled združenega vira ali seznama kanalov.';

  @override
  String get recentDmConversationsPageTitle => 'Neposredna sporočila';

  @override
  String get recentDmConversationsSectionHeader => 'Neposredna sporočila';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'Nimate nobenih neposrednih sproročil!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Zakaj ne bi začeli pogovora?';

  @override
  String get combinedFeedPageTitle => 'Združen prikaz';

  @override
  String get mentionsPageTitle => 'Omembe';

  @override
  String get starredMessagesPageTitle => 'Sporočila z zvezdico';

  @override
  String get channelsPageTitle => 'Kanali';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Niste še naročeni na noben kanal.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Poskusite odpreti <z-link>$allChannelsPageTitle</z-link> in se jim pridružiti.';
  }

  @override
  String get sharePageTitle => 'Deli';

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
  String get reactionChipsLabel => 'Odzivi';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Vi in $otherUsersCount drugih',
      few: 'Vi in $otherUsersCount druge osebe',
      two: 'Vi in 2 drugi osebi',
      one: 'Vi in 1 druga oseba',
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
  String get errorSharingTitle => 'Deljenje vsebine ni uspelo';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'Noben račun ni prijavljen. Prijavite se v račun in poskusite znova.';

  @override
  String get emojiReactionsMore => 'več';

  @override
  String get emojiPickerSearchEmoji => 'Iskanje emojijev';

  @override
  String get noEarlierMessages => 'Ni starejših sporočil';

  @override
  String get revealButtonLabel => 'Razkrij sporočilo';

  @override
  String get mutedUser => 'Uporabnik je utišan';

  @override
  String get scrollToBottomTooltip => 'Premakni se na konec';

  @override
  String get appVersionUnknownPlaceholder => '(...)';

  @override
  String get zulipAppTitle => 'Zulip';
}
