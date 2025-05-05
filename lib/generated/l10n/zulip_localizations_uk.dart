// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class ZulipLocalizationsUk extends ZulipLocalizations {
  ZulipLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get aboutPageTitle => 'Про Zulip';

  @override
  String get aboutPageAppVersion => 'Версія додатку';

  @override
  String get aboutPageOpenSourceLicenses => 'Ліцензії з відкритим кодом';

  @override
  String get aboutPageTapToView => 'Натисніть, щоб переглянути';

  @override
  String get chooseAccountPageTitle => 'Обрати обліковий запис';

  @override
  String get settingsPageTitle => 'Налаштування';

  @override
  String get switchAccountButton => 'Змінити обліковий запис';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Ваш обліковий запис на $url завантажується деякий час.';
  }

  @override
  String get tryAnotherAccountButton => 'Спробуйте інший обліковий запис';

  @override
  String get chooseAccountPageLogOutButton => 'Вийти';

  @override
  String get logOutConfirmationDialogTitle => 'Вийти?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Щоб використовувати цей обліковий запис у майбутньому, вам доведеться повторно ввести його дані та URL-адресу вашої організації.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Вийти';

  @override
  String get chooseAccountButtonAddAnAccount => 'Додати обліковий запис';

  @override
  String get profileButtonSendDirectMessage =>
      'Надіслати особисте повідомлення';

  @override
  String get errorCouldNotShowUserProfile =>
      'Не вдалося показати профіль користувача.';

  @override
  String get permissionsNeededTitle => 'Потрібні дозволи';

  @override
  String get permissionsNeededOpenSettings => 'Відкрити налаштування';

  @override
  String get permissionsDeniedCameraAccess =>
      'Щоб завантажити зображення, надайте Zulip додаткові дозволи в налаштуваннях.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Щоб завантажувати файли, надайте Zulip додаткові дозволи в налаштуваннях.';

  @override
  String get actionSheetOptionMarkChannelAsRead =>
      'Позначити канал як прочитаний';

  @override
  String get actionSheetOptionMuteTopic => 'Заглушити тему';

  @override
  String get actionSheetOptionUnmuteTopic => 'Увімкнути тему';

  @override
  String get actionSheetOptionFollowTopic => 'Підписатися на тему';

  @override
  String get actionSheetOptionUnfollowTopic => 'Відписатися від теми';

  @override
  String get actionSheetOptionResolveTopic => 'Позначити як вирішене';

  @override
  String get actionSheetOptionUnresolveTopic => 'Позначити як невирішене';

  @override
  String get errorResolveTopicFailedTitle =>
      'Не вдалося позначити тему як вирішену';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Не вдалося позначити тему як невирішену';

  @override
  String get actionSheetOptionCopyMessageText => 'Копіювати текст повідомлення';

  @override
  String get actionSheetOptionCopyMessageLink =>
      'Копіювати посилання на повідомлення';

  @override
  String get actionSheetOptionMarkAsUnread => 'Позначити як непрочитане звідси';

  @override
  String get actionSheetOptionShare => 'Поширити';

  @override
  String get actionSheetOptionQuoteAndReply => 'Цитата і відповідь';

  @override
  String get actionSheetOptionStarMessage => 'Вибрати повідомлення';

  @override
  String get actionSheetOptionUnstarMessage =>
      'Зняти позначку зірки з повідомлення';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Позначити тему як прочитану';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Щось пішло не так';

  @override
  String get errorWebAuthOperationalError => 'Сталася неочікувана помилка.';

  @override
  String get errorAccountLoggedInTitle => 'В обліковий запис уже ввійшли';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Обліковий запис $email на $server уже є у вашому списку облікових записів.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Не вдалося отримати джерело повідомлення';

  @override
  String get errorCopyingFailed => 'Помилка копіювання';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Не вдалося завантажити файл: $filename';
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
      other: '$num файли',
      one: 'Файл',
    );
    return '$_temp0 перевищують ліміт сервера в $maxFileUploadSizeMib MiB і не будуть завантажені:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Файли',
      one: 'Файл',
    );
    return '$_temp0 занадто великий';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Невірний вхід';

  @override
  String get errorLoginFailedTitle => 'Помилка входу';

  @override
  String get errorMessageNotSent => 'Повідомлення не надіслано';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Не вдалося підключитися до сервера:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Не вдалося підключитися';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Здається, цього повідомлення не існує.';

  @override
  String get errorQuotationFailed => 'Помилка цитування';

  @override
  String errorServerMessage(String message) {
    return 'Сервер сказав:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Помилка підключення до Zulip. Повторна спроба…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Помилка підключення до Zulip на $serverUrl. Буде повторена спроба:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Помилка обробки події Zulip. Повторна спроба підключення…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Помилка обробки події Zulip із $serverUrl; буде повторювати спробу.\n\nПомилка: $error\n\nПодія: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Неможливо відкрити посилання';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Не вдалося відкрити посилання: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Не вдалося заглушити тему';

  @override
  String get errorUnmuteTopicFailed => 'Не вдалося увімкнути тему';

  @override
  String get errorFollowTopicFailed => 'Не вдалося підписатися на тему';

  @override
  String get errorUnfollowTopicFailed => 'Не вдалося відписатися від теми';

  @override
  String get errorSharingFailed => 'Поширення не вдалося';

  @override
  String get errorStarMessageFailedTitle =>
      'Не вдалося позначити повідомлення зіркою';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Не вдалося зняти позначку зірки з повідомлення';

  @override
  String get successLinkCopied => 'Посилання скопійовано';

  @override
  String get successMessageTextCopied => 'Текст повідомлення скопійовано';

  @override
  String get successMessageLinkCopied =>
      'Посилання на повідомлення скопійовано';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Ви не можете надсилати повідомлення деактивованим користувачам.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'Ви не маєте дозволу на публікацію в цьому каналі.';

  @override
  String get composeBoxAttachFilesTooltip => 'Прикріпити файли';

  @override
  String get composeBoxAttachMediaTooltip => 'Додати зображення або відео';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Зробити фото';

  @override
  String get composeBoxGenericContentHint => 'Ввести повідомлення';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Повідомлення @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Написати групі';

  @override
  String get composeBoxSelfDmContentHint => 'Занотувати щось';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Надіслати повідомлення $destination';
  }

  @override
  String get composeBoxSendTooltip => 'Надіслати';

  @override
  String get unknownChannelName => '(невідомий канал)';

  @override
  String get composeBoxTopicHintText => 'Тема';

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Завантаження $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(завантаження повідомлення $messageId)';
  }

  @override
  String get unknownUserName => '(невідомий користувач)';

  @override
  String get dmsWithYourselfPageTitle => 'Особисті повідомлення із собою';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Ви та $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'Особисті повідомлення з $others';
  }

  @override
  String get messageListGroupYouWithYourself => 'Повідомлення з собою';

  @override
  String get contentValidationErrorTooLong =>
      'Довжина повідомлення не повинна перевищувати 10000 символів.';

  @override
  String get contentValidationErrorEmpty => 'Вам нема чого надсилати!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Будь ласка, дочекайтеся завершення цитування.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Дочекайтеся завершення завантаження.';

  @override
  String get dialogCancel => 'Відміна';

  @override
  String get dialogContinue => 'Продовжити';

  @override
  String get dialogClose => 'Закрити';

  @override
  String get errorDialogLearnMore => 'Дізнайтися більше';

  @override
  String get errorDialogContinue => 'ОК';

  @override
  String get errorDialogTitle => 'Помилка';

  @override
  String get snackBarDetails => 'Деталі';

  @override
  String get lightboxCopyLinkTooltip => 'Копіювати посилання';

  @override
  String get lightboxVideoCurrentPosition => 'Поточна позиція';

  @override
  String get lightboxVideoDuration => 'Довжина відео';

  @override
  String get loginPageTitle => 'Увійти';

  @override
  String get loginFormSubmitLabel => 'Увійти';

  @override
  String get loginMethodDivider => 'АБО';

  @override
  String signInWithFoo(String method) {
    return 'Увійти з $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Додати обліковий запис';

  @override
  String get loginServerUrlLabel => 'URL-адреса вашого сервера Zulip';

  @override
  String get loginHidePassword => 'Приховати пароль';

  @override
  String get loginEmailLabel => 'Адреса електронної пошти';

  @override
  String get loginErrorMissingEmail =>
      'Будь ласка, введіть свою електронну адресу.';

  @override
  String get loginPasswordLabel => 'Пароль';

  @override
  String get loginErrorMissingPassword => 'Будь ласка, введіть свій пароль.';

  @override
  String get loginUsernameLabel => 'Ім\'я користувача';

  @override
  String get loginErrorMissingUsername => 'Введіть своє ім\'я користувача.';

  @override
  String get topicValidationErrorTooLong =>
      'Довжина теми не повинна перевищувати 60 символів.';

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Теми обовʼязкові в цій організації.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url використовує Zulip Server $zulipVersion, який не підтримується. Мінімальною підтримуваною версією є Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Ваш обліковий запис на $url не вдалося автентифікувати. Спробуйте увійти ще раз або скористайтеся іншим обліковим записом.';
  }

  @override
  String get errorInvalidResponse => 'Сервер надіслав недійсну відповідь';

  @override
  String get errorNetworkRequestFailed => 'Помилка запиту мережі';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Сервер дав неправильну відповідь; Статус HTTP $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Сервер дав неправильну відповідь; Статус HTTP $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Помилка мережевого запиту: статус HTTP $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Неможливо відтворити відео';

  @override
  String get serverUrlValidationErrorEmpty => 'Будь ласка, введіть URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Введіть дійсну URL-адресу.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Введіть URL-адресу сервера, а не свою електронну адресу.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'URL-адреса сервера має починатися з http:// або https://.';

  @override
  String get spoilerDefaultHeaderText => 'Спойлер';

  @override
  String get markAllAsReadLabel => 'Позначити всі повідомлення як прочитані';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num повідомлення',
      one: '1 повідомлення',
    );
    return 'Позначено як прочитані $_temp0.';
  }

  @override
  String get markAsReadInProgress => 'Позначення повідомлень як прочитаних…';

  @override
  String get errorMarkAsReadFailedTitle => 'Не вдалося позначити як прочитане';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num повідомлення',
      one: '1 повідомлення',
    );
    return 'Позначено як непрочитані $_temp0.';
  }

  @override
  String get markAsUnreadInProgress =>
      'Позначення повідомлень як непрочитаних…';

  @override
  String get errorMarkAsUnreadFailedTitle =>
      'Не вдалося позначити як непрочитане';

  @override
  String get today => 'Сьогодні';

  @override
  String get yesterday => 'Учора';

  @override
  String get userRoleOwner => 'Власник';

  @override
  String get userRoleAdministrator => 'Адміністратор';

  @override
  String get userRoleModerator => 'Модератор';

  @override
  String get userRoleMember => 'Учасник';

  @override
  String get userRoleGuest => 'Гість';

  @override
  String get userRoleUnknown => 'Невідомо';

  @override
  String get inboxPageTitle => 'Вхідні';

  @override
  String get recentDmConversationsPageTitle => 'Особисті повідомлення';

  @override
  String get recentDmConversationsSectionHeader => 'Особисті повідомлення';

  @override
  String get combinedFeedPageTitle => 'Об\'єднана стрічка';

  @override
  String get mentionsPageTitle => 'Згадки';

  @override
  String get starredMessagesPageTitle => 'Вибрані повідомлення';

  @override
  String get channelsPageTitle => 'Канали';

  @override
  String get mainMenuMyProfile => 'Мій профіль';

  @override
  String get channelFeedButtonTooltip => 'Стрічка каналу';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers іншим',
      one: '1 іншому',
    );
    return '$senderFullName вам і $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Закріплені';

  @override
  String get unpinnedSubscriptionsLabel => 'Відкріплені';

  @override
  String get subscriptionListNoChannels => 'Канали не знайдено';

  @override
  String get notifSelfUser => 'Ви';

  @override
  String get reactedEmojiSelfUser => 'Ви';

  @override
  String onePersonTyping(String typist) {
    return '$typist друкує…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist і $otherTypist друкують…';
  }

  @override
  String get manyPeopleTyping => 'Кілька людей друкують…';

  @override
  String get wildcardMentionAll => 'усі';

  @override
  String get wildcardMentionEveryone => 'усі';

  @override
  String get wildcardMentionChannel => 'канал';

  @override
  String get wildcardMentionStream => 'канал';

  @override
  String get wildcardMentionTopic => 'тема';

  @override
  String get wildcardMentionChannelDescription => 'Повідомити канал';

  @override
  String get wildcardMentionStreamDescription => 'Повідомити канал';

  @override
  String get wildcardMentionAllDmDescription => 'Повідомити одержувачів';

  @override
  String get wildcardMentionTopicDescription => 'Повідомити канал';

  @override
  String get messageIsEditedLabel => 'РЕДАГОВАНО';

  @override
  String get messageIsMovedLabel => 'ПЕРЕМІЩЕНО';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'ТЕМА';

  @override
  String get themeSettingDark => 'Темна';

  @override
  String get themeSettingLight => 'Світла';

  @override
  String get themeSettingSystem => 'Системна';

  @override
  String get openLinksWithInAppBrowser =>
      'Відкривати посилання за допомогою браузера додатку';

  @override
  String get pollWidgetQuestionMissing => 'Немає питання.';

  @override
  String get pollWidgetOptionsMissing =>
      'У цьому опитуванні ще немає варіантів.';

  @override
  String get experimentalFeatureSettingsPageTitle => 'Експериментальні функції';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Ці опції вмикають функції, які ще розробляються та не готові. Вони можуть не працювати та викликати проблеми в інших місцях додатку.\n\nМетою цих налаштувань є експериментування людьми, що працюють над розробкою Zulip.';

  @override
  String get errorNotificationOpenTitle => 'Не вдалося відкрити сповіщення';

  @override
  String get errorNotificationOpenAccountMissing =>
      'Обліковий запис, пов’язаний із цим сповіщенням, більше не існує.';

  @override
  String get errorReactionAddingFailedTitle => 'Не вдалося додати реакцію';

  @override
  String get errorReactionRemovingFailedTitle => 'Не вдалося видалити реакцію';

  @override
  String get emojiReactionsMore => 'більше';

  @override
  String get emojiPickerSearchEmoji => 'Пошук емодзі';

  @override
  String get noEarlierMessages => 'Немає попередніх повідомлень';

  @override
  String get scrollToBottomTooltip => 'Прокрутити вниз';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
