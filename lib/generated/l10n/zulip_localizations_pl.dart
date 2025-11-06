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
  String get upgradeWelcomeDialogTitle => 'Witaj w nowej apce Zulip!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Napotkasz na znane rozwiązania, które upakowaliśmy w szybszy i elegancki pakiet.';

  @override
  String get upgradeWelcomeDialogLinkText =>
      'Sprawdź blog pod kątem obwieszczenia!';

  @override
  String get upgradeWelcomeDialogDismiss => 'Zaczynajmy';

  @override
  String get chooseAccountPageTitle => 'Wybierz konto';

  @override
  String get settingsPageTitle => 'Ustawienia';

  @override
  String get switchAccountButton => 'Przełącz konto';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Twoje konto na $url wymaga jeszcze chwili na załadowanie.';
  }

  @override
  String get tryAnotherAccountButton => 'Użyj innego konta';

  @override
  String get chooseAccountPageLogOutButton => 'Wyloguj';

  @override
  String get logOutConfirmationDialogTitle => 'Wylogować?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Aby użyć tego konta należy wskazać URL organizacji oraz dane konta.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Wyloguj';

  @override
  String get chooseAccountButtonAddAnAccount => 'Dodaj konto';

  @override
  String get navButtonAllChannels => 'Wszystkie kanały';

  @override
  String get allChannelsPageTitle => 'Wszystkie kanały';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'Brak kanałów do których masz wgląd w tej organizacji.';

  @override
  String get profileButtonSendDirectMessage => 'Wyślij wiadomość bezpośrednią';

  @override
  String get errorCouldNotShowUserProfile =>
      'Nie udało się wyświetlić profilu.';

  @override
  String get permissionsNeededTitle => 'Wymagane uprawnienia';

  @override
  String get permissionsNeededOpenSettings => 'Otwórz ustawienia';

  @override
  String get permissionsDeniedCameraAccess =>
      'Aby odebrać obraz Zulip musi uzyskać dodatkowe uprawnienia w Ustawieniach.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Aby odebrać pliki Zulip musi uzyskać dodatkowe uprawnienia w Ustawieniach.';

  @override
  String get actionSheetOptionSubscribe => 'Subskrybuj';

  @override
  String get subscribeFailedTitle => 'Subskrypcja bez powodzenia';

  @override
  String get actionSheetOptionMarkChannelAsRead =>
      'Oznacz kanał jako przeczytany';

  @override
  String get actionSheetOptionCopyChannelLink => 'Skopiuj odnośnik do kanału';

  @override
  String get actionSheetOptionListOfTopics => 'Lista wątków';

  @override
  String get actionSheetOptionChannelFeed => 'Strumień kanału';

  @override
  String get actionSheetOptionUnsubscribe => 'Odsubskrybuj';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Odsubskrybować z $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Opuszczając ten kanał utracisz możliwość ponownego przyłączenia.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Odsubskrybuj';

  @override
  String get unsubscribeFailedTitle => 'Odsubskrybowanie bez powdzenia';

  @override
  String get actionSheetOptionMuteTopic => 'Wycisz wątek';

  @override
  String get actionSheetOptionUnmuteTopic => 'Wznów wątek';

  @override
  String get actionSheetOptionFollowTopic => 'Śledź wątek';

  @override
  String get actionSheetOptionUnfollowTopic => 'Nie śledź wątku';

  @override
  String get actionSheetOptionResolveTopic => 'Oznacz jako rozwiązany';

  @override
  String get actionSheetOptionUnresolveTopic => 'Oznacz brak rozwiązania';

  @override
  String get errorResolveTopicFailedTitle =>
      'Nie udało się oznaczyć jako rozwiązany';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Nie udało się oznaczyć brak rozwiązania';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Pokaż kto zareagował';

  @override
  String get seeWhoReactedSheetNoReactions => 'Brak reakcji na tę wiadomość.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Reakcje emoji (łącznie $num)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num głosów',
      one: '1 głos',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Głosów $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts =>
      'Zobacz potwierdzenia odczytu';

  @override
  String get actionSheetReadReceipts => 'Potwierdzenia odczytu';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ta wiadomość została <z-link>przeczytana</z-link> przez $count osób:',
      one:
          'Ta wiadomość została <z-link>przeczytana</z-link> przez $count osobę:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Nikt jeszcze nie widział tej wiadomości.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Ładowanie potwierdzeń odczytu bez powodzenia.';

  @override
  String get actionSheetOptionCopyMessageText => 'Skopiuj tekst wiadomości';

  @override
  String get actionSheetOptionCopyMessageLink =>
      'Skopiuj odnośnik do wiadomości';

  @override
  String get actionSheetOptionMarkAsUnread =>
      'Odtąd oznacz jako nieprzeczytane';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Ukryj ponownie wyciszone wiadomości';

  @override
  String get actionSheetOptionShare => 'Udostępnij';

  @override
  String get actionSheetOptionQuoteMessage => 'Cytuj wiadomość';

  @override
  String get actionSheetOptionStarMessage => 'Oznacz gwiazdką';

  @override
  String get actionSheetOptionUnstarMessage => 'Odbierz gwiazdkę';

  @override
  String get actionSheetOptionEditMessage => 'Zmień wiadomość';

  @override
  String get actionSheetOptionDeleteMessage => 'Skasuj wiadomość';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Skasować wiadomość?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Kasowanie wiadomości na dobre usuwa ją dla wszystkich.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Skasuj';

  @override
  String get errorDeleteMessageFailedTitle =>
      'Kasowanie wiadomości bez powodzenia';

  @override
  String get actionSheetOptionMarkTopicAsRead =>
      'Oznacz wątek jako przeczytany';

  @override
  String get actionSheetOptionCopyTopicLink => 'Skopiuj odnośnik do wątku';

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
  String get errorCouldNotFetchMessageSource =>
      'Nie można uzyskać źródłowej wiadomości.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Brak dostępu do załadowanego pliku';

  @override
  String get errorCopyingFailed => 'Nie udało się skopiować';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Nie udało się załadować pliku: $filename';
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
  String get errorMessageEditNotSaved => 'Nie zapisano wiadomości';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Nie udało się połączyć z serwerem:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Brak połączenia';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Taka wiadomość raczej nie istnieje.';

  @override
  String get errorQuotationFailed => 'Cytowanie bez powodzenia';

  @override
  String errorServerMessage(String message) {
    return 'Odpowiedź serwera:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Błąd połączenia z Zulip. Ponawiam…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Błąd połączenia z Zulip $serverUrl. Spróbujmy ponownie:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Błąd obsługi zdarzenia Zulip. Ponnawiam połączenie…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Błąd zdarzenia Zulip z $serverUrl; ponawiam.\n\nBłąd: $error\n\nZdarzenie: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Nie udało się otworzyć odnośnika';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Nie można otworzyć: $url';
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
  String get errorUnstarMessageFailedTitle =>
      'Odebranie gwiazdki bez powodzenia';

  @override
  String get errorCouldNotEditMessageTitle => 'Nie można zmienić wiadomości';

  @override
  String get successLinkCopied => 'Skopiowano odnośnik';

  @override
  String get successMessageTextCopied => 'Skopiowano tekst wiadomości';

  @override
  String get successMessageLinkCopied => 'Skopiowano odnośnik wiadomości';

  @override
  String get successTopicLinkCopied => 'Skopiowano odnośnik do wątku';

  @override
  String get successChannelLinkCopied => 'Skopiowano odnośnik do kanału';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Nie można wysyłać wiadomości do dezaktywowanych użytkowników.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'Nie masz uprawnień do dodawania wpisów w tym kanale.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Nowe wiadomości nie pojawią się z automatu.';

  @override
  String get composeBoxBannerButtonRefresh => 'Odśwież';

  @override
  String get composeBoxBannerButtonSubscribe => 'Subskrybuj';

  @override
  String get composeBoxBannerLabelEditMessage => 'Zmień wiadomość';

  @override
  String get composeBoxBannerButtonCancel => 'Anuluj';

  @override
  String get composeBoxBannerButtonSave => 'Zapisz';

  @override
  String get editAlreadyInProgressTitle => 'Nie udało się zapisać zmiany';

  @override
  String get editAlreadyInProgressMessage =>
      'Operacja zmiany w toku. Zaczekaj na jej zakończenie.';

  @override
  String get savingMessageEditLabel => 'ZAPIS ZMIANY…';

  @override
  String get savingMessageEditFailedLabel => 'NIE ZAPISANO ZMIANY';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Czy chcesz przerwać szykowanie wpisu?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Miej na uwadze, że przechodząc do zmiany wiadomości wyczyścisz okno nowej wiadomości.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Przywracając wiadomość, która nie została wysłana, wyczyścisz zawartość kreatora nowej.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Odrzuć';

  @override
  String get composeBoxAttachFilesTooltip => 'Dołącz pliki';

  @override
  String get composeBoxAttachMediaTooltip => 'Dołącz obrazy lub wideo';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Zrób zdjęcie';

  @override
  String get composeBoxGenericContentHint => 'Wpisz wiadomość';

  @override
  String get newDmSheetComposeButtonLabel => 'Utwórz';

  @override
  String get newDmSheetScreenTitle => 'Nowa DM';

  @override
  String get newDmFabButtonLabel => 'Nowa DM';

  @override
  String get newDmSheetSearchHintEmpty =>
      'Dodaj jednego lub więcej użytkowników';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Dodaj kolejnego użytkownika…';

  @override
  String get newDmSheetNoUsersFound => 'Nie odnaleziono użytkowników';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Napisz do @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Napisz do grupy';

  @override
  String get composeBoxSelfDmContentHint => 'Zostaw notatkę dla siebie';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Wiadomość do $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Przygotowywanie…';

  @override
  String get composeBoxSendTooltip => 'Wyślij';

  @override
  String get unknownChannelName => '(nieznany kanał)';

  @override
  String get composeBoxTopicHintText => 'Wątek';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Wpisz tytuł wątku (pomiń aby uzyskać “$defaultTopicName”)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Przekazywanie $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(ładowanie wiadomości $messageId)';
  }

  @override
  String get unknownUserName => '(nieznany użytkownik)';

  @override
  String get dmsWithYourselfPageTitle => 'DM do siebie';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Ty i $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'DM z $others';
  }

  @override
  String get emptyMessageList => 'Póki co brak wiadomości.';

  @override
  String get emptyMessageListSearch => 'Brak wyników wyszukiwania.';

  @override
  String get messageListGroupYouWithYourself => 'Zapiski na własne konto';

  @override
  String get contentValidationErrorTooLong =>
      'Wiadomość nie może być dłuższa niż 10000 znaków.';

  @override
  String get contentValidationErrorEmpty => 'Nie masz nic do wysłania!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Zaczekaj na zakończenie pobierania cytatu.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Zaczekaj na zakończenie przekazywania.';

  @override
  String get dialogCancel => 'Anuluj';

  @override
  String get dialogContinue => 'Kontynuuj';

  @override
  String get dialogClose => 'Zamknij';

  @override
  String get errorDialogLearnMore => 'Dowiedz się więcej';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Błąd';

  @override
  String get snackBarDetails => 'Szczegóły';

  @override
  String get lightboxCopyLinkTooltip => 'Skopiuj odnośnik';

  @override
  String get lightboxVideoCurrentPosition => 'Obecna pozycja';

  @override
  String get lightboxVideoDuration => 'Długość wideo';

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
  String get loginServerUrlLabel => 'URL serwera Zulip';

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
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength znaków',
      one: '1 znak',
    );
    return 'Długość wątku nie może być dłuższa niż $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Wątki są wymagane przez tę organizację.';

  @override
  String get errorContentNotInsertedTitle =>
      'Dodanie zawartości bez powodzenia';

  @override
  String get errorContentToInsertIsEmpty =>
      'Plik do dodania jest pusty lub nie ma do niego dostępu.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url uruchamia Zulip Server $zulipVersion, który nie jest obsługiwany. Minimalna obsługiwana wersja to Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Konto w ramach $url nie zostało przyjęte. Spróbuj ponownie lub skorzystaj z innego konta.';
  }

  @override
  String get errorInvalidResponse => 'Nieprawidłowa odpowiedź serwera.';

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
  String get errorVideoPlayerFailed => 'Nie da rady odtworzyć wideo.';

  @override
  String get serverUrlValidationErrorEmpty => 'Proszę podaj URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Proszę podaj poprawny URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Proszę podaj adres URL serwera a nie swój email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'Adres URL serwera musi zaczynać się od http:// or https://.';

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
  String get errorMarkAsReadFailedTitle =>
      'Oznaczanie jako przeczytane bez powodzenia';

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
  String get errorMarkAsUnreadFailedTitle =>
      'Oznaczanie jako nieprzeczytane bez powodzenia';

  @override
  String get today => 'Dzisiaj';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get userActiveNow => 'Teraz dostępny';

  @override
  String get userIdle => 'Bezczynny';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minut',
      one: '1 minutę',
    );
    return 'Aktywny $_temp0 temu';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours godzin',
      one: '1 godzinę',
    );
    return 'Aktywny $_temp0 temu';
  }

  @override
  String get userActiveYesterday => 'Aktywny wczoraj';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni',
      one: '1 dzień',
    );
    return 'Aktywny $_temp0 temu';
  }

  @override
  String userActiveDate(String date) {
    return 'Aktywny $date';
  }

  @override
  String get userNotActiveInYear => 'Brak aktywności za ostatni rok';

  @override
  String get invisibleMode => 'Tryb ukrycia';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Problem z włączeniem trybu ukrycia. Spróbuj ponownie.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Problem z wyłączeniem trybu ukrycia. Spróbuj ponownie.';

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
  String get statusButtonLabelStatusSet => 'Stan';

  @override
  String get statusButtonLabelStatusUnset => 'Ustaw stan';

  @override
  String get noStatusText => 'Brak tekstu stanu';

  @override
  String get setStatusPageTitle => 'Ustaw stan';

  @override
  String get statusClearButtonLabel => 'Wyczyść';

  @override
  String get statusSaveButtonLabel => 'Zapisz';

  @override
  String get statusTextHint => 'Twój stan';

  @override
  String get userStatusBusy => 'Zajęty';

  @override
  String get userStatusInAMeeting => 'Na spotkaniu';

  @override
  String get userStatusCommuting => 'W drodze';

  @override
  String get userStatusOutSick => 'Chorobowe';

  @override
  String get userStatusVacationing => 'Na urlopie';

  @override
  String get userStatusWorkingRemotely => 'Praca zdalna';

  @override
  String get userStatusAtTheOffice => 'W biurze';

  @override
  String get updateStatusErrorTitle =>
      'Błąd aktualizacji stanu. Spróbuj ponownie.';

  @override
  String get searchMessagesPageTitle => 'Szukaj';

  @override
  String get searchMessagesHintText => 'Szukaj';

  @override
  String get searchMessagesClearButtonTooltip => 'Wyczyść';

  @override
  String get inboxPageTitle => 'Odebrane';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'Brak nieprzeczytanych wiadomości w odebranych.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Użyj poniższych przycisków aby skorzystać z widoku mieszanego lub listy kanałów.';

  @override
  String get recentDmConversationsPageTitle => 'Wiadomości bezpośrednie';

  @override
  String get recentDmConversationsSectionHeader => 'Wiadomości bezpośrednie';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'Póki co brak prywatnych wiadomości!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'A może by tak rozpocząć rozmowę?';

  @override
  String get combinedFeedPageTitle => 'Mieszany widok';

  @override
  String get mentionsPageTitle => 'Wzmianki';

  @override
  String get starredMessagesPageTitle => 'Wiadomości z gwiazdką';

  @override
  String get channelsPageTitle => 'Kanały';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Nie śledzisz żadnego z kanałów.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Spróbuj skorzystać z <z-link>$allChannelsPageTitle</z-link> i dołączyć do nich.';
  }

  @override
  String get sharePageTitle => 'Udostępnij';

  @override
  String get mainMenuMyProfile => 'Mój profil';

  @override
  String get topicsButtonTooltip => 'Wątki';

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
  String get pinnedSubscriptionsLabel => 'Przypięte';

  @override
  String get unpinnedSubscriptionsLabel => 'Odpięte';

  @override
  String get notifSelfUser => 'Ty';

  @override
  String get reactedEmojiSelfUser => 'Ty';

  @override
  String get reactionChipsLabel => 'Reakcje';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Ty i $otherUsersCount innych',
      one: 'Ty i 1 inny',
    );
    return '$_temp0';
  }

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
  String get wildcardMentionAll => 'wszyscy';

  @override
  String get wildcardMentionEveryone => 'każdy';

  @override
  String get wildcardMentionChannel => 'kanał';

  @override
  String get wildcardMentionStream => 'strumień';

  @override
  String get wildcardMentionTopic => 'wątek';

  @override
  String get wildcardMentionChannelDescription => 'Powiadom w kanale';

  @override
  String get wildcardMentionStreamDescription => 'Powiadom w strumieniu';

  @override
  String get wildcardMentionAllDmDescription => 'Powiadom zainteresowanych';

  @override
  String get wildcardMentionTopicDescription => 'Powiadom w wątku';

  @override
  String get messageIsEditedLabel => 'ZMIENIONO';

  @override
  String get messageIsMovedLabel => 'PRZENIESIONO';

  @override
  String get messageNotSentLabel => 'NIE WYSŁANO WIADOMOŚCI';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'WYSTRÓJ';

  @override
  String get themeSettingDark => 'Ciemny';

  @override
  String get themeSettingLight => 'Jasny';

  @override
  String get themeSettingSystem => 'Systemowy';

  @override
  String get openLinksWithInAppBrowser => 'Otwieraj odnośniki w aplikacji';

  @override
  String get pollWidgetQuestionMissing => 'Brak pytania.';

  @override
  String get pollWidgetOptionsMissing => 'Ta sonda nie ma opcji do wyboru.';

  @override
  String get initialAnchorSettingTitle => 'Pokaż wiadomości w porządku';

  @override
  String get initialAnchorSettingDescription =>
      'Możesz wybrać czy bardziej odpowiada Ci odczyt nieprzeczytanych lub najnowszych wiadomości.';

  @override
  String get initialAnchorSettingFirstUnreadAlways =>
      'Pierwsza nieprzeczytana wiadomość';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Pierwsza nieprzeczytana wiadomość w widoku dyskusji, wszędzie indziej najnowsza wiadomość';

  @override
  String get initialAnchorSettingNewestAlways => 'Najnowsza wiadomość';

  @override
  String get markReadOnScrollSettingTitle =>
      'Oznacz wiadomości jako przeczytane przy przwijaniu';

  @override
  String get markReadOnScrollSettingDescription =>
      'Czy chcesz z automatu oznaczać wiadomości jako przeczytane przy przewijaniu?';

  @override
  String get markReadOnScrollSettingAlways => 'Zawsze';

  @override
  String get markReadOnScrollSettingNever => 'Nigdy';

  @override
  String get markReadOnScrollSettingConversations => 'Tylko w widoku dyskusji';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Wiadomości zostaną z automatu oznaczone jako przeczytane tylko w pojedyczym wątku lub w wymianie wiadomości bezpośrednich.';

  @override
  String get experimentalFeatureSettingsPageTitle => 'Funkcje eksperymentalne';

  @override
  String get experimentalFeatureSettingsWarning =>
      'W ten sposób aktywujesz funkcje, które są w fazie testów. Mogą one nie działać lub powodować problemy z tym co bez nich działa poprawnie.\n\nTo ustawienie przewidziane jest dla tych, którzy pracują nad ulepszeniem aplikacji Zulip.';

  @override
  String get errorNotificationOpenTitle =>
      'Otwieranie powiadomienia bez powodzenia';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Nie odnaleziono konta powiązanego z tym powiadomieniem.';

  @override
  String get errorReactionAddingFailedTitle => 'Dodanie reakcji bez powodzenia';

  @override
  String get errorReactionRemovingFailedTitle =>
      'Usuwanie reakcji bez powodzenia';

  @override
  String get errorSharingTitle => 'Udostępnianie zawartości bez powodzenia';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'Brak zalogowanego użytkownika. Proszę zaloguj się i spróbuj ponownie.';

  @override
  String get emojiReactionsMore => 'więcej';

  @override
  String get emojiPickerSearchEmoji => 'Szukaj emoji';

  @override
  String get noEarlierMessages => 'Brak historii';

  @override
  String get revealButtonLabel => 'Odsłoń wiadomość';

  @override
  String get mutedUser => 'Wyciszony użytkownik';

  @override
  String get scrollToBottomTooltip => 'Przewiń do dołu';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
