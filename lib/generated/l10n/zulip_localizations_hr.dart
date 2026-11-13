// TODO(upstream) drop once gen-l10n stops using the deprecated members:
//   https://github.com/flutter/flutter/issues/191072
// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class ZulipLocalizationsHr extends ZulipLocalizations {
  ZulipLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get aboutPageTitle => 'O programu Zulip';

  @override
  String get aboutPageAppVersion => 'Verzija aplikacije';

  @override
  String get aboutPageAppVersionUnknown =>
      'Podaci o verziji aplikacije nisu pronađeni.';

  @override
  String get aboutPageReleaseNotes => 'Napomene o verziji';

  @override
  String get aboutPageOpenSourceLicenses => 'Licence otvorenog koda';

  @override
  String get chooseAccountPageTitle => 'Odaberi račun';

  @override
  String get settingsPageTitle => 'Postavke';

  @override
  String get switchAccountButtonTooltip => 'Prebaci račun';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Tvoj račun na $url učitava se dulje od očekivanog.';
  }

  @override
  String get tryAnotherAccountButton => 'Pokušaj s drugim računom';

  @override
  String get chooseAccountPageLogOutButton => 'Odjavi se';

  @override
  String get logOutConfirmationDialogTitle => 'Odjaviti se?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Da bi u budućnosti koristio ovaj račun, morat ćeš ponovno unijeti URL svoje organizacije i podatke o računu.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Odjavi se';

  @override
  String get chooseAccountButtonAddAnAccount => 'Dodaj račun';

  @override
  String get navButtonAllChannels => 'Svi kanali';

  @override
  String get allChannelsPageTitle => 'Svi kanali';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'U ovoj organizaciji nema kanala koje možeš pregledavati.';

  @override
  String get profileButtonSendDirectMessage => 'Pošalji izravnu poruku';

  @override
  String get errorCouldNotShowUserProfile =>
      'Nije moguće prikazati profil korisnika.';

  @override
  String get permissionsNeededTitle => 'Potrebna dopuštenja';

  @override
  String get permissionsNeededOpenSettings => 'Otvori postavke';

  @override
  String get permissionsDeniedCameraAccess =>
      'Za prijenos slike dodijeli Zulipu dodatna dopuštenja u postavkama.';

  @override
  String get actionSheetOptionSubscribe => 'Pretplati se';

  @override
  String get subscribeFailedTitle => 'Pretplata nije uspjela';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Označi kanal kao pročitan';

  @override
  String get actionSheetOptionCopyChannelLink => 'Kopiraj poveznicu na kanal';

  @override
  String get actionSheetOptionListOfTopics => 'Popis tema';

  @override
  String get actionSheetOptionChannelFeed => 'Pregled kanala';

  @override
  String get actionSheetOptionUnsubscribe => 'Otkaži pretplatu';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Otkazati pretplatu na $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Kad napustiš ovaj kanal, više mu se nećeš moći ponovno pridružiti.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Otkaži pretplatu';

  @override
  String get unsubscribeFailedTitle => 'Otkazivanje pretplate nije uspjelo';

  @override
  String get actionSheetOptionPinChannel => 'Prikvači na vrh';

  @override
  String get actionSheetOptionUnpinChannel => 'Otkvači s vrha';

  @override
  String get errorPinChannelFailedTitle => 'Prikvačivanje kanala nije uspjelo';

  @override
  String get errorUnpinChannelFailedTitle => 'Otkvačivanje kanala nije uspjelo';

  @override
  String get actionSheetOptionMuteTopic => 'Utišaj temu';

  @override
  String get actionSheetOptionUnmuteTopic => 'Ponovno uključi temu';

  @override
  String get actionSheetOptionFollowTopic => 'Prati temu';

  @override
  String get actionSheetOptionUnfollowTopic => 'Prestani pratiti temu';

  @override
  String get actionSheetOptionResolveTopic => 'Označi kao riješeno';

  @override
  String get actionSheetOptionUnresolveTopic => 'Označi kao neriješeno';

  @override
  String get errorResolveTopicFailedTitle =>
      'Označavanje teme kao riješene nije uspjelo';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Označavanje teme kao neriješene nije uspjelo';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Vidi tko je reagirao';

  @override
  String get seeWhoReactedSheetNoReactions => 'Ova poruka nema reakcija.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Reakcije emojijem (ukupno $num)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num glasova',
      few: '$num glasa',
      one: '$num glas',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Glasovi za $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts => 'Vidi potvrde o čitanju';

  @override
  String get actionSheetReadReceipts => 'Potvrde o čitanju';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ovu je poruku <z-link>pročitalo</z-link> $count osoba:',
      one: 'Ovu je poruku <z-link>pročitala</z-link> $count osoba:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Ovu poruku još nitko nije pročitao.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Učitavanje potvrda o čitanju nije uspjelo.';

  @override
  String get actionSheetOptionCopyMessageText => 'Kopiraj tekst poruke';

  @override
  String get actionSheetOptionCopyMessageLink => 'Kopiraj poveznicu na poruku';

  @override
  String get actionSheetOptionMarkAsUnread => 'Označi kao nepročitano od ovdje';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Ponovno sakrij utišanu poruku';

  @override
  String get actionSheetOptionHideLinkPreviews => 'Sakrij preglede poveznica';

  @override
  String get actionSheetOptionShowLinkPreviews => 'Prikaži preglede poveznica';

  @override
  String get actionSheetOptionShare => 'Podijeli';

  @override
  String get actionSheetOptionQuoteMessage => 'Citiraj poruku';

  @override
  String get actionSheetOptionStarMessage => 'Označi poruku zvjezdicom';

  @override
  String get actionSheetOptionUnstarMessage => 'Ukloni zvjezdicu s poruke';

  @override
  String get actionSheetOptionEditMessage => 'Uredi poruku';

  @override
  String get actionSheetOptionDeleteMessage => 'Izbriši poruku';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Izbrisati poruku?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Brisanjem se poruka trajno uklanja za sve.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Izbriši';

  @override
  String get errorDeleteMessageFailedTitle => 'Brisanje poruke nije uspjelo';

  @override
  String get actionSheetOptionReportMessage => 'Prijavi poruku';

  @override
  String get reportMessageDialogTitle => 'Prijavi poruku';

  @override
  String get reportMessageDescription =>
      'Tvoja prijava bit će poslana na privatni kanal za moderacijske zahtjeve ove organizacije.';

  @override
  String get messageReportTypeSpam => 'Spam';

  @override
  String get messageReportTypeHarassment => 'Uznemiravanje';

  @override
  String get messageReportTypeInappropriate => 'Neprimjeren sadržaj';

  @override
  String get messageReportTypeNorms => 'Krši pravila zajednice';

  @override
  String get messageReportTypeOther => 'Drugi razlog';

  @override
  String get reportMessageReasonLabel => 'Što nije u redu s ovom porukom?';

  @override
  String get reportMessageDescriptionLabel =>
      'Možeš li navesti više pojedinosti?';

  @override
  String get reportMessageDescriptionRequired => 'Molimo navedi pojedinosti.';

  @override
  String get reportMessageSubmitButton => 'Pošalji';

  @override
  String get reportMessageSuccess => 'Poruka je prijavljena';

  @override
  String get errorReportMessageFailedTitle => 'Prijava poruke nije uspjela';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Označi temu kao pročitanu';

  @override
  String get actionSheetOptionCopyTopicLink => 'Kopiraj poveznicu na temu';

  @override
  String actionSheetTitleDm(String user) {
    return 'Izravne poruke s $user';
  }

  @override
  String get actionSheetTitleSelfDm => 'Izravne poruke sebi';

  @override
  String get actionSheetTitleGroupDm => 'Grupna izravna poruka';

  @override
  String get actionSheetOptionViewProfile => 'Prikaži profil';

  @override
  String get actionSheetOptionMarkDmConversationAsRead =>
      'Označi razgovor kao pročitan';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Nešto je pošlo krivo';

  @override
  String get errorWebAuthOperationalError =>
      'Došlo je do neočekivane pogreške.';

  @override
  String get errorAccountLoggedInTitle => 'Račun je već prijavljen';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Račun $email na $server već je na popisu tvojih računa.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Nije moguće dohvatiti izvorni tekst poruke.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Nije moguće pristupiti prenesenoj datoteci';

  @override
  String get errorCopyingFailed => 'Kopiranje nije uspjelo';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Prijenos datoteke nije uspio: $filename';
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
      other: 'Datoteke su veće',
      few: 'Datoteke su veće',
      one: 'Datoteka je veća',
    );
    return '$_temp0 od ograničenja poslužitelja od $maxFileUploadSizeMib MiB i neće se prenijeti:\r\n\r\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num datoteke prevelike',
      few: 'Datoteke prevelike',
      one: 'Datoteka prevelika',
    );
    return '$_temp0';
  }

  @override
  String get errorCouldNotLoadSelectedFiles =>
      'Odabrane datoteke nije moguće učitati.';

  @override
  String errorCouldNotReadFile(String filename) {
    return 'Nije moguće pročitati datoteku: $filename';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Neispravan unos';

  @override
  String get errorLoginFailedTitle => 'Prijava nije uspjela';

  @override
  String get errorMessageNotSent => 'Poruka nije poslana';

  @override
  String get errorMessageEditNotSaved => 'Poruka nije spremljena';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Povezivanje s poslužiteljem nije uspjelo:\r\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Nije moguće povezati se';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Čini se da ta poruka ne postoji.';

  @override
  String get errorQuotationFailed => 'Citiranje nije uspjelo';

  @override
  String errorServerMessage(String message) {
    return 'Poslužitelj je odgovorio:\r\n\r\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Pogreška pri povezivanju sa Zulipom. Pokušavam ponovno…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Pogreška pri povezivanju sa Zulipom na $serverUrl. Pokušat ću ponovno:\r\n\r\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Pogreška pri obradi Zulip događaja. Ponovno povezivanje…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Pogreška pri obradi Zulip događaja s $serverUrl; pokušat ću ponovno.\r\n\r\nPogreška: $error\r\n\r\nDogađaj: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Nije moguće otvoriti poveznicu';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Poveznicu nije moguće otvoriti: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Utišavanje teme nije uspjelo';

  @override
  String get errorUnmuteTopicFailed => 'Ponovno uključivanje teme nije uspjelo';

  @override
  String get errorFollowTopicFailed => 'Praćenje teme nije uspjelo';

  @override
  String get errorUnfollowTopicFailed => 'Prestanak praćenja teme nije uspio';

  @override
  String get errorSharingFailed => 'Dijeljenje nije uspjelo';

  @override
  String get errorStarMessageFailedTitle =>
      'Označavanje poruke zvjezdicom nije uspjelo';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Uklanjanje zvjezdice s poruke nije uspjelo';

  @override
  String get errorHideLinkPreviewsFailedTitle =>
      'Sakrivanje pregleda poveznica nije uspjelo';

  @override
  String get errorShowLinkPreviewsFailedTitle =>
      'Prikazivanje pregleda poveznica nije uspjelo';

  @override
  String get errorCouldNotEditMessageTitle => 'Nije moguće urediti poruku';

  @override
  String get successAppVersionCopied => 'Verzija aplikacije je kopirana';

  @override
  String get successLinkCopied => 'Poveznica je kopirana';

  @override
  String get successMessageTextCopied => 'Tekst poruke je kopiran';

  @override
  String get successMessageLinkCopied => 'Poveznica na poruku je kopirana';

  @override
  String get successTopicLinkCopied => 'Poveznica na temu je kopirana';

  @override
  String get successChannelLinkCopied => 'Poveznica na kanal je kopirana';

  @override
  String get composeBoxBannerLabelDeactivatedDmRecipient =>
      'Ne možeš slati poruke deaktiviranim korisnicima.';

  @override
  String get composeBoxBannerLabelUnknownDmRecipient =>
      'Ne možeš slati poruke nepoznatim korisnicima.';

  @override
  String get composeBoxBannerLabelCannotSendUnspecifiedReason =>
      'Ovdje ne možeš slati poruke.';

  @override
  String get composeBoxBannerLabelCannotSendInChannel =>
      'Nemaš dopuštenje za pisanje u ovom kanalu.';

  @override
  String get composeBoxBannerLabelUnsubscribed =>
      'Odgovori na tvoje poruke neće se prikazivati automatski.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Nove poruke neće se prikazivati automatski.';

  @override
  String get composeBoxBannerButtonRefresh => 'Osvježi';

  @override
  String get composeBoxBannerButtonSubscribe => 'Pretplati se';

  @override
  String get composeBoxBannerLabelEditMessage => 'Uredi poruku';

  @override
  String get composeBoxBannerButtonCancel => 'Odustani';

  @override
  String get composeBoxBannerButtonSave => 'Spremi';

  @override
  String get editAlreadyInProgressTitle => 'Nije moguće urediti poruku';

  @override
  String get editAlreadyInProgressMessage =>
      'Uređivanje je već u tijeku. Pričekaj da završi.';

  @override
  String get savingMessageEditLabel => 'SPREMANJE IZMJENE…';

  @override
  String get savingMessageEditFailedLabel => 'IZMJENA NIJE SPREMLJENA';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Odbaciti poruku koju pišeš?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Kad urediš poruku, sadržaj koji je prije bio u polju za pisanje se odbacuje.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Kad vratiš neposlanu poruku, sadržaj koji je prije bio u polju za pisanje se odbacuje.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Odbaci';

  @override
  String get composeBoxAttachFilesTooltip => 'Priloži datoteke';

  @override
  String get composeBoxAttachMediaTooltip => 'Priloži slike ili videozapise';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Snimi fotografiju';

  @override
  String get composeBoxGenericContentHint => 'Napiši poruku';

  @override
  String get newDmSheetComposeButtonLabel => 'Nova poruka';

  @override
  String get newDmSheetScreenTitle => 'Nova izravna poruka';

  @override
  String get newDmFabButtonLabel => 'Nova izravna poruka';

  @override
  String get newDmSheetSearchHintEmpty => 'Dodaj jednog ili više korisnika';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Dodaj još jednog korisnika…';

  @override
  String get newDmSheetNoUsersFound => 'Nema pronađenih korisnika';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Pošalji poruku @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Poruka grupi';

  @override
  String get composeBoxSelfDmContentHint => 'Napiši si bilješku';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Pošalji poruku u $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Pripremanje…';

  @override
  String get composeBoxSendTooltip => 'Pošalji';

  @override
  String get unknownChannelName => '(nepoznat kanal)';

  @override
  String get composeBoxTopicHintText => 'Tema';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Unesi temu (preskoči za „$defaultTopicName“)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Prijenos $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(učitavanje poruke $messageId)';
  }

  @override
  String get unknownUserName => '(nepoznat korisnik)';

  @override
  String get dmsWithYourselfPageTitle => 'Izravne poruke sa sobom';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Ti i $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'Izravne poruke s $others';
  }

  @override
  String get emptyMessageList => 'Ovdje nema poruka.';

  @override
  String get emptyMessageListCombinedFeed =>
      'U tvom objedinjenom pregledu nema poruka.';

  @override
  String get emptyMessageListChannelWithoutContentAccess =>
      'Nemaš <z-link>pristup sadržaju</z-link> ovog kanala.';

  @override
  String get emptyMessageListChannelUnavailable =>
      'Ovaj kanal ne postoji ili ti ga nije dopušteno pregledavati.';

  @override
  String get emptyMessageListSelfDmHeader =>
      'Još nisi poslao nijednu izravnu poruku sebi!';

  @override
  String get emptyMessageListSelfDmMessage =>
      'Koristi ovaj prostor za osobne bilješke ili za isprobavanje Zulip mogućnosti.';

  @override
  String emptyMessageListDm(String person) {
    return 'Još nemaš izravnih poruka s $person.';
  }

  @override
  String emptyMessageListDmDeactivatedUser(String person) {
    return 'Nemaš izravnih poruka s $person.';
  }

  @override
  String get emptyMessageListDmUnknownUser =>
      'Nemaš izravnih poruka s ovim korisnikom.';

  @override
  String get emptyMessageListGroupDm =>
      'Još nemaš izravnih poruka s tim korisnicima.';

  @override
  String get emptyMessageListGroupDmDeactivatedUser =>
      'Nemaš izravnih poruka s tim korisnicima.';

  @override
  String get emptyMessageListDmStartConversation =>
      'Zašto ne započneš razgovor?';

  @override
  String get emptyMessageListMentionsHeader =>
      'Ovdje će se prikazivati poruke u kojima si <z-link>spomenut</z-link>.';

  @override
  String get emptyMessageListMentionsMessage =>
      'Da bi nešto istaknuo, možeš spomenuti korisnika, grupu, sudionike teme ili sve pretplatnike kanala. Upiši @ u polje za pisanje i odaberi osobu s popisa prijedloga.';

  @override
  String get emptyMessageListStarredHeader => 'Nemaš poruka sa zvjezdicom.';

  @override
  String emptyMessageListStarredMessage(String button) {
    return '<z-link>Označavanje zvjezdicom</z-link> dobar je način da pratiš važne poruke, poput zadataka kojima se trebaš vratiti ili korisnih poveznica. Da označiš poruku, dugo je pritisni i dodirni gumb $button';
  }

  @override
  String get emptyMessageListSearch => 'Nema rezultata pretrage.';

  @override
  String get messageListGroupYouWithYourself => 'Poruke sa sobom';

  @override
  String get contentValidationErrorTooLong =>
      'Poruka ne smije biti dulja od 10000 znakova.';

  @override
  String get contentValidationErrorEmpty => 'Nemaš što poslati!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Pričekaj da citiranje završi.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Pričekaj da prijenos završi.';

  @override
  String get dialogCancel => 'Odustani';

  @override
  String get dialogContinue => 'Nastavi';

  @override
  String get dialogClose => 'Zatvori';

  @override
  String get errorDialogLearnMore => 'Saznaj više';

  @override
  String get errorDialogContinue => 'U redu';

  @override
  String get errorDialogTitle => 'Pogreška';

  @override
  String get snackBarDetails => 'Pojedinosti';

  @override
  String get lightboxCopyLinkTooltip => 'Kopiraj poveznicu';

  @override
  String get lightboxVideoCurrentPosition => 'Trenutna pozicija';

  @override
  String get lightboxVideoDuration => 'Trajanje videozapisa';

  @override
  String get loginPageTitle => 'Prijavi se';

  @override
  String get loginFormSubmitLabel => 'Prijavi se';

  @override
  String get loginMethodDivider => 'ILI';

  @override
  String get loginMethodDividerSemanticLabel => 'Alternativni načini prijave';

  @override
  String signInWithFoo(String method) {
    return 'Prijavi se pomoću $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Dodaj račun';

  @override
  String get loginRealmUrlLabel => 'URL tvoje Zulip organizacije';

  @override
  String get loginRealmUrlHelperText =>
      'To je adresa koju bi koristio za otvaranje Zulipa u pregledniku.';

  @override
  String get loginRealmUrlHelpButton => 'Pomoć';

  @override
  String get loginHidePassword => 'Sakrij lozinku';

  @override
  String get loginEmailLabel => 'E-adresa';

  @override
  String get loginErrorMissingEmail => 'Unesi svoju e-adresu.';

  @override
  String get loginPasswordLabel => 'Lozinka';

  @override
  String get loginErrorMissingPassword => 'Unesi svoju lozinku.';

  @override
  String get loginUsernameLabel => 'Korisničko ime';

  @override
  String get loginErrorMissingUsername => 'Unesi svoje korisničko ime.';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '# znakova',
      few: '# znaka',
      one: '# znak',
    );
    return 'Tema ne smije biti dulja od $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Teme su obavezne u ovom kanalu.';

  @override
  String get errorContentNotInsertedTitle => 'Sadržaj nije umetnut';

  @override
  String get errorContentToInsertIsEmpty =>
      'Datoteka koju treba umetnuti je prazna ili joj se ne može pristupiti.';

  @override
  String errorServerVersionNotAllowedMessage(
    String url,
    String zulipVersion,
    String minAllowedZulipVersion,
  ) {
    return '$url radi na Zulip Serveru $zulipVersion, koji nije podržan. Najniža podržana verzija je Zulip Server $minAllowedZulipVersion.';
  }

  @override
  String serverCompatBannerAdminMessage(String url, String zulipVersion) {
    return '$url radi na Zulip Serveru $zulipVersion, koji nije podržan. Nadogradi poslužitelj što prije.';
  }

  @override
  String serverCompatBannerUserMessage(String url, String zulipVersion) {
    return '$url radi na Zulip Serveru $zulipVersion, koji nije podržan. Obrati se administratoru poslužitelja u vezi nadogradnje.';
  }

  @override
  String get serverCompatBannerDismissLabel => 'Odbaci';

  @override
  String get serverCompatBannerLearnMoreLabel => 'Saznaj više';

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Tvoj račun na $url nije moguće autentificirati. Pokušaj se ponovno prijaviti ili koristi drugi račun.';
  }

  @override
  String get errorInvalidResponse =>
      'Poslužitelj je poslao neispravan odgovor.';

  @override
  String get errorNetworkRequestFailed => 'Mrežni zahtjev nije uspio';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Poslužitelj je vratio neispravan odgovor; HTTP status $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Poslužitelj je vratio neispravan odgovor; HTTP status $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Mrežni zahtjev nije uspio: HTTP status $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Nije moguće reproducirati videozapis.';

  @override
  String get errorVideoPlayerFailedTryBrowser =>
      'Umjesto toga ga pokušaj otvoriti u pregledniku.';

  @override
  String get dialogOpenInBrowser => 'Otvori u pregledniku';

  @override
  String get serverUrlValidationErrorEmpty => 'Unesi URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Unesi ispravan URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Unesi URL poslužitelja, a ne svoju e-adresu.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'URL poslužitelja mora započinjati s http:// ili https://.';

  @override
  String get spoilerDefaultHeaderText => 'Spojler';

  @override
  String get markAllAsReadLabel => 'Označi sve poruke kao pročitane';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num poruka',
      few: '$num poruke',
      one: '$num poruka',
    );
    return 'Označeno $_temp0 kao pročitano.';
  }

  @override
  String get markAsReadInProgress => 'Označavanje poruka kao pročitanih…';

  @override
  String get errorMarkAsReadFailedTitle =>
      'Označavanje kao pročitano nije uspjelo';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num poruka',
      few: '$num poruke',
      one: '$num poruka',
    );
    return 'Označeno $_temp0 kao nepročitano.';
  }

  @override
  String get markAsUnreadInProgress => 'Označavanje poruka kao nepročitanih…';

  @override
  String get errorMarkAsUnreadFailedTitle =>
      'Označavanje kao nepročitano nije uspjelo';

  @override
  String markAllAsReadConfirmationDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Označiti $count+ poruka kao pročitane?',
      few: 'Označiti $count+ poruke kao pročitane?',
      one: 'Označiti $count+ poruka kao pročitane?',
    );
    return '$_temp0';
  }

  @override
  String get markAllAsReadConfirmationDialogTitleNoCount =>
      'Označiti poruke kao pročitane?';

  @override
  String get markAllAsReadConfirmationDialogMessage =>
      'Poruke u više razgovora mogu biti obuhvaćene.';

  @override
  String get markAllAsReadConfirmationDialogConfirmButton =>
      'Označi kao pročitano';

  @override
  String get today => 'Danas';

  @override
  String get yesterday => 'Jučer';

  @override
  String get userActiveNow => 'Aktivan sada';

  @override
  String get userIdle => 'Neaktivan';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuta',
      few: '$minutes minute',
      one: '$minutes minutu',
    );
    return 'Aktivan prije $_temp0';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours sati',
      few: '$hours sata',
      one: '$hours sat',
    );
    return 'Aktivan prije $_temp0';
  }

  @override
  String get userActiveYesterday => 'Aktivan jučer';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dana',
      few: '$days dana',
      one: '$days dan',
    );
    return 'Aktivan prije $_temp0';
  }

  @override
  String userActiveDate(String date) {
    return 'Aktivan $date';
  }

  @override
  String get userNotActiveInYear => 'Nije aktivan u posljednjih godinu dana';

  @override
  String get invisibleMode => 'Nevidljivi način';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Pogreška pri uključivanju nevidljivog načina. Pokušaj ponovno.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Pogreška pri isključivanju nevidljivog načina. Pokušaj ponovno.';

  @override
  String get userRoleOwner => 'Vlasnik';

  @override
  String get userRoleAdministrator => 'Administrator';

  @override
  String get userRoleModerator => 'Moderator';

  @override
  String get userRoleMember => 'Član';

  @override
  String get userRoleGuest => 'Gost';

  @override
  String get userRoleUnknown => 'Nepoznato';

  @override
  String get statusButtonLabelStatusSet => 'Status';

  @override
  String get statusButtonLabelStatusUnset => 'Postavi status';

  @override
  String get noStatusText => 'Nema teksta statusa';

  @override
  String get setStatusPageTitle => 'Postavi status';

  @override
  String get statusClearButtonLabel => 'Očisti';

  @override
  String get statusSaveButtonLabel => 'Spremi';

  @override
  String get statusTextHint => 'Tvoj status';

  @override
  String get userStatusBusy => 'Zauzet';

  @override
  String get userStatusInAMeeting => 'Na sastanku';

  @override
  String get userStatusCommuting => 'Na putu';

  @override
  String get userStatusOutSick => 'Bolovanje';

  @override
  String get userStatusVacationing => 'Na godišnjem';

  @override
  String get userStatusWorkingRemotely => 'Radim na daljinu';

  @override
  String get userStatusAtTheOffice => 'U uredu';

  @override
  String get updateStatusErrorTitle =>
      'Pogreška pri ažuriranju statusa. Pokušaj ponovno.';

  @override
  String get searchMessagesPageTitle => 'Pretraži';

  @override
  String get searchMessagesHintText => 'Pretraži';

  @override
  String get searchMessagesClearButtonTooltip => 'Očisti';

  @override
  String get inboxPageTitle => 'Sandučić';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'U sandučiću nema nepročitanih poruka.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Pomoću gumba ispod pregledaj objedinjeni pregled ili popis kanala.';

  @override
  String get pinnedChannelsFolderName => 'Prikvačeni kanali';

  @override
  String get otherChannelsFolderName => 'Ostali kanali';

  @override
  String get recentDmConversationsPageTitle => 'Izravne poruke';

  @override
  String get recentDmConversationsPageShortLabel => 'Izravne';

  @override
  String get recentDmConversationsSectionHeader => 'Izravne poruke';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'Još nemaš izravnih poruka!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Zašto ne započneš razgovor?';

  @override
  String get combinedFeedPageTitle => 'Objedinjeni pregled';

  @override
  String get mentionsPageTitle => 'Spominjanja';

  @override
  String get starredMessagesPageTitle => 'Poruke sa zvjezdicom';

  @override
  String get channelsPageTitle => 'Kanali';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Još nisi pretplaćen na nijedan kanal.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Idi na <z-link>$allChannelsPageTitle</z-link> i pridruži se nekom od njih.';
  }

  @override
  String get shareChooseAccountModalTitle => 'Odaberi račun';

  @override
  String get mainMenuMyProfile => 'Moj profil';

  @override
  String get topicsButtonTooltip => 'Teme';

  @override
  String get channelFeedButtonTooltip => 'Pregled kanala';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: 'još $numOthers osoba',
      few: 'još $numOthers osobe',
      one: 'još $numOthers osobi',
    );
    return '$senderFullName tebi i $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Prikvačeno';

  @override
  String get unpinnedSubscriptionsLabel => 'Nije prikvačeno';

  @override
  String get notifSelfUser => 'Ti';

  @override
  String get reactedEmojiSelfUser => 'Ti';

  @override
  String get reactionChipsLabel => 'Reakcije';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Ti i još $otherUsersCount osoba',
      few: 'Ti i još $otherUsersCount osobe',
      one: 'Ti i još $otherUsersCount osoba',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist piše…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist i $otherTypist pišu…';
  }

  @override
  String get manyPeopleTyping => 'Nekoliko osoba piše…';

  @override
  String get wildcardMentionAll => 'svi';

  @override
  String get wildcardMentionEveryone => 'svi';

  @override
  String get wildcardMentionChannel => 'kanal';

  @override
  String get wildcardMentionStream => 'stream';

  @override
  String get wildcardMentionTopic => 'tema';

  @override
  String get wildcardMentionChannelDescription => 'Obavijesti kanal';

  @override
  String get wildcardMentionStreamDescription => 'Obavijesti stream';

  @override
  String get wildcardMentionAllDmDescription => 'Obavijesti primatelje';

  @override
  String get wildcardMentionTopicDescription => 'Obavijesti temu';

  @override
  String get systemGroupNameEveryoneOnInternet => 'Svi na internetu';

  @override
  String get systemGroupNameEveryone => 'Svi, uključujući goste';

  @override
  String get systemGroupNameMembers => 'Svi osim gostiju';

  @override
  String get systemGroupNameFullMembers => 'Puni članovi';

  @override
  String get systemGroupNameModerators => 'Moderatori';

  @override
  String get systemGroupNameAdministrators => 'Administratori';

  @override
  String get systemGroupNameOwners => 'Vlasnici';

  @override
  String get systemGroupNameNobody => 'Nitko';

  @override
  String get navBarFeedLabel => 'Pregled';

  @override
  String get navBarMenuLabel => 'Izbornik';

  @override
  String get messageIsEditedLabel => 'UREĐENO';

  @override
  String get messageIsMovedLabel => 'PREMJEŠTENO';

  @override
  String get messageNotSentLabel => 'PORUKA NIJE POSLANA';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'TEMA IZGLEDA';

  @override
  String get themeSettingDark => 'Tamna';

  @override
  String get themeSettingLight => 'Svijetla';

  @override
  String get themeSettingSystem => 'Sustav';

  @override
  String get openLinksWithInAppBrowser =>
      'Otvaraj poveznice u pregledniku unutar aplikacije';

  @override
  String get pollWidgetQuestionMissing => 'Nema pitanja.';

  @override
  String get pollWidgetOptionsMissing => 'Ova anketa još nema mogućnosti.';

  @override
  String get initialAnchorSettingTitle => 'Otvaraj preglede poruka na';

  @override
  String get initialAnchorSettingDescription =>
      'Možeš odabrati hoće li se pregledi poruka otvarati na prvoj nepročitanoj poruci ili na najnovijim porukama.';

  @override
  String get initialAnchorSettingFirstUnreadAlways => 'Prva nepročitana poruka';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Prva nepročitana poruka u razgovorima, najnovija poruka drugdje';

  @override
  String get initialAnchorSettingNewestAlways => 'Najnovija poruka';

  @override
  String get markReadOnScrollSettingTitle =>
      'Označavaj poruke kao pročitane pri pomicanju';

  @override
  String get markReadOnScrollSettingDescription =>
      'Trebaju li se poruke automatski označavati kao pročitane dok se pomičeš kroz njih?';

  @override
  String get markReadOnScrollSettingAlways => 'Uvijek';

  @override
  String get markReadOnScrollSettingNever => 'Nikada';

  @override
  String get markReadOnScrollSettingConversations => 'Samo u prikazu razgovora';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Poruke se automatski označavaju kao pročitane samo pri pregledu jedne teme ili izravnog razgovora.';

  @override
  String get experimentalFeatureSettingsPageTitle =>
      'Eksperimentalne mogućnosti';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Ove mogućnosti uključuju funkcije koje su još u razvoju i nisu dovršene. Možda neće raditi i mogu uzrokovati probleme u drugim dijelovima aplikacije.\r\n\r\nNamjena ovih postavki je isprobavanje od strane ljudi koji rade na razvoju Zulipa.';

  @override
  String get errorNotificationOpenTitle => 'Obavijest nije moguće otvoriti';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Račun povezan s ovom obavijesti nije pronađen.';

  @override
  String get errorReactionAddingFailedTitle =>
      'Dodavanje reakcije nije uspjelo';

  @override
  String get errorReactionRemovingFailedTitle =>
      'Uklanjanje reakcije nije uspjelo';

  @override
  String get errorSharingTitle => 'Dijeljenje sadržaja nije uspjelo';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'Nijedan račun nije prijavljen. Prijavi se na račun i pokušaj ponovno.';

  @override
  String get emojiReactionsMore => 'više';

  @override
  String get emojiPickerSearchEmoji => 'Pretraži emoji';

  @override
  String get noEarlierMessages => 'Nema starijih poruka';

  @override
  String get revealButtonLabel => 'Otkrij poruku';

  @override
  String get mutedUser => 'Utišan korisnik';

  @override
  String get scrollToBottomTooltip => 'Pomakni se na dno';

  @override
  String get zulipAppTitle => 'Zulip';

  @override
  String get topicListEmptyPlaceholderHeader => 'Ovdje još nema tema.';
}
