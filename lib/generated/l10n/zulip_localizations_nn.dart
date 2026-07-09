// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Nynorsk (`nn`).
class ZulipLocalizationsNn extends ZulipLocalizations {
  ZulipLocalizationsNn([String locale = 'nn']) : super(locale);

  @override
  String get aboutPageTitle => 'Om Zulip';

  @override
  String get aboutPageAppVersion => 'Appversjon';

  @override
  String get aboutPageOpenSourceLicenses => 'Lisensar for open kjeldekode';

  @override
  String get aboutPageTapToView => 'Tæpp for å sjå';

  @override
  String get upgradeWelcomeDialogTitle => 'Velkomen til den nye Zulip-appen!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Du finn eit kjent miljø i ei raskare og meir straumlineforma pakke.';

  @override
  String get upgradeWelcomeDialogLinkText => 'Sjekk kunngjeringsbloggposten!';

  @override
  String get upgradeWelcomeDialogDismiss => 'La oss starta';

  @override
  String get chooseAccountPageTitle => 'Vel konto';

  @override
  String get settingsPageTitle => 'Innstillingar';

  @override
  String get switchAccountButtonTooltip => 'Byt konto';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Det tek ei stund å lasta inn kontoen din på $url.';
  }

  @override
  String get tryAnotherAccountButton => 'Prøv ein annan konto';

  @override
  String get chooseAccountPageLogOutButton => 'Logg ut';

  @override
  String get logOutConfirmationDialogTitle => 'Logg ut?';

  @override
  String get logOutConfirmationDialogMessage =>
      'For å nytta denne kontoen i framtida må du skriva inn URL-en for organisasjonen på nytt, i lag med kontoinformasjonen din.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Logg ut';

  @override
  String get chooseAccountButtonAddAnAccount => 'Legg til konto';

  @override
  String get navButtonAllChannels => 'Alle kanalar';

  @override
  String get allChannelsPageTitle => 'Alle kanalar';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'Det finst ingen kanalar du kan sjå i denne organisasjonen.';

  @override
  String get profileButtonSendDirectMessage => 'Send direktemelding';

  @override
  String get errorCouldNotShowUserProfile => 'Kunne ikkje visa brukarprofil.';

  @override
  String get permissionsNeededTitle => 'Treng løyve';

  @override
  String get permissionsNeededOpenSettings => 'Opne innstillingane';

  @override
  String get permissionsDeniedCameraAccess =>
      'Gje Zulip ekstra løyve i Innstillingane for å lasta opp eit bilete.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Gje Zulip ekstra løyve i Innstillingane for å lasta opp filer.';

  @override
  String get actionSheetOptionSubscribe => 'Abonner';

  @override
  String get subscribeFailedTitle => 'Kunne ikkje abonnera';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Merk kanalen som lesen';

  @override
  String get actionSheetOptionCopyChannelLink => 'Kopier lenke til kanal';

  @override
  String get actionSheetOptionListOfTopics => 'Liste over emne';

  @override
  String get actionSheetOptionChannelFeed => 'Kanalstraumen';

  @override
  String get actionSheetOptionUnsubscribe => 'Avabonner';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Slutt å abonnera på $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Når du går ut av denne kanalen kan du ikkje seinare bli med.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Avabonner';

  @override
  String get unsubscribeFailedTitle => 'Kunne ikkje avslutta abonnementet';

  @override
  String get actionSheetOptionPinChannel => 'Fest til toppen';

  @override
  String get actionSheetOptionUnpinChannel => 'Løsne frå toppen';

  @override
  String get errorPinChannelFailedTitle => 'Kunne ikkje festa kanalen';

  @override
  String get errorUnpinChannelFailedTitle => 'Kunne ikkje løsna kanalen';

  @override
  String get actionSheetOptionMuteTopic => 'Demp emnet';

  @override
  String get actionSheetOptionUnmuteTopic => 'Avdemp emnet';

  @override
  String get actionSheetOptionFollowTopic => 'Fylg emnet';

  @override
  String get actionSheetOptionUnfollowTopic => 'Ikkje fylg emnet';

  @override
  String get actionSheetOptionResolveTopic => 'Merk som løyst';

  @override
  String get actionSheetOptionUnresolveTopic => 'Merk som uløyst';

  @override
  String get errorResolveTopicFailedTitle =>
      'Kunne ikkje merka emnet som løyst';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Kunne ikkje merka emnet som uløyst';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Sjå kven som reagerte';

  @override
  String get seeWhoReactedSheetNoReactions =>
      'Denne meldinga har ingen reaksjonar.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Emoji-reaksjonar ($num i alt)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num røyster',
      one: '1 røyst',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Røyster for $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts => 'Sjå lesekvitteringar';

  @override
  String get actionSheetReadReceipts => 'Lesekvitteringar';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Denne meldinga har vorte <z-link>lesen</z-link> av $count personar:',
      one: 'Denne meldinga har vorte <z-link>lesen</z-link> av $count person:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Ingen har lese denne meldinga enno.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Kunne ikkje henta lesekvitteringane.';

  @override
  String get actionSheetOptionCopyMessageText => 'Kopier meldingstekst';

  @override
  String get actionSheetOptionCopyMessageLink => 'Kopier lenke til meldina';

  @override
  String get actionSheetOptionMarkAsUnread => 'Merk som ulese herifrå';

  @override
  String get actionSheetOptionHideMutedMessage => 'Gøym dempa melding på nytt';

  @override
  String get actionSheetOptionShare => 'Del';

  @override
  String get actionSheetOptionQuoteMessage => 'Siter meldinga';

  @override
  String get actionSheetOptionStarMessage => 'Stjernemerk meldinga';

  @override
  String get actionSheetOptionUnstarMessage => 'Fjern stjernemerkinga';

  @override
  String get actionSheetOptionEditMessage => 'Endre melding';

  @override
  String get actionSheetOptionDeleteMessage => 'Slett melding';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Slett meldinga?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Når du slettar ei melding permanent forsvinn ho for alle.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Slett';

  @override
  String get errorDeleteMessageFailedTitle => 'Kunne ikkje sletta meldinga';

  @override
  String get actionSheetOptionReportMessage => 'Meld melding';

  @override
  String get reportMessageDialogTitle => 'Meld meldinga';

  @override
  String get reportMessageDescription =>
      'Rapporten din vil bli sendt til den private kanalen for moderatorspørsmål for denne organisasjonen.';

  @override
  String get messageReportTypeSpam => 'Søppel';

  @override
  String get messageReportTypeHarassment => 'Trakassering';

  @override
  String get messageReportTypeInappropriate => 'Upassande innhald';

  @override
  String get messageReportTypeNorms => 'Bryt samfunnsnormene';

  @override
  String get messageReportTypeOther => 'Annan grunn';

  @override
  String get reportMessageReasonLabel => 'Kva er problemet med denne meldinga?';

  @override
  String get reportMessageDescriptionLabel => 'Kan du gje fleire detaljar?';

  @override
  String get reportMessageDescriptionRequired => 'Gje detaljar.';

  @override
  String get reportMessageSubmitButton => 'Send inn';

  @override
  String get reportMessageSuccess => 'Meldinga er meldt';

  @override
  String get errorReportMessageFailedTitle => 'Kunne ikkje rapportera meldinga';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Merk emnet som lese';

  @override
  String get actionSheetOptionCopyTopicLink => 'Kopier lenke til emnet';

  @override
  String actionSheetTitleDm(String user) {
    return 'DM-ar med $user';
  }

  @override
  String get actionSheetTitleSelfDm => 'DM-ar med deg sjølv';

  @override
  String get actionSheetTitleGroupDm => 'Gruppe-DM';

  @override
  String get actionSheetOptionViewProfile => 'Vis profil';

  @override
  String get actionSheetOptionMarkDmConversationAsRead =>
      'Merk samtalen som lesen';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Noko gjekk gale';

  @override
  String get errorWebAuthOperationalError => 'Det hende noko uventa.';

  @override
  String get errorAccountLoggedInTitle => 'Kontoen er allereie innlogga';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Kontoen $email ved $server finst allereie i kontolista di.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Kunne ikkje henta meldingskjelda.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Kunne ikkje få tak i opplasta fil';

  @override
  String get errorCopyingFailed => 'Kunne ikkje kopiera';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Kunne ikkje lasta opp: $filename';
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
      other: '$num filene',
      one: 'Fila',
    );
    return '$_temp0 er større enn servergrensa på $maxFileUploadSizeMib MiB og vil ikkje bli lasta opp:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Filene for store',
      one: 'Fila for stor',
    );
    return '$_temp0';
  }

  @override
  String errorCouldNotReadFile(String filename) {
    return 'Could not read file: $filename';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Ugyldige inndata';

  @override
  String get errorLoginFailedTitle => 'Innlogginga feila';

  @override
  String get errorMessageNotSent => 'Meldinga ikkje send';

  @override
  String get errorMessageEditNotSaved => 'Meldinga ikkje lagra';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Kunne ikkje kopla til server:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Kunne ikkje kopla til';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Det ser ikkje ut til at meldinga finst.';

  @override
  String get errorQuotationFailed => 'Siteringa feila';

  @override
  String errorServerMessage(String message) {
    return 'Serveren sa:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Feil når eg kopla til Zulip. Prøver på nytt…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Feil når eg kopla til Zulip på $serverUrl. Prøver på nytt:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Feil når eg handsama Zulip-hending. Prøver koplinga på nytt…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Feil når eg handsama Zulip-hending frå $serverUrl; prøver på nytt.\n\nFeil: $error\n\nHending: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Kunne ikkje opna lenke';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Kunne ikkje opna lenka: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Kunne ikkje dempa emnet';

  @override
  String get errorUnmuteTopicFailed => 'Kunne ikkje avdempa emnet';

  @override
  String get errorFollowTopicFailed => 'Kunne ikkje fylgja emnet';

  @override
  String get errorUnfollowTopicFailed => 'Kunne ikkje slutta å fylgja emnet';

  @override
  String get errorSharingFailed => 'Kunne ikkje dela';

  @override
  String get errorStarMessageFailedTitle => 'Kunne ikkje stjernemerka meldinga';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Kunne ikkje fjerna stjerne på meldinga';

  @override
  String get errorCouldNotEditMessageTitle => 'Kunne ikkje redigera meldinga';

  @override
  String get successLinkCopied => 'Kopierte lenka';

  @override
  String get successMessageTextCopied => 'Meldingstekst kopiert';

  @override
  String get successMessageLinkCopied => 'Meldingslenke kopiert';

  @override
  String get successTopicLinkCopied => 'Emnelenke kopiert';

  @override
  String get successChannelLinkCopied => 'Kanallenke kopier';

  @override
  String get composeBoxBannerLabelDeactivatedDmRecipient =>
      'Du kan ikkje senda ei melding til deaktiverte brukarar.';

  @override
  String get composeBoxBannerLabelUnknownDmRecipient =>
      'Du kan ikkje senda meldingar til ukjende brukarar.';

  @override
  String get composeBoxBannerLabelCannotSendUnspecifiedReason =>
      'Du kan ikkje senda ei melding her.';

  @override
  String get composeBoxBannerLabelCannotSendInChannel =>
      'Du har ikkje lov til å posta i denne kanalen.';

  @override
  String get composeBoxBannerLabelUnsubscribed =>
      'Svar på meldingane dine dukkar ikkje opp automatisk.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Nye meldingar dukkar ikkje opp automatisk.';

  @override
  String get composeBoxBannerButtonRefresh => 'Oppdater';

  @override
  String get composeBoxBannerButtonSubscribe => 'Abonner';

  @override
  String get composeBoxBannerLabelEditMessage => 'Rediger melding';

  @override
  String get composeBoxBannerButtonCancel => 'Avbryt';

  @override
  String get composeBoxBannerButtonSave => 'Lagre';

  @override
  String get editAlreadyInProgressTitle => 'Kan ikkje redigera melding';

  @override
  String get editAlreadyInProgressMessage =>
      'Ei redigering er alt i gang. Vent til ho er ferdig.';

  @override
  String get savingMessageEditLabel => 'LAGRAR ENDRING…';

  @override
  String get savingMessageEditFailedLabel => 'ENDRINGA IKKJE LAGRA';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Forkast meldinga du skriv?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Når du endrar ei melding forsvinn innhaldet som fanst i tekstfeltet frå før.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Om du hentar tilbake ei usendt melding blir innhaldet som fanst i meldingsfeltet frå før fjerna.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Forkast';

  @override
  String get composeBoxAttachFilesTooltip => 'Legg ved fil';

  @override
  String get composeBoxAttachMediaTooltip => 'Legg ved bilete eller videoar';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Ta eit bilete';

  @override
  String get composeBoxGenericContentHint => 'Skriv ei melding';

  @override
  String get newDmSheetComposeButtonLabel => 'Skriv';

  @override
  String get newDmSheetScreenTitle => 'Ny direktemelding';

  @override
  String get newDmFabButtonLabel => 'Ny direktemelding';

  @override
  String get newDmSheetSearchHintEmpty => 'Legg til ein eller fleire brukarar';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Legg til ein brukar til…';

  @override
  String get newDmSheetNoUsersFound => 'Fann ingen brukarar';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Send melding til @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Send melding til gruppa';

  @override
  String get composeBoxSelfDmContentHint => 'Skriv melding til deg sjølv';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Send melding til $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Førebur…';

  @override
  String get composeBoxSendTooltip => 'Send';

  @override
  String get unknownChannelName => '(ukjend kanal)';

  @override
  String get composeBoxTopicHintText => 'Emne';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Skriv emne (hopp over for “$defaultTopicName”)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Last opp $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(lastar inn melding $messageId)';
  }

  @override
  String get unknownUserName => '(ukjend brukar)';

  @override
  String get dmsWithYourselfPageTitle => 'Direktemeldingar med deg sjølv';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Du og $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'Direktemeldingar med $others';
  }

  @override
  String get emptyMessageList => 'Det finst ingen meldingar her.';

  @override
  String get emptyMessageListCombinedFeed =>
      'Det er ingen meldingar i kombinasjonsstraumen din.';

  @override
  String get emptyMessageListChannelWithoutContentAccess =>
      'Du har ikkje <z-link>tilgang til innhaldet</z-link> i denne kanalen.';

  @override
  String get emptyMessageListChannelUnavailable =>
      'Denne kanalen finst ikkje, eller du har ikkje lov til å sjå han.';

  @override
  String get emptyMessageListSelfDmHeader =>
      'Du har ikkje sendt direktemeldingar til deg sjølv enno!';

  @override
  String get emptyMessageListSelfDmMessage =>
      'Bruk denne plassen for eigne notat, eller for å testa Zulip-funksjonar.';

  @override
  String emptyMessageListDm(String person) {
    return 'Du har ingen direktemeldingar med $person enno.';
  }

  @override
  String emptyMessageListDmDeactivatedUser(String person) {
    return 'Du har ingen direktemeldingar med $person.';
  }

  @override
  String get emptyMessageListDmUnknownUser =>
      'Du har ingen direktemeldingar med denne brukaren.';

  @override
  String get emptyMessageListGroupDm =>
      'Du har ingen direktemeldingar med desse brukarane enno.';

  @override
  String get emptyMessageListGroupDmDeactivatedUser =>
      'Du har ingen direktemeldingar med desse brukarane.';

  @override
  String get emptyMessageListDmStartConversation =>
      'Kvifor ikkje starta samtalen?';

  @override
  String get emptyMessageListMentionsHeader =>
      'Denne visinga inneheld meldingar der du er <z-link>nemnd</z-link>.';

  @override
  String get emptyMessageListMentionsMessage =>
      'For å dra merksemda til ei melding kan du nemna ein brukar, ei gruppe, emnedeltakarar eller alle abonnentar til ein kanal. Skriv @ i meldingsboksen og vel kven du vil nemna i lista over forslag.';

  @override
  String get emptyMessageListStarredHeader =>
      'Du har ingen meldingar med stjerne.';

  @override
  String emptyMessageListStarredMessage(String button) {
    return '<z-link>Å leggja stjerne på</z-link> er ein smart måte å ha oversikt over viktige meldingar på, som oppgåver du må attende til, eller nyttige referansar. For å leggja stjerne på ei melding lang-trykkjer du på henne og trykkjer deretter “$button.”';
  }

  @override
  String get emptyMessageListSearch => 'Ingen søkjeresultat.';

  @override
  String get messageListGroupYouWithYourself => 'Meldingar med deg sjølv';

  @override
  String get contentValidationErrorTooLong =>
      'Meldinga bør ikkje vera lengre enn 10000 teikn.';

  @override
  String get contentValidationErrorEmpty => 'Du har ingen ting å senda!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Vent på at siteringa skal bli ferdig.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Vent på at opplastinga skal bli ferdig.';

  @override
  String get dialogCancel => 'Avbryt';

  @override
  String get dialogContinue => 'Hald fram';

  @override
  String get dialogClose => 'Lukk';

  @override
  String get errorDialogLearnMore => 'Lær meir';

  @override
  String get errorDialogContinue => 'Greidt';

  @override
  String get errorDialogTitle => 'Feil';

  @override
  String get snackBarDetails => 'Detaljar';

  @override
  String get lightboxCopyLinkTooltip => 'Kopier lenke';

  @override
  String get lightboxVideoCurrentPosition => 'Noverande posisjon';

  @override
  String get lightboxVideoDuration => 'Videolengde';

  @override
  String get loginPageTitle => 'Logg inn';

  @override
  String get loginFormSubmitLabel => 'Logg inn';

  @override
  String get loginMethodDivider => 'ELLER';

  @override
  String get loginMethodDividerSemanticLabel => 'Innloggingsalternativ';

  @override
  String signInWithFoo(String method) {
    return 'Logg inn med $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Legg til ein konto';

  @override
  String get loginRealmUrlLabel => 'URL-en til Zulip-organisasjonen din';

  @override
  String get loginRealmUrlHelperText =>
      'This is the address you would use to open Zulip in a browser.';

  @override
  String get loginRealmUrlHelpButton => 'Help';

  @override
  String get loginHidePassword => 'Gøym passordet';

  @override
  String get loginEmailLabel => 'E-postadresse';

  @override
  String get loginErrorMissingEmail => 'Skriv e-postadressa di.';

  @override
  String get loginPasswordLabel => 'Passord';

  @override
  String get loginErrorMissingPassword => 'Skriv inn passordet ditt.';

  @override
  String get loginUsernameLabel => 'Brukarnamn';

  @override
  String get loginErrorMissingUsername => 'Skriv inn brukarnamnet ditt.';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength teikn',
      one: '1 teikn',
    );
    return 'Lenexa på emneteksten kan ikkje vera meir enn $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Emne er påkravd i denne organisasjonen.';

  @override
  String get errorContentNotInsertedTitle => 'Innhaldet ikkje sett inn';

  @override
  String get errorContentToInsertIsEmpty =>
      'Fila som skulle setjast inn er tom eller kan ikkje nåast.';

  @override
  String errorServerVersionNotAllowedMessage(
    String url,
    String zulipVersion,
    String minAllowedZulipVersion,
  ) {
    return '$url køyrer Zulip Server $zulipVersion, som ikkje er støtta. Den eldste støtta versjonen av Zulip Server er $minAllowedZulipVersion.';
  }

  @override
  String serverCompatBannerAdminMessage(String url, String zulipVersion) {
    return '$url køyrer Zulip Server $zulipVersion, som ikkje er støtta. Oppgrader serveren din så snart som råd.';
  }

  @override
  String serverCompatBannerUserMessage(String url, String zulipVersion) {
    return '$url køyrer Zulip Server $zulipVersion, som ikkje er støtta. Ta kontakt med serveradministratoren din om å oppgradera han.';
  }

  @override
  String get serverCompatBannerDismissLabel => 'Ta vekk åtvaringa';

  @override
  String get serverCompatBannerLearnMoreLabel => 'Lær meir';

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Kontoen din på $url kunne ikkje bli autentisert. Prøv å logga inn på nytt eller bruk ein annan konto.';
  }

  @override
  String get errorInvalidResponse => 'Serveren sende eit ugyldig svar.';

  @override
  String get errorNetworkRequestFailed => 'Netverksfeil';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Serveren gav ugyldig svar; HTTP-status $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Serveren gav ugyldig svar; HTTP-status $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Nettverksfeil: HTTP-status $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Kunne ikkje spela video.';

  @override
  String get errorVideoPlayerFailedTryBrowser =>
      'Prøv å opna han i ein nettlesar i staden.';

  @override
  String get dialogOpenInBrowser => 'Opne i nettlesar';

  @override
  String get serverUrlValidationErrorEmpty => 'Skriv ein URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Skriv ein gyldig URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Skriv ein server-URL, ikkje e-postadressa di.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'Server-URL-en må starta med http:// eller https://.';

  @override
  String get spoilerDefaultHeaderText => 'Avsløring';

  @override
  String get markAllAsReadLabel => 'Merk alle meldingane som lesne';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num meldingar som lesne',
      one: '1 melding som lesen',
    );
    return 'Merk $_temp0.';
  }

  @override
  String get markAsReadInProgress => 'Merkjer meldingar som lesne…';

  @override
  String get errorMarkAsReadFailedTitle =>
      'Kunne ikkje merkja meldingar som lesne';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num meldingar som lesne',
      one: '1 melding som lesen',
    );
    return 'Merkte $_temp0.';
  }

  @override
  String get markAsUnreadInProgress => 'Merkjer meldingar som ulesne…';

  @override
  String get errorMarkAsUnreadFailedTitle => 'Kunne ikkje merkja som ulesne';

  @override
  String markAllAsReadConfirmationDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mark $count+ meldingar som lesne?',
      one: 'Merk $count+ melding som lesen?',
    );
    return '$_temp0';
  }

  @override
  String get markAllAsReadConfirmationDialogTitleNoCount =>
      'Merk meldingar som lesne?';

  @override
  String get markAllAsReadConfirmationDialogMessage =>
      'Meldingar i fleire samtaler kan bli påverka.';

  @override
  String get markAllAsReadConfirmationDialogConfirmButton => 'Merk som lesen';

  @override
  String get today => 'I dag';

  @override
  String get yesterday => 'I går';

  @override
  String get userActiveNow => 'Aktiv no';

  @override
  String get userIdle => 'Oppteken';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutt',
      one: '1 minutt',
    );
    return 'Aktiv for $_temp0 sidan';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours timar',
      one: '1 time',
    );
    return 'Aktiv for $_temp0 sidan';
  }

  @override
  String get userActiveYesterday => 'Aktiv i går';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagar',
      one: '1 dag',
    );
    return 'Aktiv for $_temp0 sidan';
  }

  @override
  String userActiveDate(String date) {
    return 'Aktiv $date';
  }

  @override
  String get userNotActiveInYear => 'Ikkje aktiv det siste året';

  @override
  String get invisibleMode => 'Usynleg modus';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Kunne ikkje slå på usynleg modus. Prøv på nytt.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Kunne ikkje slå av usynleg modus. Prøv på nytt.';

  @override
  String get userRoleOwner => 'Eigar';

  @override
  String get userRoleAdministrator => 'Administrator';

  @override
  String get userRoleModerator => 'Moderator';

  @override
  String get userRoleMember => 'Medlem';

  @override
  String get userRoleGuest => 'Gjest';

  @override
  String get userRoleUnknown => 'Ukjent';

  @override
  String get statusButtonLabelStatusSet => 'Status';

  @override
  String get statusButtonLabelStatusUnset => 'Set status';

  @override
  String get noStatusText => 'Ingen statustekst';

  @override
  String get setStatusPageTitle => 'Set status';

  @override
  String get statusClearButtonLabel => 'Fjern';

  @override
  String get statusSaveButtonLabel => 'Lagre';

  @override
  String get statusTextHint => 'Statusen din';

  @override
  String get userStatusBusy => 'Oppteken';

  @override
  String get userStatusInAMeeting => 'I eit møte';

  @override
  String get userStatusCommuting => 'Pendlar';

  @override
  String get userStatusOutSick => 'Sjuk';

  @override
  String get userStatusVacationing => 'På ferie';

  @override
  String get userStatusWorkingRemotely => 'Fjernarbeid';

  @override
  String get userStatusAtTheOffice => 'På kontoret';

  @override
  String get updateStatusErrorTitle =>
      'Kunne ikkje oppdatera brukarstatus. Prøv på nytt.';

  @override
  String get searchMessagesPageTitle => 'Søk';

  @override
  String get searchMessagesHintText => 'Søk';

  @override
  String get searchMessagesClearButtonTooltip => 'Tøm';

  @override
  String get inboxPageTitle => 'Innboks';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'Det er ingen ulesne meldingar i innboksen din.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Bruk knappande nedanfor for å sjå kombistraumen eller ei liste med kanalar.';

  @override
  String get pinnedChannelsFolderName => 'Festa kanalar';

  @override
  String get otherChannelsFolderName => 'Andre kanalar';

  @override
  String get recentDmConversationsPageTitle => 'Direktemeldingar';

  @override
  String get recentDmConversationsPageShortLabel => 'DM-ar';

  @override
  String get recentDmConversationsSectionHeader => 'Direktemeldingar';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'Du har ingen direktemeldingar enno!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Kvifor ikkje starta ei samtale?';

  @override
  String get combinedFeedPageTitle => 'Kombistraum';

  @override
  String get mentionsPageTitle => 'Nemningar';

  @override
  String get starredMessagesPageTitle => 'Stjernemerkte';

  @override
  String get channelsPageTitle => 'Kanalar';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Du tingar ikkje på nokre kanalar enno.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Prøv å gå til <z-link>$allChannelsPageTitle</z-link> og bli med i nokre.';
  }

  @override
  String get shareChooseAccountModalTitle => 'Vel ein konto';

  @override
  String get mainMenuMyProfile => 'Profilen min';

  @override
  String get topicsButtonTooltip => 'Emne';

  @override
  String get channelFeedButtonTooltip => 'Kanalstraum';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers andre',
      one: '1 annan',
    );
    return '$senderFullName til deg og $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Festa';

  @override
  String get unpinnedSubscriptionsLabel => 'Ufesta';

  @override
  String get notifSelfUser => 'Du';

  @override
  String get reactedEmojiSelfUser => 'Du';

  @override
  String get reactionChipsLabel => 'Reaksjonar';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Du og $otherUsersCount andre',
      one: 'Du og 1 annan',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist skriv…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist og $otherTypist skriv…';
  }

  @override
  String get manyPeopleTyping => 'Fleire skriv…';

  @override
  String get wildcardMentionAll => 'alle';

  @override
  String get wildcardMentionEveryone => 'alle';

  @override
  String get wildcardMentionChannel => 'kanal';

  @override
  String get wildcardMentionStream => 'straum';

  @override
  String get wildcardMentionTopic => 'emne';

  @override
  String get wildcardMentionChannelDescription => 'Varsle kanal';

  @override
  String get wildcardMentionStreamDescription => 'Varsle straum';

  @override
  String get wildcardMentionAllDmDescription => 'Varsle mottakarar';

  @override
  String get wildcardMentionTopicDescription => 'Varsle emne';

  @override
  String get systemGroupNameEveryoneOnInternet => 'Alle på Internett';

  @override
  String get systemGroupNameEveryone => 'Alle inklusive gjester';

  @override
  String get systemGroupNameMembers => 'Alle bortsett frå gjester';

  @override
  String get systemGroupNameFullMembers => 'Medlemer';

  @override
  String get systemGroupNameModerators => 'Moderatorar';

  @override
  String get systemGroupNameAdministrators => 'Administratorar';

  @override
  String get systemGroupNameOwners => 'Eigarar';

  @override
  String get systemGroupNameNobody => 'Ingen';

  @override
  String get navBarFeedLabel => 'Straum';

  @override
  String get navBarMenuLabel => 'Meny';

  @override
  String get messageIsEditedLabel => 'REDIGERT';

  @override
  String get messageIsMovedLabel => 'FLYTTA';

  @override
  String get messageNotSentLabel => 'MELDING IKKJE SENDT';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'TEMA';

  @override
  String get themeSettingDark => 'Myrk';

  @override
  String get themeSettingLight => 'Ljos';

  @override
  String get themeSettingSystem => 'System';

  @override
  String get openLinksWithInAppBrowser =>
      'Opne lenkjer med den innebygde nettlesaren';

  @override
  String get pollWidgetQuestionMissing => 'Ingen spørsmål.';

  @override
  String get pollWidgetOptionsMissing =>
      'Denne undersøkinga har ingen alternativ enno.';

  @override
  String get initialAnchorSettingTitle => 'Opne meldingsstraumen med';

  @override
  String get initialAnchorSettingDescription =>
      'Du kan velja om meldingsstraumen skal starta med den fyrste ulesne meldinga eller med den nyaste meldinga.';

  @override
  String get initialAnchorSettingFirstUnreadAlways => 'Fyrste ulesne melding';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Fyrste ulesne melding i samtalevisingar, nyaste melding elles';

  @override
  String get initialAnchorSettingNewestAlways => 'Nyaste melding';

  @override
  String get markReadOnScrollSettingTitle =>
      'Merk meldingar som lesne når du rullar';

  @override
  String get markReadOnScrollSettingDescription =>
      'Når du rullar gjennom meldingar, skal dei automatisk bli merkte som lesne?';

  @override
  String get markReadOnScrollSettingAlways => 'Alltid';

  @override
  String get markReadOnScrollSettingNever => 'Aldri';

  @override
  String get markReadOnScrollSettingConversations => 'Berre i samtalevisingar';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Meldingar vil berre bli automatisk merkte som lesne når du ser på eit enkelt emne eller ei direktemeldingssamtale.';

  @override
  String get experimentalFeatureSettingsPageTitle =>
      'Eksperimentelle funksjonar';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Desse alternativa slår på funksjonar som framleis er under utvikling, og ikkje er ferdige. Det er ikkje sikkert dei fungerer, og dei kan påverka andre delar av appen.\n\nFormålet med desse innstillingane er at Zulip-utviklarane skal kunna eksperimentera.';

  @override
  String get errorNotificationOpenTitle => 'Kunne ikkje opna varsel';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Kontoen knytt til dette varselet kunne ikkje bli funne.';

  @override
  String get errorReactionAddingFailedTitle => 'Kunne ikkje leggja til varsel';

  @override
  String get errorReactionRemovingFailedTitle => 'Kunne ikkje fjerna varsel';

  @override
  String get errorSharingTitle => 'Kunne ikkje dela innhald';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'Det finst ingen innlogga konto. Logg inn på ein konto og prøv på nytt.';

  @override
  String get emojiReactionsMore => 'meir';

  @override
  String get emojiPickerSearchEmoji => 'Søk blandt emojiane';

  @override
  String get noEarlierMessages => 'Ingen eldre meldingar';

  @override
  String get revealButtonLabel => 'Vis melding';

  @override
  String get mutedUser => 'Dempa brukar';

  @override
  String get scrollToBottomTooltip => 'Rull til botna';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';

  @override
  String get topicListEmptyPlaceholderHeader =>
      'Det finst ingen emne her enno.';
}
