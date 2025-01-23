// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class ZulipLocalizationsPl extends ZulipLocalizations {
  ZulipLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get aboutPageTitle => 'O Zulip';

  @override
  String get aboutPageAppVersion => 'Wydanie apki';

  @override
  String get aboutPageOpenSourceLicenses => 'Licencje otwartego źródła';

  @override
  String get aboutPageTapToView => 'Dotknij, aby pokazać';

  @override
  String get chooseAccountPageTitle => 'Wybierz konto';

  @override
  String get switchAccountButton => 'Przełącz konto';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Twoje konto na $url wymaga jeszcze chwili na załadowanie.';
  }

  @override
  String get tryAnotherAccountButton => 'Sprawdź inne konto';

  @override
  String get chooseAccountPageLogOutButton => 'Wyloguj';

  @override
  String get logOutConfirmationDialogTitle => 'Wylogować?';

  @override
  String get logOutConfirmationDialogMessage => 'Aby użyć tego konta należy wypełnić URL organizacji oraz dane konta.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Wyloguj';

  @override
  String get chooseAccountButtonAddAnAccount => 'Dodaj konto';

  @override
  String get profileButtonSendDirectMessage => 'Wyślij wiadomość bezpośrednią';

  @override
  String get permissionsNeededTitle => 'Wymagane uprawnienia';

  @override
  String get permissionsNeededOpenSettings => 'Otwórz ustawienia';

  @override
  String get permissionsDeniedCameraAccess => 'Aby odebrać obraz Zulip musi uzyskać dodatkowe uprawnienia w Ustawieniach.';

  @override
  String get permissionsDeniedReadExternalStorage => 'Aby odebrać pliki Zulip musi uzyskać dodatkowe uprawnienia w Ustawieniach.';

  @override
  String get actionSheetOptionMuteTopic => 'Wycisz wątek';

  @override
  String get actionSheetOptionUnmuteTopic => 'Wznów wątek';

  @override
  String get actionSheetOptionFollowTopic => 'Śledź wątek';

  @override
  String get actionSheetOptionUnfollowTopic => 'Nie śledź wątku';

  @override
  String get actionSheetOptionCopyMessageText => 'Skopiuj tekst wiadomości';

  @override
  String get actionSheetOptionCopyMessageLink => 'Skopiuj odnośnik do wiadomości';

  @override
  String get actionSheetOptionMarkAsUnread => 'Odtąd oznacz jako nieprzeczytane';

  @override
  String get actionSheetOptionShare => 'Udostępnij';

  @override
  String get actionSheetOptionQuoteAndReply => 'Odpowiedz cytując';

  @override
  String get actionSheetOptionStarMessage => 'Oznacz gwiazdką';

  @override
  String get actionSheetOptionUnstarMessage => 'Odbierz gwiazdkę';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Coś poszło nie tak';

  @override
  String get errorWebAuthOperationalError => 'Wystąpił niespodziewany błąd.';

  @override
  String get errorAccountLoggedInTitle => 'Konto już wylogowane';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Konto $email na $server znajduje się już na liście dodanych kont.';
  }

  @override
  String get errorCouldNotFetchMessageSource => 'Nie można uzyskać źródłowej wiadomości';

  @override
  String get errorCopyingFailed => 'Nie udało się skopiować';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Nie udało się załadować pliku: $filename';
  }

  @override
  String errorFilesTooLarge(int num, int maxFileUploadSizeMib, String listMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num Pliki są',
      one: 'Plik jest',
    );
    return '$_temp0 ponad limit serwera $maxFileUploadSizeMib MiB i nie zostaną przyjęte:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Pliki',
      one: 'Plik',
    );
    return '$_temp0 ponad limit';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Błędny wsad';

  @override
  String get errorLoginFailedTitle => 'Logowanie bez powodzenia';

  @override
  String get errorMessageNotSent => 'Nie wysłano wiadomości';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Nie udało się połączyć z serwerem:\n$url';
  }

  @override
  String get errorLoginCouldNotConnectTitle => 'Nie można połączyć';

  @override
  String get errorMessageDoesNotSeemToExist => 'Taka wiadomość raczej nie istnieje.';

  @override
  String get errorQuotationFailed => 'Cytowanie bez powodzenia';

  @override
  String errorServerMessage(String message) {
    return 'Odpowiedź serwera:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort => 'Błąd połączenia z Zulip. Ponawiam…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Błąd połączenia z Zulip $serverUrl. Spróbujmy ponownie:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle => 'Błąd obsługi zdarzenia Zulip. Ponnawiam połączenie…';

  @override
  String errorHandlingEventDetails(String serverUrl, String error, String event) {
    return 'Błąd zdarzenia Zulip z $serverUrl; ponawiam.\n\nBłąd: $error\n\nZdarzenie: $event';
  }

  @override
  String get errorMuteTopicFailed => 'Wyciszenie bez powodzenia';

  @override
  String get errorUnmuteTopicFailed => 'Wznowienie bez powodzenia';

  @override
  String get errorFollowTopicFailed => 'Śledzenie bez powodzenia';

  @override
  String get errorUnfollowTopicFailed => 'Nie śledź bez powodzenia';

  @override
  String get errorSharingFailed => 'Udostępnianie bez powodzenia';

  @override
  String get errorStarMessageFailedTitle => 'Dodanie gwiazdki bez powodzenia';

  @override
  String get errorUnstarMessageFailedTitle => 'Odebranie gwiazdki bez powodzenia';

  @override
  String get successLinkCopied => 'Skopiowano odnośnik';

  @override
  String get successMessageTextCopied => 'Skopiowano tekst wiadomości';

  @override
  String get successMessageLinkCopied => 'Skopiowano odnośnik wiadomości';

  @override
  String get errorBannerDeactivatedDmLabel => 'Nie można wysyłać wiadomości do dezaktywowanych użytkowników.';

  @override
  String get errorBannerCannotPostInChannelLabel => 'Nie masz uprawnień do dodawania wpisów w tym kanale.';

  @override
  String get composeBoxAttachFilesTooltip => 'Dołącz pliki';

  @override
  String get composeBoxAttachMediaTooltip => 'Dołącz obrazy lub wideo';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Zrób zdjęcie';

  @override
  String get composeBoxGenericContentHint => 'Wpisz wiadomość';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Napisz do @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Napisz do grupy';

  @override
  String get composeBoxSelfDmContentHint => 'Zanotuj coś na przyszłość';

  @override
  String composeBoxChannelContentHint(String channel, String topic) {
    return 'Wiadomość #$channel > $topic';
  }

  @override
  String get composeBoxSendTooltip => 'Wyślij';

  @override
  String get composeBoxUnknownChannelName => '(nieznany kanał)';

  @override
  String get composeBoxTopicHintText => 'Wątek';

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Przekazywanie $filename…';
  }

  @override
  String get unknownUserName => '(nieznany użytkownik)';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Ty i $others';
  }

  @override
  String get messageListGroupYouWithYourself => 'Ty ze sobą';

  @override
  String get contentValidationErrorTooLong => 'Wiadomość nie może być dłuższa niż 10000 znaków.';

  @override
  String get contentValidationErrorEmpty => 'Nie masz nic do wysłania!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress => 'Zaczekaj na zakończenie pobierania cytatu.';

  @override
  String get contentValidationErrorUploadInProgress => 'Zaczekaj na zakończenie przekazywania.';

  @override
  String get dialogCancel => 'Anuluj';

  @override
  String get dialogContinue => 'Kontynuuj';

  @override
  String get dialogClose => 'Zamknij';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Błąd';

  @override
  String get snackBarDetails => 'Szczegóły';

  @override
  String get lightboxCopyLinkTooltip => 'Skopiuj odnośnik';

  @override
  String get loginPageTitle => 'Zaloguj';

  @override
  String get loginFormSubmitLabel => 'Zaloguj';

  @override
  String get loginMethodDivider => 'LUB';

  @override
  String signInWithFoo(String method) {
    return 'Logowanie z $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Dodaj konto';

  @override
  String get loginServerUrlInputLabel => 'URL serwera Zulip';

  @override
  String get loginHidePassword => 'Ukryj hasło';

  @override
  String get loginEmailLabel => 'Adres email';

  @override
  String get loginErrorMissingEmail => 'Proszę podaj swój email.';

  @override
  String get loginPasswordLabel => 'Hasło';

  @override
  String get loginErrorMissingPassword => 'Proszę wprowadź hasło.';

  @override
  String get loginUsernameLabel => 'Użytkownik';

  @override
  String get loginErrorMissingUsername => 'Proszę podaj nazwę użytkownika.';

  @override
  String get topicValidationErrorTooLong => 'Tytuł nie może być dłuższy niż 60 znaków.';

  @override
  String get topicValidationErrorMandatoryButEmpty => 'Wątki są wymagane przez tę organizację.';

  @override
  String get errorInvalidResponse => 'Nieprawidłowa odpowiedź serwera';

  @override
  String get errorNetworkRequestFailed => 'Dostęp do sieci bez powodzenia';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Zdeforomowana odpowiedź serwera; status HTTP $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Zdeformowana odpowiedź serwera; status HTTP $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Błąd uzyskania sieci: status HTTP $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Nie da rady odtworzyć wideo';

  @override
  String get serverUrlValidationErrorEmpty => 'Proszę podaj URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Proszę podaj poprawny URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail => 'Proszę podaj adres URL serwera a nie swój email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme => 'Adres URL serwera musi zaczynać się od http:// or https://.';

  @override
  String get spoilerDefaultHeaderText => 'Spoiler';

  @override
  String get markAllAsReadLabel => 'Oznacz wszystkie jako przeczytane';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num wiadomości',
      one: '1 wiadomość',
    );
    return 'Oznaczono $_temp0 jako przeczytane.';
  }

  @override
  String get markAsReadInProgress => 'Oznaczanie wiadomości jako przeczytane…';

  @override
  String get errorMarkAsReadFailedTitle => 'Oznaczanie jako przeczytane bez powodzenia';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num wiadomości',
      one: '1 wiadomość',
    );
    return 'Oznaczono $_temp0 jako nieprzeczytane.';
  }

  @override
  String get markAsUnreadInProgress => 'Oznaczanie jako nieprzeczytane…';

  @override
  String get errorMarkAsUnreadFailedTitle => 'Oznaczanie jako nieprzeczytane bez powodzenia';

  @override
  String get today => 'Dzisiaj';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get userRoleOwner => 'Właściciel';

  @override
  String get userRoleAdministrator => 'Administrator';

  @override
  String get userRoleModerator => 'Moderator';

  @override
  String get userRoleMember => 'Członek';

  @override
  String get userRoleGuest => 'Gość';

  @override
  String get userRoleUnknown => 'Nieznany';

  @override
  String get inboxPageTitle => 'Odebrane';

  @override
  String get recentDmConversationsPageTitle => 'Wiadomości bezpośrednie';

  @override
  String get combinedFeedPageTitle => 'Mieszany widok';

  @override
  String get mentionsPageTitle => 'Wzmianki';

  @override
  String get starredMessagesPageTitle => 'Wiadomości z gwiazdką';

  @override
  String get channelsPageTitle => 'Kanały';

  @override
  String get mainMenuMyProfile => 'Mój profil';

  @override
  String get channelFeedButtonTooltip => 'Strumień kanału';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers innych',
      one: '1 innego',
    );
    return '$senderFullName do ciebie i $_temp0';
  }

  @override
  String get notifSelfUser => 'Ty';

  @override
  String onePersonTyping(String typist) {
    return '$typist coś pisze…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist i $otherTypist coś piszą…';
  }

  @override
  String get manyPeopleTyping => 'Wielu ludzi coś pisze…';

  @override
  String get messageIsEditedLabel => 'ZMIENIONO';

  @override
  String get messageIsMovedLabel => 'PRZENIESIONO';

  @override
  String get pollWidgetQuestionMissing => 'Brak pytania.';

  @override
  String get pollWidgetOptionsMissing => 'Ta sonda nie ma opcji do wyboru.';

  @override
  String get errorNotificationOpenTitle => 'Otwieranie powiadomienia bez powodzenia';

  @override
  String get errorNotificationOpenAccountMissing => 'Konto związane z tym powiadomieniem już nie istnieje.';

  @override
  String get errorReactionAddingFailedTitle => 'Dodanie reakcji bez powodzenia';

  @override
  String get errorReactionRemovingFailedTitle => 'Usuwanie reakcji bez powodzenia';

  @override
  String get emojiReactionsMore => 'więcej';

  @override
  String get emojiPickerSearchEmoji => 'Szukaj emoji';
}
