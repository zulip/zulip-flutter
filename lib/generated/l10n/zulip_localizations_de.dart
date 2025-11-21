// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class ZulipLocalizationsDe extends ZulipLocalizations {
  ZulipLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get aboutPageTitle => 'Über Zulip';

  @override
  String get aboutPageAppVersion => 'App-Version';

  @override
  String get aboutPageOpenSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get aboutPageTapToView => 'Antippen zum Ansehen';

  @override
  String get upgradeWelcomeDialogTitle => 'Willkommen in der neuen Zulip-App!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Du wirst ein vertrautes Erlebnis in einer schnelleren, schlankeren App erleben.';

  @override
  String get upgradeWelcomeDialogLinkText =>
      'Sieh dir den Ankündigungs-Blogpost an!';

  @override
  String get upgradeWelcomeDialogDismiss => 'Los gehts';

  @override
  String get chooseAccountPageTitle => 'Konto auswählen';

  @override
  String get settingsPageTitle => 'Einstellungen';

  @override
  String get switchAccountButton => 'Konto wechseln';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Dein Account bei $url benötigt einige Zeit zum Laden.';
  }

  @override
  String get tryAnotherAccountButton => 'Anderen Account ausprobieren';

  @override
  String get chooseAccountPageLogOutButton => 'Abmelden';

  @override
  String get logOutConfirmationDialogTitle => 'Abmelden?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Um diesen Account in Zukunft zu verwenden, musst du die URL deiner Organisation und deine Account-Informationen erneut eingeben.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Abmelden';

  @override
  String get chooseAccountButtonAddAnAccount => 'Account hinzufügen';

  @override
  String get navButtonAllChannels => 'Alle Kanäle';

  @override
  String get allChannelsPageTitle => 'Alle Kanäle';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'Es gibt keine Kanäle, die du in dieser Organisation anzeigen könntest.';

  @override
  String get profileButtonSendDirectMessage => 'Direktnachricht senden';

  @override
  String get errorCouldNotShowUserProfile =>
      'Nutzerprofil kann nicht angezeigt werden.';

  @override
  String get permissionsNeededTitle => 'Berechtigungen erforderlich';

  @override
  String get permissionsNeededOpenSettings => 'Einstellungen öffnen';

  @override
  String get permissionsDeniedCameraAccess =>
      'Bitte gewähre Zulip zusätzliche Berechtigungen in den Einstellungen, um ein Bild hochzuladen.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Bitte gewähre Zulip zusätzliche Berechtigungen in den Einstellungen, um Dateien hochzuladen.';

  @override
  String get actionSheetOptionSubscribe => 'Abonnieren';

  @override
  String get subscribeFailedTitle => 'Konnte nicht abonnieren';

  @override
  String get actionSheetOptionMarkChannelAsRead =>
      'Kanal als gelesen markieren';

  @override
  String get actionSheetOptionCopyChannelLink => 'Link zum Kanal kopieren';

  @override
  String get actionSheetOptionListOfTopics => 'Themenliste';

  @override
  String get actionSheetOptionChannelFeed => 'Kanal-Feed';

  @override
  String get actionSheetOptionUnsubscribe => 'Deabonnieren';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return '$channelName deabonnieren?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Sobald du diesen Kanal verlässt, kannst du ihm nicht mehr beitreten.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Deabonnieren';

  @override
  String get unsubscribeFailedTitle => 'Konnte nicht deabonnieren';

  @override
  String get actionSheetOptionMuteTopic => 'Thema stummschalten';

  @override
  String get actionSheetOptionUnmuteTopic => 'Thema lautschalten';

  @override
  String get actionSheetOptionFollowTopic => 'Thema folgen';

  @override
  String get actionSheetOptionUnfollowTopic => 'Thema entfolgen';

  @override
  String get actionSheetOptionResolveTopic => 'Als gelöst markieren';

  @override
  String get actionSheetOptionUnresolveTopic => 'Als ungelöst markieren';

  @override
  String get errorResolveTopicFailedTitle =>
      'Thema konnte nicht als gelöst markiert werden';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Thema konnte nicht als ungelöst markiert werden';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Wer hat reagiert';

  @override
  String get seeWhoReactedSheetNoReactions =>
      'Diese Nachricht hat keine Reaktionen.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Emoji-Reaktionen (insgesamt $num)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num Stimmen',
      one: '1 Stimme',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Stimmen für $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts =>
      'Empfangsbestätigungen ansehen';

  @override
  String get actionSheetReadReceipts => 'Empfangsbestätigungen';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Diese Nachricht wurde von $count Personen <z-link>gelesen</z-link>:',
      one: 'Diese Nachricht wurde von einer Person <z-link>gelesen</z-link>:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Niemand hat diese Nachricht bisher gelesen.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Laden von Empfangsbestätigungen fehlgeschlagen.';

  @override
  String get actionSheetOptionCopyMessageText => 'Nachrichtentext kopieren';

  @override
  String get actionSheetOptionCopyMessageLink => 'Link zur Nachricht kopieren';

  @override
  String get actionSheetOptionMarkAsUnread => 'Ab hier als ungelesen markieren';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Stummgeschaltete Nachricht wieder ausblenden';

  @override
  String get actionSheetOptionShare => 'Teilen';

  @override
  String get actionSheetOptionQuoteMessage => 'Nachricht zitieren';

  @override
  String get actionSheetOptionStarMessage => 'Nachricht markieren';

  @override
  String get actionSheetOptionUnstarMessage => 'Markierung aufheben';

  @override
  String get actionSheetOptionEditMessage => 'Nachricht bearbeiten';

  @override
  String get actionSheetOptionDeleteMessage => 'Nachricht löschen';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Nachricht löschen?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Das Löschen einer Nachricht entfernt diese permanent für alle Nutzer:innen.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Löschen';

  @override
  String get errorDeleteMessageFailedTitle =>
      'Löschen der Nachricht fehlgeschlagen';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Thema als gelesen markieren';

  @override
  String get actionSheetOptionCopyTopicLink => 'Link zum Thema kopieren';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errorWebAuthOperationalError =>
      'Ein unerwarteter Fehler ist aufgetreten.';

  @override
  String get errorAccountLoggedInTitle => 'Account bereits angemeldet';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Der Account $email auf $server ist bereits in deiner Account-Liste.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Konnte Nachrichtenquelle nicht abrufen.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Konnte nicht auf die hochgeladene Datei zugreifen';

  @override
  String get errorCopyingFailed => 'Kopieren fehlgeschlagen';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Fehler beim Upload der Datei: $filename';
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
      other: '$num Dateien sind',
      one: 'Datei ist',
    );
    String _temp1 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num werden',
      one: 'wird',
    );
    return '$_temp0 größer als das Serverlimit von $maxFileUploadSizeMib MiB und $_temp1 nicht hochgeladen:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Dateien',
      one: 'Datei',
    );
    return '$_temp0 zu groß';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Ungültige Eingabe';

  @override
  String get errorLoginFailedTitle => 'Anmeldung fehlgeschlagen';

  @override
  String get errorMessageNotSent => 'Nachricht nicht versendet';

  @override
  String get errorMessageEditNotSaved => 'Nachricht nicht gespeichert';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Verbindung zu Server fehlgeschlagen:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Konnte nicht verbinden';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Diese Nachricht scheint nicht zu existieren.';

  @override
  String get errorQuotationFailed => 'Zitat fehlgeschlagen';

  @override
  String errorServerMessage(String message) {
    return 'Der Server sagte:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Fehler beim Verbinden mit Zulip. Wiederhole…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Fehler beim Verbinden mit Zulip auf $serverUrl. Wird wiederholt:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Fehler beim Verarbeiten eines Zulip-Ereignisses. Wiederhole Verbindung…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Fehler beim Verarbeiten eines Zulip-Ereignisses von $serverUrl; Wird wiederholt.\n\nFehler: $error\n\nEreignis: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Link kann nicht geöffnet werden';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Link konnte nicht geöffnet werden: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Konnte Thema nicht stummschalten';

  @override
  String get errorUnmuteTopicFailed => 'Konnte Thema nicht lautschalten';

  @override
  String get errorFollowTopicFailed => 'Konnte Thema nicht folgen';

  @override
  String get errorUnfollowTopicFailed => 'Konnte Thema nicht entfolgen';

  @override
  String get errorSharingFailed => 'Teilen fehlgeschlagen';

  @override
  String get errorStarMessageFailedTitle => 'Konnte Nachricht nicht markieren';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Konnte Markierung nicht von der Nachricht entfernen';

  @override
  String get errorCouldNotEditMessageTitle =>
      'Konnte Nachricht nicht bearbeiten';

  @override
  String get successLinkCopied => 'Link kopiert';

  @override
  String get successMessageTextCopied => 'Nachrichtentext kopiert';

  @override
  String get successMessageLinkCopied => 'Nachrichtenlink kopiert';

  @override
  String get successTopicLinkCopied => 'Link zum Thema kopiert';

  @override
  String get successChannelLinkCopied => 'Kanallink kopiert';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Du kannst keine Nachrichten an deaktivierte Nutzer:innen senden.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'Du hast keine Berechtigung in diesen Kanal zu schreiben.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Neue Nachrichten werden nicht automatisch angezeigt.';

  @override
  String get composeBoxBannerButtonRefresh => 'Auffrischen';

  @override
  String get composeBoxBannerButtonSubscribe => 'Abonnieren';

  @override
  String get composeBoxBannerLabelEditMessage => 'Nachricht bearbeiten';

  @override
  String get composeBoxBannerButtonCancel => 'Abbrechen';

  @override
  String get composeBoxBannerButtonSave => 'Speichern';

  @override
  String get editAlreadyInProgressTitle => 'Kann Nachricht nicht bearbeiten';

  @override
  String get editAlreadyInProgressMessage =>
      'Eine Bearbeitung läuft gerade. Bitte warte bis sie abgeschlossen ist.';

  @override
  String get savingMessageEditLabel => 'SPEICHERE BEARBEITUNG…';

  @override
  String get savingMessageEditFailedLabel => 'BEARBEITUNG NICHT GESPEICHERT';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Die Nachricht, die du schreibst, verwerfen?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Wenn du eine Nachricht bearbeitest, wird der vorherige Inhalt der Nachrichteneingabe verworfen.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Wenn du eine nicht gesendete Nachricht wiederherstellst, wird der vorherige Inhalt der Nachrichteneingabe verworfen.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Verwerfen';

  @override
  String get composeBoxAttachFilesTooltip => 'Dateien anhängen';

  @override
  String get composeBoxAttachMediaTooltip => 'Bilder oder Videos anhängen';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Ein Foto aufnehmen';

  @override
  String get composeBoxGenericContentHint => 'Eine Nachricht eingeben';

  @override
  String get newDmSheetComposeButtonLabel => 'Verfassen';

  @override
  String get newDmSheetScreenTitle => 'Neue DN';

  @override
  String get newDmFabButtonLabel => 'Neue DN';

  @override
  String get newDmSheetSearchHintEmpty =>
      'Füge ein oder mehrere Nutzer:innen hinzu';

  @override
  String get newDmSheetSearchHintSomeSelected =>
      'Füge weitere Nutzer:in hinzu…';

  @override
  String get newDmSheetNoUsersFound => 'Keine Nutzer:innen gefunden';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Nachricht an @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Nachricht an Gruppe';

  @override
  String get composeBoxSelfDmContentHint => 'Schreibe dir selbst eine Notiz';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Nachricht an $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Bereite vor…';

  @override
  String get composeBoxSendTooltip => 'Senden';

  @override
  String get unknownChannelName => '(unbekannter Kanal)';

  @override
  String get composeBoxTopicHintText => 'Thema';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Gib ein Thema ein (leer lassen für “$defaultTopicName”)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Lade $filename hoch…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(lade Nachricht $messageId)';
  }

  @override
  String get unknownUserName => '(Nutzer:in unbekannt)';

  @override
  String get dmsWithYourselfPageTitle => 'DNs mit dir selbst';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Du und $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'DNs mit $others';
  }

  @override
  String get emptyMessageList => 'Hier gibt es keine Nachrichten.';

  @override
  String get emptyMessageListSearch => 'Keine Suchergebnisse.';

  @override
  String get messageListGroupYouWithYourself => 'Nachrichten mit dir selbst';

  @override
  String get contentValidationErrorTooLong =>
      'Nachrichtenlänge sollte nicht größer als 10000 Zeichen sein.';

  @override
  String get contentValidationErrorEmpty => 'Du hast nichts zum Senden!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Bitte warte bis das Zitat abgeschlossen ist.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Bitte warte bis das Hochladen abgeschlossen ist.';

  @override
  String get dialogCancel => 'Abbrechen';

  @override
  String get dialogContinue => 'Fortsetzen';

  @override
  String get dialogClose => 'Schließen';

  @override
  String get errorDialogLearnMore => 'Mehr erfahren';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Fehler';

  @override
  String get snackBarDetails => 'Details';

  @override
  String get lightboxCopyLinkTooltip => 'Link kopieren';

  @override
  String get lightboxVideoCurrentPosition => 'Aktuelle Position';

  @override
  String get lightboxVideoDuration => 'Videolänge';

  @override
  String get loginPageTitle => 'Anmelden';

  @override
  String get loginFormSubmitLabel => 'Anmelden';

  @override
  String get loginMethodDivider => 'ODER';

  @override
  String signInWithFoo(String method) {
    return 'Anmelden mit $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Account hinzufügen';

  @override
  String get loginServerUrlLabel => 'Deine Zulip Server URL';

  @override
  String get loginHidePassword => 'Passwort verstecken';

  @override
  String get loginEmailLabel => 'E-Mail-Adresse';

  @override
  String get loginErrorMissingEmail => 'Bitte gib deine E-Mail ein.';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginErrorMissingPassword => 'Bitte gib dein Passwort ein.';

  @override
  String get loginUsernameLabel => 'Benutzername';

  @override
  String get loginErrorMissingUsername => 'Bitte gib deinen Benutzernamen ein.';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength Zeichen',
      one: '1 Zeichen',
    );
    return 'Länge des Themas sollte $_temp0 nicht überschreiten.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Themen sind in dieser Organisation erforderlich.';

  @override
  String get errorContentNotInsertedTitle => 'Inhalt nicht eingefügt';

  @override
  String get errorContentToInsertIsEmpty =>
      'Die einzufügende Datei ist leer oder kann nicht geöffnet werden.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url nutzt Zulip Server $zulipVersion, welche nicht unterstützt wird. Die unterstützte Mindestversion ist Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Dein Account bei $url konnte nicht authentifiziert werden. Bitte wiederhole die Anmeldung oder verwende einen anderen Account.';
  }

  @override
  String get errorInvalidResponse =>
      'Der Server hat eine ungültige Antwort gesendet.';

  @override
  String get errorNetworkRequestFailed => 'Netzwerkanfrage fehlgeschlagen';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Server lieferte fehlerhafte Antwort; HTTP Status $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Server lieferte fehlerhafte Antwort; HTTP Status $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Netzwerkanfrage fehlgeschlagen: HTTP Status $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed =>
      'Video konnte nicht wiedergegeben werden.';

  @override
  String get serverUrlValidationErrorEmpty => 'Bitte gib eine URL ein.';

  @override
  String get serverUrlValidationErrorInvalidUrl =>
      'Bitte gib eine gültige URL ein.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Bitte gib die Server-URL ein, nicht deine E-Mail-Adresse.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'Die Server-URL muss mit http:// oder https:// beginnen.';

  @override
  String get spoilerDefaultHeaderText => 'Spoiler';

  @override
  String get markAllAsReadLabel => 'Alle Nachrichten als gelesen markieren';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num Nachrichten',
      one: 'Eine Nachricht',
    );
    return '$_temp0 als gelesen markiert.';
  }

  @override
  String get markAsReadInProgress => 'Nachrichten werden als gelesen markiert…';

  @override
  String get errorMarkAsReadFailedTitle =>
      'Als gelesen markieren fehlgeschlagen';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num Nachrichten',
      one: 'Eine Nachricht',
    );
    return '$_temp0 als ungelesen markiert.';
  }

  @override
  String get markAsUnreadInProgress =>
      'Nachrichten werden als ungelesen markiert…';

  @override
  String get errorMarkAsUnreadFailedTitle =>
      'Als ungelesen markieren fehlgeschlagen';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get userActiveNow => 'Gerade aktiv';

  @override
  String get userIdle => 'Untätig';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: 'einer Minute',
    );
    return 'Aktiv vor $_temp0';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: 'einer Stunde',
    );
    return 'Aktiv vor $_temp0';
  }

  @override
  String get userActiveYesterday => 'Gestern aktiv';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: 'einem Tag',
    );
    return 'Aktiv vor $_temp0';
  }

  @override
  String userActiveDate(String date) {
    return 'Aktiv $date';
  }

  @override
  String get userNotActiveInYear => 'Im letzten Jahr nicht aktiv';

  @override
  String get invisibleMode => 'Unsichtbarer Modus';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Fehler beim Einschalten des unsichtbaren Modus. Bitte versuche es erneut.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Fehler beim Ausschalten des unsichtbaren Modus. Bitte versuche es erneut.';

  @override
  String get userRoleOwner => 'Besitzer';

  @override
  String get userRoleAdministrator => 'Administrator';

  @override
  String get userRoleModerator => 'Moderator';

  @override
  String get userRoleMember => 'Mitglied';

  @override
  String get userRoleGuest => 'Gast';

  @override
  String get userRoleUnknown => 'Unbekannt';

  @override
  String get statusButtonLabelStatusSet => 'Status';

  @override
  String get statusButtonLabelStatusUnset => 'Status setzen';

  @override
  String get noStatusText => 'Kein Statustext';

  @override
  String get setStatusPageTitle => 'Status setzen';

  @override
  String get statusClearButtonLabel => 'Leeren';

  @override
  String get statusSaveButtonLabel => 'Speichern';

  @override
  String get statusTextHint => 'Dein Status';

  @override
  String get userStatusBusy => 'Beschäftigt';

  @override
  String get userStatusInAMeeting => 'In einem Meeting';

  @override
  String get userStatusCommuting => 'Unterwegs';

  @override
  String get userStatusOutSick => 'Krankgemeldet';

  @override
  String get userStatusVacationing => 'Im Urlaub';

  @override
  String get userStatusWorkingRemotely => 'Arbeitet von zu Hause';

  @override
  String get userStatusAtTheOffice => 'Im Büro';

  @override
  String get updateStatusErrorTitle =>
      'Fehler beim Update des Benutzerstatus. Bitte versuche es nochmal.';

  @override
  String get searchMessagesPageTitle => 'Suche';

  @override
  String get searchMessagesHintText => 'Suche';

  @override
  String get searchMessagesClearButtonTooltip => 'Leeren';

  @override
  String get inboxPageTitle => 'Eingang';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'Es gibt keine ungelesenen Nachrichten in deinem Posteingang.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Nutze die Buttons unten, um den kombinierten Feed oder die Liste der Kanäle anzuzeigen.';

  @override
  String get recentDmConversationsPageTitle => 'Direktnachrichten';

  @override
  String get recentDmConversationsSectionHeader => 'Direktnachrichten';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'Du hast noch keine Direktnachrichten!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Warum beginnst du nicht einfach eine Unterhaltung?';

  @override
  String get combinedFeedPageTitle => 'Kombinierter Feed';

  @override
  String get mentionsPageTitle => 'Erwähnungen';

  @override
  String get starredMessagesPageTitle => 'Markierte Nachrichten';

  @override
  String get channelsPageTitle => 'Kanäle';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Du hast noch keine Kanäle abonniert.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Versuche, nach <z-link>$allChannelsPageTitle</z-link> zu gehen und einigen davon beizutreten.';
  }

  @override
  String get sharePageTitle => 'Teilen';

  @override
  String get mainMenuMyProfile => 'Mein Profil';

  @override
  String get topicsButtonTooltip => 'Themen';

  @override
  String get channelFeedButtonTooltip => 'Kanal-Feed';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers weitere',
      one: '1 weitere:n',
    );
    return '$senderFullName an dich und $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Angeheftet';

  @override
  String get unpinnedSubscriptionsLabel => 'Nicht angeheftet';

  @override
  String get notifSelfUser => 'Du';

  @override
  String get reactedEmojiSelfUser => 'Du';

  @override
  String get reactionChipsLabel => 'Reaktionen';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Du und $otherUsersCount weitere',
      one: 'Du und ein weiterer',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist tippt…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist und $otherTypist tippen…';
  }

  @override
  String get manyPeopleTyping => 'Mehrere Leute tippen…';

  @override
  String get wildcardMentionAll => 'alle';

  @override
  String get wildcardMentionEveryone => 'jeder';

  @override
  String get wildcardMentionChannel => 'Kanal';

  @override
  String get wildcardMentionStream => 'Stream';

  @override
  String get wildcardMentionTopic => 'Thema';

  @override
  String get wildcardMentionChannelDescription => 'Kanal benachrichtigen';

  @override
  String get wildcardMentionStreamDescription => 'Stream benachrichtigen';

  @override
  String get wildcardMentionAllDmDescription => 'Empfänger benachrichtigen';

  @override
  String get wildcardMentionTopicDescription => 'Thema benachrichtigen';

  @override
  String get messageIsEditedLabel => 'BEARBEITET';

  @override
  String get messageIsMovedLabel => 'VERSCHOBEN';

  @override
  String get messageNotSentLabel => 'NACHRICHT NICHT GESENDET';

  @override
  String pollVoterNames(String voterNames) {
    return '$voterNames';
  }

  @override
  String get themeSettingTitle => 'THEMA';

  @override
  String get themeSettingDark => 'Dunkel';

  @override
  String get themeSettingLight => 'Hell';

  @override
  String get themeSettingSystem => 'System';

  @override
  String get openLinksWithInAppBrowser => 'Links mit In-App-Browser öffnen';

  @override
  String get pollWidgetQuestionMissing => 'Keine Frage.';

  @override
  String get pollWidgetOptionsMissing =>
      'Diese Umfrage hat noch keine Optionen.';

  @override
  String get initialAnchorSettingTitle => 'Nachrichten-Feed öffnen bei';

  @override
  String get initialAnchorSettingDescription =>
      'Du kannst auswählen ob Nachrichten-Feeds bei deiner ersten ungelesenen oder bei den neuesten Nachrichten geöffnet werden.';

  @override
  String get initialAnchorSettingFirstUnreadAlways =>
      'Erste ungelesene Nachricht';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Erste ungelesene Nachricht in Unterhaltungsansicht, sonst neueste Nachricht';

  @override
  String get initialAnchorSettingNewestAlways => 'Neueste Nachricht';

  @override
  String get markReadOnScrollSettingTitle =>
      'Nachrichten beim Scrollen als gelesen markieren';

  @override
  String get markReadOnScrollSettingDescription =>
      'Sollen Nachrichten automatisch als gelesen markiert werden, wenn du sie durchscrollst?';

  @override
  String get markReadOnScrollSettingAlways => 'Immer';

  @override
  String get markReadOnScrollSettingNever => 'Nie';

  @override
  String get markReadOnScrollSettingConversations =>
      'Nur in Unterhaltungsansichten';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Nachrichten werden nur beim Ansehen einzelner Themen oder Direktnachrichten automatisch als gelesen markiert.';

  @override
  String get experimentalFeatureSettingsPageTitle =>
      'Experimentelle Funktionen';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Diese Optionen aktivieren Funktionen, die noch in Entwicklung und nicht bereit sind. Sie funktionieren möglicherweise nicht und können Problem in anderen Bereichen der App verursachen.\n\nDer Zweck dieser Einstellungen ist das Experimentieren der Leute, die an der Entwicklung von Zulip arbeiten.';

  @override
  String get errorNotificationOpenTitle =>
      'Fehler beim Öffnen der Benachrichtigung';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Der Account, der mit dieser Benachrichtigung verknüpft ist, konnte nicht gefunden werden.';

  @override
  String get errorReactionAddingFailedTitle =>
      'Hinzufügen der Reaktion fehlgeschlagen';

  @override
  String get errorReactionRemovingFailedTitle =>
      'Entfernen der Reaktion fehlgeschlagen';

  @override
  String get errorSharingTitle => 'Teilen des Inhalts fehlgeschlagen';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'Es ist kein Konto angemeldet. Bitte logge dich in ein Konto ein und versuche es erneut.';

  @override
  String get emojiReactionsMore => 'mehr';

  @override
  String get emojiPickerSearchEmoji => 'Emoji suchen';

  @override
  String get noEarlierMessages => 'Keine früheren Nachrichten';

  @override
  String get revealButtonLabel => 'Nachricht anzeigen';

  @override
  String get mutedUser => 'Stummgeschaltete:r Nutzer:in';

  @override
  String get scrollToBottomTooltip => 'Nach unten Scrollen';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
