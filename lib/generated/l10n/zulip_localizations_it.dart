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
  String get upgradeWelcomeDialogTitle => 'Benvenuti alla nuova app Zulip!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Troverai un\'esperienza familiare in un pacchetto più veloce ed elegante.';

  @override
  String get upgradeWelcomeDialogLinkText =>
      'Date un\'occhiata al post dell\'annuncio sul blog!';

  @override
  String get upgradeWelcomeDialogDismiss => 'Andiamo';

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
  String get actionSheetOptionSeeWhoReacted => 'See who reacted';

  @override
  String get seeWhoReactedSheetNoReactions => 'This message has no reactions.';

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
  String get actionSheetOptionQuoteMessage => 'Cita messaggio';

  @override
  String get actionSheetOptionStarMessage => 'Messaggio speciale';

  @override
  String get actionSheetOptionUnstarMessage => 'Messaggio normale';

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
      other: '$num file sono',
      one: 'file è',
    );
    return '$_temp0 più grande/i del limite del server di $maxFileUploadSizeMib MiB e non verrà/anno caricato/i:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'File',
      one: 'File',
    );
    return '$_temp0 troppo grande/i';
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
    return 'Errore nella gestione di un evento Zulip da $serverUrl; verrà effettuato un nuovo tentativo.\n\nErrore: $error\n\nEvento: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Impossibile aprire il collegamento';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Impossibile aprire il collegamento: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Impossibile silenziare l\'argomento';

  @override
  String get errorUnmuteTopicFailed => 'Impossibile de-silenziare l\'argomento';

  @override
  String get errorFollowTopicFailed => 'Impossibile seguire l\'argomento';

  @override
  String get errorUnfollowTopicFailed =>
      'Impossibile smettere di seguire l\'argomento';

  @override
  String get errorSharingFailed => 'Condivisione fallita';

  @override
  String get errorStarMessageFailedTitle =>
      'Impossibile contrassegnare il messaggio come speciale';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Impossibile contrassegnare il messaggio come normale';

  @override
  String get errorCouldNotEditMessageTitle =>
      'Impossibile modificare il messaggio';

  @override
  String get successLinkCopied => 'Collegamento copiato';

  @override
  String get successMessageTextCopied => 'Testo messaggio copiato';

  @override
  String get successMessageLinkCopied => 'Collegamento messaggio copiato';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Non è possibile inviare messaggi agli utenti disattivati.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'Non hai l\'autorizzazione per postare su questo canale.';

  @override
  String get composeBoxBannerLabelEditMessage => 'Modifica messaggio';

  @override
  String get composeBoxBannerButtonCancel => 'Annulla';

  @override
  String get composeBoxBannerButtonSave => 'Salva';

  @override
  String get editAlreadyInProgressTitle =>
      'Impossibile modificare il messaggio';

  @override
  String get editAlreadyInProgressMessage =>
      'Una modifica è già in corso. Attendere il completamento.';

  @override
  String get savingMessageEditLabel => 'SALVATAGGIO MODIFICA…';

  @override
  String get savingMessageEditFailedLabel => 'MODIFICA NON SALVATA';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Scartare il messaggio che si sta scrivendo?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Quando si modifica un messaggio, il contenuto precedentemente presente nella casella di composizione viene ignorato.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Quando si recupera un messaggio non inviato, il contenuto precedentemente presente nella casella di composizione viene ignorato.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Abbandona';

  @override
  String get composeBoxAttachFilesTooltip => 'Allega file';

  @override
  String get composeBoxAttachMediaTooltip => 'Allega immagini o video';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Fai una foto';

  @override
  String get composeBoxGenericContentHint => 'Batti un messaggio';

  @override
  String get newDmSheetComposeButtonLabel => 'Componi';

  @override
  String get newDmSheetScreenTitle => 'Nuovo MD';

  @override
  String get newDmFabButtonLabel => 'Nuovo MD';

  @override
  String get newDmSheetSearchHintEmpty => 'Aggiungi uno o più utenti';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Aggiungi un altro utente…';

  @override
  String get newDmSheetNoUsersFound => 'Nessun utente trovato';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Messaggia @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Gruppo di messaggi';

  @override
  String get composeBoxSelfDmContentHint => 'Annota qualcosa';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Messaggia $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Preparazione…';

  @override
  String get composeBoxSendTooltip => 'Invia';

  @override
  String get unknownChannelName => '(canale sconosciuto)';

  @override
  String get composeBoxTopicHintText => 'Argomento';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Inserisci un argomento (salta per \"$defaultTopicName\")';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Caricamento $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(caricamento messaggio $messageId)';
  }

  @override
  String get unknownUserName => '(utente sconosciuto)';

  @override
  String get dmsWithYourselfPageTitle => 'MD con te stesso';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Tu e $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'MD con $others';
  }

  @override
  String get emptyMessageList => 'There are no messages here.';

  @override
  String get emptyMessageListSearch => 'No search results.';

  @override
  String get messageListGroupYouWithYourself => 'Messaggi con te stesso';

  @override
  String get contentValidationErrorTooLong =>
      'La lunghezza del messaggio non deve essere superiore a 10.000 caratteri.';

  @override
  String get contentValidationErrorEmpty => 'Non devi inviare nulla!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Attendere il completamento del commento.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Attendere il completamento del caricamento.';

  @override
  String get dialogCancel => 'Annulla';

  @override
  String get dialogContinue => 'Continua';

  @override
  String get dialogClose => 'Chiudi';

  @override
  String get errorDialogLearnMore => 'Scopri di più';

  @override
  String get errorDialogContinue => 'Ok';

  @override
  String get errorDialogTitle => 'Errore';

  @override
  String get snackBarDetails => 'Dettagli';

  @override
  String get lightboxCopyLinkTooltip => 'Copia collegamento';

  @override
  String get lightboxVideoCurrentPosition => 'Posizione corrente';

  @override
  String get lightboxVideoDuration => 'Durata video';

  @override
  String get loginPageTitle => 'Accesso';

  @override
  String get loginFormSubmitLabel => 'Accesso';

  @override
  String get loginMethodDivider => 'O';

  @override
  String signInWithFoo(String method) {
    return 'Accedi con $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Aggiungi account';

  @override
  String get loginServerUrlLabel => 'URL del server Zulip';

  @override
  String get loginHidePassword => 'Nascondi password';

  @override
  String get loginEmailLabel => 'Indirizzo email';

  @override
  String get loginErrorMissingEmail => 'Inserire l\'email.';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginErrorMissingPassword => 'Inserire la propria password.';

  @override
  String get loginUsernameLabel => 'Nomeutente';

  @override
  String get loginErrorMissingUsername => 'Inserire il proprio nomeutente.';

  @override
  String get topicValidationErrorTooLong =>
      'La lunghezza dell\'argomento non deve superare i 60 caratteri.';

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'In questa organizzazione sono richiesti degli argomenti.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url sta usando Zulip Server $zulipVersion, che non è supportato. La versione minima supportata è Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'L\'account su $url non è stato autenticato. Riprovare ad accedere o provare a usare un altro account.';
  }

  @override
  String get errorInvalidResponse =>
      'Il server ha inviato una risposta non valida.';

  @override
  String get errorNetworkRequestFailed => 'Richiesta di rete non riuscita';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Il server ha fornito una risposta non valida; stato HTTP $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Il server ha fornito una risposta non valida; stato HTTP $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Richiesta di rete non riuscita: stato HTTP $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Impossibile riprodurre il video.';

  @override
  String get serverUrlValidationErrorEmpty => 'Inserire un URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Inserire un URL valido.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Inserire l\'URL del server, non il proprio indirizzo email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'L\'URL del server deve iniziare con http:// o https://.';

  @override
  String get spoilerDefaultHeaderText => 'Spoiler';

  @override
  String get markAllAsReadLabel => 'Segna tutti i messaggi come letti';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messagei',
      one: '1 messaggio',
    );
    return 'Segnato/i $_temp0 come letto/i.';
  }

  @override
  String get markAsReadInProgress => 'Contrassegno dei messaggi come letti…';

  @override
  String get errorMarkAsReadFailedTitle =>
      'Contrassegno come letto non riuscito';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messagi',
      one: '1 messaggio',
    );
    return 'Segnato/i $_temp0 come non letto/i.';
  }

  @override
  String get markAsUnreadInProgress =>
      'Contrassegno dei messaggi come non letti…';

  @override
  String get errorMarkAsUnreadFailedTitle =>
      'Contrassegno come non letti non riuscito';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get invisibleMode => 'Invisible mode';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Error turning on invisible mode. Please try again.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Error turning off invisible mode. Please try again.';

  @override
  String get userRoleOwner => 'Proprietario';

  @override
  String get userRoleAdministrator => 'Amministratore';

  @override
  String get userRoleModerator => 'Moderatore';

  @override
  String get userRoleMember => 'Membro';

  @override
  String get userRoleGuest => 'Ospite';

  @override
  String get userRoleUnknown => 'Sconosciuto';

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
  String get inboxEmptyPlaceholder =>
      'Non ci sono messaggi non letti nella posta in arrivo. Usare i pulsanti sotto per visualizzare il feed combinato o l\'elenco dei canali.';

  @override
  String get recentDmConversationsPageTitle => 'Messaggi diretti';

  @override
  String get recentDmConversationsSectionHeader => 'Messaggi diretti';

  @override
  String get recentDmConversationsEmptyPlaceholder =>
      'Non ci sono ancora messaggi diretti! Perché non iniziare la conversazione?';

  @override
  String get combinedFeedPageTitle => 'Feed combinato';

  @override
  String get mentionsPageTitle => 'Menzioni';

  @override
  String get starredMessagesPageTitle => 'Messaggi speciali';

  @override
  String get channelsPageTitle => 'Canali';

  @override
  String get channelsEmptyPlaceholder =>
      'Non sei ancora iscritto ad alcun canale.';

  @override
  String get mainMenuMyProfile => 'Il mio profilo';

  @override
  String get topicsButtonTooltip => 'Argomenti';

  @override
  String get channelFeedButtonTooltip => 'Feed del canale';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers altri',
      one: '1 altro',
    );
    return '$senderFullName a te e $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Bloccato';

  @override
  String get unpinnedSubscriptionsLabel => 'Non bloccato';

  @override
  String get notifSelfUser => 'Tu';

  @override
  String get reactedEmojiSelfUser => 'Tu';

  @override
  String onePersonTyping(String typist) {
    return '$typist sta scrivendo…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist e $otherTypist stanno scrivendo…';
  }

  @override
  String get manyPeopleTyping => 'Molte persone stanno scrivendo…';

  @override
  String get wildcardMentionAll => 'tutti';

  @override
  String get wildcardMentionEveryone => 'ognuno';

  @override
  String get wildcardMentionChannel => 'canale';

  @override
  String get wildcardMentionStream => 'flusso';

  @override
  String get wildcardMentionTopic => 'argomento';

  @override
  String get wildcardMentionChannelDescription => 'Notifica canale';

  @override
  String get wildcardMentionStreamDescription => 'Notifica flusso';

  @override
  String get wildcardMentionAllDmDescription => 'Notifica destinatari';

  @override
  String get wildcardMentionTopicDescription => 'Notifica argomento';

  @override
  String get messageIsEditedLabel => 'MODIFICATO';

  @override
  String get messageIsMovedLabel => 'SPOSTATO';

  @override
  String get messageNotSentLabel => 'MESSAGGIO NON INVIATO';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'TEMA';

  @override
  String get themeSettingDark => 'Scuro';

  @override
  String get themeSettingLight => 'Chiaro';

  @override
  String get themeSettingSystem => 'Sistema';

  @override
  String get openLinksWithInAppBrowser =>
      'Apri i collegamenti con il browser in-app';

  @override
  String get pollWidgetQuestionMissing => 'Nessuna domanda.';

  @override
  String get pollWidgetOptionsMissing =>
      'Questo sondaggio non ha ancora opzioni.';

  @override
  String get initialAnchorSettingTitle => 'Apri i feed dei messaggi su';

  @override
  String get initialAnchorSettingDescription =>
      'È possibile scegliere se i feed dei messaggi devono aprirsi al primo messaggio non letto oppure ai messaggi più recenti.';

  @override
  String get initialAnchorSettingFirstUnreadAlways =>
      'Primo messaggio non letto';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Primo messaggio non letto nelle singole conversazioni, messaggio più recente altrove';

  @override
  String get initialAnchorSettingNewestAlways => 'Messaggio più recente';

  @override
  String get markReadOnScrollSettingTitle =>
      'Segna i messaggi come letti durante lo scorrimento';

  @override
  String get markReadOnScrollSettingDescription =>
      'Quando si scorrono i messaggi, questi devono essere contrassegnati automaticamente come letti?';

  @override
  String get markReadOnScrollSettingAlways => 'Sempre';

  @override
  String get markReadOnScrollSettingNever => 'Mai';

  @override
  String get markReadOnScrollSettingConversations =>
      'Solo nelle visualizzazioni delle conversazioni';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'I messaggi verranno automaticamente contrassegnati come in sola lettura quando si visualizza un singolo argomento o una conversazione in un messaggio diretto.';

  @override
  String get experimentalFeatureSettingsPageTitle =>
      'Caratteristiche sperimentali';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Queste opzioni abilitano funzionalità ancora in fase di sviluppo e non ancora pronte. Potrebbero non funzionare e causare problemi in altre aree dell\'app.\n\nQueste impostazioni sono pensate per la sperimentazione da parte di chi lavora allo sviluppo di Zulip.';

  @override
  String get errorNotificationOpenTitle => 'Impossibile aprire la notifica';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Impossibile trovare l\'account associato a questa notifica.';

  @override
  String get errorReactionAddingFailedTitle =>
      'Aggiunta della reazione non riuscita';

  @override
  String get errorReactionRemovingFailedTitle =>
      'Rimozione della reazione non riuscita';

  @override
  String get emojiReactionsMore => 'altro';

  @override
  String get emojiPickerSearchEmoji => 'Cerca emoji';

  @override
  String get noEarlierMessages => 'Nessun messaggio precedente';

  @override
  String get revealButtonLabel => 'Mostra messaggio per mittente silenziato';

  @override
  String get mutedUser => 'Utente silenziato';

  @override
  String get scrollToBottomTooltip => 'Scorri fino in fondo';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
