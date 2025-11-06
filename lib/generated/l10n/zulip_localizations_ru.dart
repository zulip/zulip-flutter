// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class ZulipLocalizationsRu extends ZulipLocalizations {
  ZulipLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get aboutPageTitle => 'О Zulip';

  @override
  String get aboutPageAppVersion => 'Версия приложения';

  @override
  String get aboutPageOpenSourceLicenses => 'Лицензии открытого исходного кода';

  @override
  String get aboutPageTapToView => 'Нажмите для просмотра';

  @override
  String get upgradeWelcomeDialogTitle =>
      'Добро пожаловать в новое приложение Zulip!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Вы найдете привычные возможности в более быстром и легком приложении.';

  @override
  String get upgradeWelcomeDialogLinkText => 'Ознакомьтесь с анонсом в блоге!';

  @override
  String get upgradeWelcomeDialogDismiss => 'Приступим';

  @override
  String get chooseAccountPageTitle => 'Выберите учетную запись';

  @override
  String get settingsPageTitle => 'Настройки';

  @override
  String get switchAccountButton => 'Сменить учетную запись';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Ваша учетная запись на $url загружается медленно.';
  }

  @override
  String get tryAnotherAccountButton => 'Попробовать другую учетную запись';

  @override
  String get chooseAccountPageLogOutButton => 'Выход из системы';

  @override
  String get logOutConfirmationDialogTitle => 'Выйти из системы?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Чтобы использовать эту учетную запись в будущем, вам придется заново ввести URL-адрес вашей организации и информацию о вашей учетной записи.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Выйти';

  @override
  String get chooseAccountButtonAddAnAccount => 'Добавить учетную запись';

  @override
  String get navButtonAllChannels => 'Все каналы';

  @override
  String get allChannelsPageTitle => 'Все каналы';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'В этой организации нет каналов, которые вы можете просматривать.';

  @override
  String get profileButtonSendDirectMessage => 'Отправить личное сообщение';

  @override
  String get errorCouldNotShowUserProfile =>
      'Не удалось показать профиль пользователя.';

  @override
  String get permissionsNeededTitle => 'Требуются разрешения';

  @override
  String get permissionsNeededOpenSettings => 'Открыть настройки';

  @override
  String get permissionsDeniedCameraAccess =>
      'Для загрузки изображения, пожалуйста, предоставьте Zulip дополнительные разрешения в настройках.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Для загрузки файлов, пожалуйста, предоставьте Zulip дополнительные разрешения в настройках.';

  @override
  String get actionSheetOptionSubscribe => 'Подписаться';

  @override
  String get subscribeFailedTitle => 'Подписаться не удалось';

  @override
  String get actionSheetOptionMarkChannelAsRead =>
      'Отметить канал как прочитанный';

  @override
  String get actionSheetOptionCopyChannelLink => 'Скопировать ссылку на канал';

  @override
  String get actionSheetOptionListOfTopics => 'Список тем';

  @override
  String get actionSheetOptionChannelFeed => 'Лента канала';

  @override
  String get actionSheetOptionUnsubscribe => 'Отписаться';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Отменить подписку на $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Если вы покинете этот канал, вы не сможете к нему присоединиться.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Отписаться';

  @override
  String get unsubscribeFailedTitle => 'Не удалось отписаться';

  @override
  String get actionSheetOptionMuteTopic => 'Заглушить тему';

  @override
  String get actionSheetOptionUnmuteTopic => 'Включить оповещения темы';

  @override
  String get actionSheetOptionFollowTopic => 'Отслеживать тему';

  @override
  String get actionSheetOptionUnfollowTopic => 'Не отслеживать тему';

  @override
  String get actionSheetOptionResolveTopic => 'Поставить отметку \"решено\"';

  @override
  String get actionSheetOptionUnresolveTopic => 'Снять отметку \"решено\"';

  @override
  String get errorResolveTopicFailedTitle =>
      'Не удалось отметить тему как решенную';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Не удалось отметить тему как нерешенную';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Посмотреть отреагировавших';

  @override
  String get seeWhoReactedSheetNoReactions => 'На это сообщение нет реакций.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Эмодзи-реакции (всего: $num)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num голосов',
      many: '$num голосов',
      few: '$num голоса',
      one: '1 голос',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Голоса за $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts =>
      'Посмотреть подтверждения прочтения';

  @override
  String get actionSheetReadReceipts => 'Подтверждения прочтения';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Это сообщение было <z-link>прочитано</z-link> $count пользователями:',
      one:
          'Это сообщение было <z-link>прочитано</z-link> $count пользователем:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Это сообщение еще никто не прочитал.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Не удалось загрузить подтверждения прочтения.';

  @override
  String get actionSheetOptionCopyMessageText => 'Скопировать текст сообщения';

  @override
  String get actionSheetOptionCopyMessageLink =>
      'Скопировать ссылку на сообщение';

  @override
  String get actionSheetOptionMarkAsUnread =>
      'Отметить как непрочитанные начиная отсюда';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Скрыть заглушенное сообщение';

  @override
  String get actionSheetOptionShare => 'Поделиться';

  @override
  String get actionSheetOptionQuoteMessage => 'Цитировать сообщение';

  @override
  String get actionSheetOptionStarMessage => 'Отметить сообщение';

  @override
  String get actionSheetOptionUnstarMessage => 'Снять отметку с сообщения';

  @override
  String get actionSheetOptionEditMessage => 'Редактировать сообщение';

  @override
  String get actionSheetOptionDeleteMessage => 'Удалить сообщение';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Удалить сообщение?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'При удалении сообщения оно навсегда пропадет для всех.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Удалить';

  @override
  String get errorDeleteMessageFailedTitle => 'Не удалось удалить сообщение';

  @override
  String get actionSheetOptionMarkTopicAsRead =>
      'Отметить тему как прочитанную';

  @override
  String get actionSheetOptionCopyTopicLink => 'Скопировать ссылку на тему';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Что-то пошло не так';

  @override
  String get errorWebAuthOperationalError => 'Произошла непредвиденная ошибка.';

  @override
  String get errorAccountLoggedInTitle => 'Вход в учетную запись уже выполнен';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Учетная запись $email на $server уже присутствует.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Не удалось извлечь источник сообщения.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Не удалось получить доступ к загруженному файлу';

  @override
  String get errorCopyingFailed => 'Сбой копирования';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Не удалось загрузить файл: $filename';
  }

  @override
  String filenameAndSizeInMiB(String filename, String size) {
    return '$filename: $size МиБ';
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
      other: '$num файлов',
      one: 'файла',
    );
    return 'Размер $_temp0 превышает предел для сервера $maxFileUploadSizeMib МиБ, загрузка невозможна:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'файлов',
      one: 'файла',
    );
    return 'Слишком большой размер $_temp0';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Неверный ввод';

  @override
  String get errorLoginFailedTitle => 'Не удалось войти в систему';

  @override
  String get errorMessageNotSent => 'Сообщение не отправлено';

  @override
  String get errorMessageEditNotSaved => 'Сообщение не сохранено';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Не удалось подключиться к серверу:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Нет связи с сервером';

  @override
  String get errorMessageDoesNotSeemToExist =>
      'Это сообщение, похоже, отсутствует.';

  @override
  String get errorQuotationFailed => 'Цитирование не удалось';

  @override
  String errorServerMessage(String message) {
    return 'Ответ сервера:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Ошибка подключения к Zulip. Повторяем попытку…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Ошибка подключения к Zulip на $serverUrl. Повторим попытку:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Ошибка обработки события Zulip. Повторная попытка соединения…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Ошибка обработки события Zulip от $serverUrl; повторим попытку.\n\nОшибка: $error\n\nСобытие: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Не удалось открыть ссылку';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Не удалось открыть ссылку: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Не удалось заглушить тему';

  @override
  String get errorUnmuteTopicFailed => 'Не удалось включить оповещения темы';

  @override
  String get errorFollowTopicFailed => 'Не удалось начать отслеживать тему';

  @override
  String get errorUnfollowTopicFailed =>
      'Не удалось прекратить отслеживать тему';

  @override
  String get errorSharingFailed => 'Не удалось поделиться';

  @override
  String get errorStarMessageFailedTitle => 'Не удалось отметить сообщение';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Не удалось снять отметку с сообщения';

  @override
  String get errorCouldNotEditMessageTitle => 'Сбой редактирования';

  @override
  String get successLinkCopied => 'Ссылка скопирована';

  @override
  String get successMessageTextCopied => 'Текст сообщения скопирован';

  @override
  String get successMessageLinkCopied => 'Ссылка на сообщение скопирована';

  @override
  String get successTopicLinkCopied => 'Ссылка на тему скопирована';

  @override
  String get successChannelLinkCopied => 'Ссылка на канал скопирована';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Нельзя отправить сообщение отключенным пользователям.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'У вас нет права писать в этом канале.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Новые сообщения не будут отображаться автоматически.';

  @override
  String get composeBoxBannerButtonRefresh => 'Обновить';

  @override
  String get composeBoxBannerButtonSubscribe => 'Подписаться';

  @override
  String get composeBoxBannerLabelEditMessage => 'Редактирование сообщения';

  @override
  String get composeBoxBannerButtonCancel => 'Отмена';

  @override
  String get composeBoxBannerButtonSave => 'Сохранить';

  @override
  String get editAlreadyInProgressTitle => 'Редактирование недоступно';

  @override
  String get editAlreadyInProgressMessage =>
      'Редактирование уже выполняется. Дождитесь завершения.';

  @override
  String get savingMessageEditLabel => 'ЗАПИСЬ ПРАВОК…';

  @override
  String get savingMessageEditFailedLabel => 'ПРАВКИ НЕ СОХРАНЕНЫ';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Отказаться от написанного сообщения?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'При изменении сообщения текст из поля для редактирования удаляется.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'При восстановлении неотправленного сообщения содержимое поля редактирования очищается.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Сбросить';

  @override
  String get composeBoxAttachFilesTooltip => 'Прикрепить файлы';

  @override
  String get composeBoxAttachMediaTooltip => 'Прикрепить изображения или видео';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Сделать снимок';

  @override
  String get composeBoxGenericContentHint => 'Ввести сообщение';

  @override
  String get newDmSheetComposeButtonLabel => 'Написать';

  @override
  String get newDmSheetScreenTitle => 'Новое ЛС';

  @override
  String get newDmFabButtonLabel => 'Новое ЛС';

  @override
  String get newDmSheetSearchHintEmpty => 'Добавить пользователей';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Добавить ещё…';

  @override
  String get newDmSheetNoUsersFound => 'Никто не найден';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Сообщение для @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Сообщение для группы';

  @override
  String get composeBoxSelfDmContentHint => 'Написать себе записку';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Сообщение для $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Подготовка…';

  @override
  String get composeBoxSendTooltip => 'Отправить';

  @override
  String get unknownChannelName => '(неизвестный канал)';

  @override
  String get composeBoxTopicHintText => 'Тема';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Укажите тему (или оставьте “$defaultTopicName”)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Загрузка $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(загрузка сообщения $messageId)';
  }

  @override
  String get unknownUserName => '(неизвестный пользователь)';

  @override
  String get dmsWithYourselfPageTitle => 'ЛС с собой';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Вы и $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'ЛС с $others';
  }

  @override
  String get emptyMessageList => 'Здесь нет сообщений.';

  @override
  String get emptyMessageListSearch => 'Ничего не найдено.';

  @override
  String get messageListGroupYouWithYourself => 'Сообщения с собой';

  @override
  String get contentValidationErrorTooLong =>
      'Длина сообщения не должна превышать 10000 символов.';

  @override
  String get contentValidationErrorEmpty => 'Нечего отправлять!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Пожалуйста, дождитесь завершения цитирования.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Пожалуйста, дождитесь завершения загрузки.';

  @override
  String get dialogCancel => 'Отмена';

  @override
  String get dialogContinue => 'Продолжить';

  @override
  String get dialogClose => 'Закрыть';

  @override
  String get errorDialogLearnMore => 'Узнать больше';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Ошибка';

  @override
  String get snackBarDetails => 'Подробности';

  @override
  String get lightboxCopyLinkTooltip => 'Скопировать ссылку';

  @override
  String get lightboxVideoCurrentPosition => 'Место воспроизведения';

  @override
  String get lightboxVideoDuration => 'Длительность видео';

  @override
  String get loginPageTitle => 'Вход в систему';

  @override
  String get loginFormSubmitLabel => 'Войти';

  @override
  String get loginMethodDivider => 'ИЛИ';

  @override
  String signInWithFoo(String method) {
    return 'Войти с помощью $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Добавление учетной записи';

  @override
  String get loginServerUrlLabel => 'URL вашего сервера Zulip';

  @override
  String get loginHidePassword => 'Скрыть пароль';

  @override
  String get loginEmailLabel => 'Адрес почты';

  @override
  String get loginErrorMissingEmail =>
      'Пожалуйста, введите ваш адрес электронной почты.';

  @override
  String get loginPasswordLabel => 'Пароль';

  @override
  String get loginErrorMissingPassword => 'Пожалуйста, введите пароль.';

  @override
  String get loginUsernameLabel => 'Имя пользователя';

  @override
  String get loginErrorMissingUsername =>
      'Пожалуйста, введите ваше имя пользователя.';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength символов',
      many: '$maxLength символов',
      few: '$maxLength символа',
      one: '$maxLength символ',
    );
    return 'Длина темы не должна превышать $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Темы обязательны в этой организации.';

  @override
  String get errorContentNotInsertedTitle => 'Содержимое не вставлено';

  @override
  String get errorContentToInsertIsEmpty =>
      'Файл для вставки пустой, или к нему нет доступа.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url использует Zulip Server $zulipVersion, который не поддерживается. Минимальная поддерживаемая версия — Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Не удалось войти в вашу учётную запись $url. Попробуйте ещё раз или используйте другую учётную запись.';
  }

  @override
  String get errorInvalidResponse => 'Сервер отправил недопустимый ответ.';

  @override
  String get errorNetworkRequestFailed => 'Сбой сетевого запроса';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Сервер вернул некорректный ответ; HTTP-статус $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Сервер вернул некорректный ответ; HTTP-статус $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Сбой сетевого запроса: HTTP-статус $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Не удается воспроизвести видео.';

  @override
  String get serverUrlValidationErrorEmpty => 'Пожалуйста, введите URL-адрес.';

  @override
  String get serverUrlValidationErrorInvalidUrl =>
      'Пожалуйста, введите корректный URL-адрес.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Пожалуйста, введите URL-адрес сервера, а не свой email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'URL-адрес сервера должен начинаться с http:// или https://.';

  @override
  String get spoilerDefaultHeaderText => 'Спойлер';

  @override
  String get markAllAsReadLabel => 'Отметить все сообщения как прочитанные';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num сообщений',
      one: '$num сообщения',
    );
    return 'Отметка прочтения установлена для $_temp0.';
  }

  @override
  String get markAsReadInProgress => 'Помечаем сообщения как прочитанные…';

  @override
  String get errorMarkAsReadFailedTitle =>
      'Не удалось установить отметку прочтения';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num сообщений',
      one: '$num сообщения',
    );
    return 'Отметка прочтения снята для $_temp0.';
  }

  @override
  String get markAsUnreadInProgress => 'Помечаем сообщения как непрочитанные…';

  @override
  String get errorMarkAsUnreadFailedTitle =>
      'Не удалось снять отметку прочтения';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get userActiveNow => 'На связи';

  @override
  String get userIdle => 'Бездействует';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минут',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минуту',
    );
    return 'Был/а на связи $_temp0 назад';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours часов',
      many: '$hours часов',
      few: '$hours часа',
      one: '$hours час',
    );
    return 'Был/а на связи $_temp0 назад';
  }

  @override
  String get userActiveYesterday => 'Был/а на связи вчера';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дней',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Был/а на связи $_temp0 назад';
  }

  @override
  String userActiveDate(String date) {
    return 'Был/а на связи $date';
  }

  @override
  String get userNotActiveInYear => 'Не выходил/а на связь за последний год';

  @override
  String get invisibleMode => 'Режим невидимости';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Не удалось включить режим невидимости. Повторите попытку позже.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Не удалось отключить режим невидимости. Повторите попытку позже.';

  @override
  String get userRoleOwner => 'Владелец';

  @override
  String get userRoleAdministrator => 'Администратор';

  @override
  String get userRoleModerator => 'Модератор';

  @override
  String get userRoleMember => 'Участник';

  @override
  String get userRoleGuest => 'Гость';

  @override
  String get userRoleUnknown => 'Неизвестно';

  @override
  String get statusButtonLabelStatusSet => 'Статус';

  @override
  String get statusButtonLabelStatusUnset => 'Установить статус';

  @override
  String get noStatusText => 'Нет текста статуса';

  @override
  String get setStatusPageTitle => 'Установить статус';

  @override
  String get statusClearButtonLabel => 'Очистить';

  @override
  String get statusSaveButtonLabel => 'Сохранить';

  @override
  String get statusTextHint => 'Ваш статус';

  @override
  String get userStatusBusy => 'В делах';

  @override
  String get userStatusInAMeeting => 'На встрече';

  @override
  String get userStatusCommuting => 'В дороге';

  @override
  String get userStatusOutSick => 'Болею';

  @override
  String get userStatusVacationing => 'В отпуске';

  @override
  String get userStatusWorkingRemotely => 'Работаю дистанционно';

  @override
  String get userStatusAtTheOffice => 'В офисе';

  @override
  String get updateStatusErrorTitle =>
      'Ошибка обновления статуса пользователя. Попробуйте ещё раз.';

  @override
  String get searchMessagesPageTitle => 'Поиск';

  @override
  String get searchMessagesHintText => 'Поиск';

  @override
  String get searchMessagesClearButtonTooltip => 'Очистить';

  @override
  String get inboxPageTitle => 'Входящие';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'У вас нет непрочитанных входящих сообщений.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Используйте кнопки внизу для просмотра объединенной ленты или списка каналов.';

  @override
  String get recentDmConversationsPageTitle => 'Личные сообщения';

  @override
  String get recentDmConversationsSectionHeader => 'Личные сообщения';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'У вас пока нет личных сообщений!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Почему бы не начать общение?';

  @override
  String get combinedFeedPageTitle => 'Объединенная лента';

  @override
  String get mentionsPageTitle => 'Упоминания';

  @override
  String get starredMessagesPageTitle => 'Отмеченные сообщения';

  @override
  String get channelsPageTitle => 'Каналы';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Вы пока не подписаны ни на один канал.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Вы можете просмотреть <z-link>$allChannelsPageTitle</z-link> и присоединиться к некоторым из них.';
  }

  @override
  String get sharePageTitle => 'Поделиться';

  @override
  String get mainMenuMyProfile => 'Мой профиль';

  @override
  String get topicsButtonTooltip => 'Темы';

  @override
  String get channelFeedButtonTooltip => 'Лента канала';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers другим',
      one: '$numOthers другому',
    );
    return '$senderFullName вам и ещё $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Закреплены';

  @override
  String get unpinnedSubscriptionsLabel => 'Откреплены';

  @override
  String get notifSelfUser => 'Вы';

  @override
  String get reactedEmojiSelfUser => 'Вы';

  @override
  String get reactionChipsLabel => 'Реакции';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Вы и еще $otherUsersCount человек',
      many: 'Вы и еще $otherUsersCount человек',
      few: 'Вы и еще $otherUsersCount человека',
      one: 'Вы и еще $otherUsersCount человек',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist набирает сообщение…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist и $otherTypist набирают сообщения…';
  }

  @override
  String get manyPeopleTyping => 'Несколько человек набирают сообщения…';

  @override
  String get wildcardMentionAll => 'все';

  @override
  String get wildcardMentionEveryone => 'каждый';

  @override
  String get wildcardMentionChannel => 'канал';

  @override
  String get wildcardMentionStream => 'канал';

  @override
  String get wildcardMentionTopic => 'тема';

  @override
  String get wildcardMentionChannelDescription => 'Оповестить канал';

  @override
  String get wildcardMentionStreamDescription => 'Оповестить канал';

  @override
  String get wildcardMentionAllDmDescription => 'Оповестить получателей';

  @override
  String get wildcardMentionTopicDescription => 'Оповестить тему';

  @override
  String get messageIsEditedLabel => 'ИЗМЕНЕНО';

  @override
  String get messageIsMovedLabel => 'ПЕРЕМЕЩЕНО';

  @override
  String get messageNotSentLabel => 'СООБЩЕНИЕ НЕ ОТПРАВЛЕНО';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'РЕЖИМ';

  @override
  String get themeSettingDark => 'Темный';

  @override
  String get themeSettingLight => 'Светлый';

  @override
  String get themeSettingSystem => 'Системный';

  @override
  String get openLinksWithInAppBrowser => 'Открывать ссылки внутри приложения';

  @override
  String get pollWidgetQuestionMissing => 'Нет вопроса.';

  @override
  String get pollWidgetOptionsMissing => 'В опросе пока нет вариантов ответа.';

  @override
  String get initialAnchorSettingTitle => 'Где открывать ленту сообщений';

  @override
  String get initialAnchorSettingDescription =>
      'Можно открывать ленту сообщений на первом непрочитанном сообщении или на самом новом.';

  @override
  String get initialAnchorSettingFirstUnreadAlways =>
      'Первое непрочитанное сообщение';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Первое непрочитанное сообщение при просмотре бесед, самое новое в остальных местах';

  @override
  String get initialAnchorSettingNewestAlways => 'Самое новое сообщение';

  @override
  String get markReadOnScrollSettingTitle =>
      'Отмечать сообщения как прочитанные при прокрутке';

  @override
  String get markReadOnScrollSettingDescription =>
      'При прокрутке сообщений автоматически отмечать их как прочитанные?';

  @override
  String get markReadOnScrollSettingAlways => 'Всегда';

  @override
  String get markReadOnScrollSettingNever => 'Никогда';

  @override
  String get markReadOnScrollSettingConversations =>
      'Только при просмотре бесед';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Сообщения будут автоматически помечаться как прочитанные только при просмотре отдельной темы или личной беседы.';

  @override
  String get experimentalFeatureSettingsPageTitle =>
      'Экспериментальные функции';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Эти параметры включают возможности, которые все ещё находятся в разработке и не готовы. Они могут не работать и вызывать проблемы в других местах приложения.\n\nЦель этих настроек — экспериментирование людьми, работающими над разработкой Zulip.';

  @override
  String get errorNotificationOpenTitle => 'Не удалось открыть оповещения';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Учетная запись, связанная с этим уведомлением, не найдена.';

  @override
  String get errorReactionAddingFailedTitle => 'Не удалось добавить реакцию';

  @override
  String get errorReactionRemovingFailedTitle => 'Не удалось удалить реакцию';

  @override
  String get errorSharingTitle => 'Не удалось поделиться содержанием';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'Не выполнен вход с учетной записью. Пожалуйста, войдите в систему и повторите попытку.';

  @override
  String get emojiReactionsMore => 'ещё';

  @override
  String get emojiPickerSearchEmoji => 'Поиск эмодзи';

  @override
  String get noEarlierMessages => 'Предшествующих сообщений нет';

  @override
  String get revealButtonLabel => 'Показать сообщение';

  @override
  String get mutedUser => 'Заглушенный пользователь';

  @override
  String get scrollToBottomTooltip => 'Пролистать вниз';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
