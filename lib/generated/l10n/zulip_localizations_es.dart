// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ZulipLocalizationsEs extends ZulipLocalizations {
  ZulipLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get aboutPageTitle => 'Acerca de Zulip';

  @override
  String get aboutPageAppVersion => 'Versión de la App';

  @override
  String get aboutPageOpenSourceLicenses => 'Licencias de Código Abierto';

  @override
  String get aboutPageTapToView => 'Toca para ver';

  @override
  String get upgradeWelcomeDialogTitle =>
      '¡Te damos la bienvenida a la nueva app de Zulip!';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Encontrarás una experiencia familiar en un paquete más rápido y ligero.';

  @override
  String get upgradeWelcomeDialogLinkText =>
      '¡Echa un vistazo al post de anuncio en blog!';

  @override
  String get upgradeWelcomeDialogDismiss => 'Vamos';

  @override
  String get chooseAccountPageTitle => 'Escoger cuenta';

  @override
  String get settingsPageTitle => 'Ajustes';

  @override
  String get switchAccountButtonTooltip => 'Cambiar cuenta';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Tu cuenta en $url está tomando más de lo normal en cargar.';
  }

  @override
  String get tryAnotherAccountButton => 'Prueba con otra cuenta';

  @override
  String get chooseAccountPageLogOutButton => 'Cerrar sesión';

  @override
  String get logOutConfirmationDialogTitle => '¿Cerrar sesión?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Para usar esta cuenta en el futuro, tendrás que volver a introducir la URL de tu organización y la información de tu cuenta.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Salir';

  @override
  String get chooseAccountButtonAddAnAccount => 'Añadir una cuenta';

  @override
  String get navButtonAllChannels => 'Todos los canales';

  @override
  String get allChannelsPageTitle => 'Todos los canales';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'No tienes acceso a ninguno de los canales de esta organización.';

  @override
  String get profileButtonSendDirectMessage => 'Enviar mensaje directo';

  @override
  String get errorCouldNotShowUserProfile =>
      'No se pudo mostrar el perfil de usuario.';

  @override
  String get permissionsNeededTitle => 'Permisos necesarios';

  @override
  String get permissionsNeededOpenSettings => 'Abrir ajustes';

  @override
  String get permissionsDeniedCameraAccess =>
      'Para subir una imagen, concede a Zulip permisos adicionales en Ajustes.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Para subir archivos, concede a Zulip permisos adicionales en Ajustes.';

  @override
  String get actionSheetOptionSubscribe => 'Suscribirse';

  @override
  String get subscribeFailedTitle => 'Falló la suscripción';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Marcar canal como leído';

  @override
  String get actionSheetOptionCopyChannelLink => 'Copiar link al canal';

  @override
  String get actionSheetOptionListOfTopics => 'Lista de temas';

  @override
  String get actionSheetOptionChannelFeed => 'Feed del canal';

  @override
  String get actionSheetOptionUnsubscribe => 'Cancelar suscripción';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return '¿Deseas cancelar tu suscripción a $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Una vez que abandones este canal, no podrás volver a unirte.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton =>
      'Cancelar suscripción';

  @override
  String get unsubscribeFailedTitle => 'Falló la cancelación de suscripción';

  @override
  String get actionSheetOptionPinChannel => 'Fijar canal';

  @override
  String get actionSheetOptionUnpinChannel => 'Desfijar canal';

  @override
  String get errorPinChannelFailedTitle => 'Error al fijar el canal';

  @override
  String get errorUnpinChannelFailedTitle => 'Error al desfijar el canal';

  @override
  String get actionSheetOptionMuteTopic => 'Silenciar tema';

  @override
  String get actionSheetOptionUnmuteTopic => 'Dejar de silenciar el tema';

  @override
  String get actionSheetOptionFollowTopic => 'Seguir tema';

  @override
  String get actionSheetOptionUnfollowTopic => 'Dejar de seguir el tema';

  @override
  String get actionSheetOptionResolveTopic => 'Marcar como resuelto';

  @override
  String get actionSheetOptionUnresolveTopic => 'Marcar como no resuelto';

  @override
  String get errorResolveTopicFailedTitle =>
      'No se pudo marcar el tema como resuelto';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'No se pudo marcar el tema como no resuelto';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Ver reacciones';

  @override
  String get seeWhoReactedSheetNoReactions =>
      'Este mensaje no tiene reacciones.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Reacciones con emoji ($num en total)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num votos',
      one: '1 voto',
    );
    return '$emojiName: $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Votos por $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts =>
      'Ver confirmaciones de lectura';

  @override
  String get actionSheetReadReceipts => 'Confirmaciones de lectura';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Este mensaje ha sido <z-link>leído</z-link> por $count personas:',
      one:
          'Este mensaje ha sido <z-link>leído</z-link> por $count una persona:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Nadie ha leído este mensaje aún.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Falló la carga de confirmaciones de lectura.';

  @override
  String get actionSheetOptionCopyMessageText => 'Copiar texto del mensaje';

  @override
  String get actionSheetOptionCopyMessageLink => 'Copiar enlace al mensaje';

  @override
  String get actionSheetOptionMarkAsUnread => 'Marcar como no leído desde aquí';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Ocultar mensaje silenciado de nuevo';

  @override
  String get actionSheetOptionShare => 'Compartir';

  @override
  String get actionSheetOptionQuoteMessage => 'Citar mensaje';

  @override
  String get actionSheetOptionStarMessage => 'Marcar mensaje';

  @override
  String get actionSheetOptionUnstarMessage => 'Desmarcar mensaje';

  @override
  String get actionSheetOptionEditMessage => 'Editar mensaje';

  @override
  String get actionSheetOptionDeleteMessage => 'Eliminar mensaje';

  @override
  String get deleteMessageConfirmationDialogTitle => '¿Eliminar mensaje?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Eliminar un mensaje permanentemente lo elimina para todos.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Eliminar';

  @override
  String get errorDeleteMessageFailedTitle => 'No se pudo eliminar el mensaje';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Marcar tema como leído';

  @override
  String get actionSheetOptionCopyTopicLink => 'Copiar enlace al tema';

  @override
  String actionSheetTitleDm(String user) {
    return 'Mensajes directos con $user';
  }

  @override
  String get actionSheetTitleSelfDm => 'Mensajes directos contigo mismo';

  @override
  String get actionSheetTitleGroupDm => 'Mensaje directo grupal';

  @override
  String get actionSheetOptionViewProfile => 'Ver perfil';

  @override
  String get actionSheetOptionMarkDmConversationAsRead =>
      'Marcar la conversación como leída';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Algo salió mal';

  @override
  String get errorWebAuthOperationalError =>
      'Se ha producido un error inesperado.';

  @override
  String get errorAccountLoggedInTitle => 'La cuenta ya ha iniciado sesión';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'La cuenta $email en $server ya está en tu lista de cuentas.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'No se pudo obtener el origen del mensaje.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'No se pudo acceder al archivo cargado';

  @override
  String get errorCopyingFailed => 'Copia fallida';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'No se pudo cargar el archivo: $filename';
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
      other: '$num los archivos',
      one: 'El archivo es',
    );
    return '$_temp0 superan el límite del servidor de $maxFileUploadSizeMib MiB y no se cargarán:\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Files',
      one: 'File',
    );
    return '$_temp0 demasiado grandes';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Entrada inválida';

  @override
  String get errorLoginFailedTitle => 'Falló el inicio de sesión';

  @override
  String get errorMessageNotSent => 'Mensaje no enviado';

  @override
  String get errorMessageEditNotSaved => 'Mensaje no enviado';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'Error al conectar al servidor:\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Error al conectar';

  @override
  String get errorMessageDoesNotSeemToExist => 'Ese mensaje no parece existir.';

  @override
  String get errorQuotationFailed => 'Error al citar';

  @override
  String errorServerMessage(String message) {
    return 'El servidor dijo:\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Error al conectar a Zulip. Reintentando…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Error al conectar a Zulip en $serverUrl. Se volverá a intentar:\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Error al gestionar un evento de Zulip. Reintentando la conexión…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Error al gestionar un evento de Zulip desde $serverUrl; se volverá a intentar.\n\nError: $error\n\nEvento: $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'No se puede abrir el enlace';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'No se pudo abrir el enlace: $url';
  }

  @override
  String get errorMuteTopicFailed => 'Error al silenciar el tema';

  @override
  String get errorUnmuteTopicFailed =>
      'No se ha podido dejar de silenciar el tema';

  @override
  String get errorFollowTopicFailed => 'Error al seguir el tema';

  @override
  String get errorUnfollowTopicFailed => 'Error al dejar de seguir el tema';

  @override
  String get errorSharingFailed => 'Error al compartir';

  @override
  String get errorStarMessageFailedTitle => 'Error al destacar el mensaje';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Error al dejar de destacar el mensaje';

  @override
  String get errorCouldNotEditMessageTitle =>
      'No se ha podido editar el mensaje';

  @override
  String get successLinkCopied => 'Enlace copiado';

  @override
  String get successMessageTextCopied => 'Texto del mensaje copiado';

  @override
  String get successMessageLinkCopied => 'Enlace del mensaje copiado';

  @override
  String get successTopicLinkCopied => 'Enlace al tema copiado';

  @override
  String get successChannelLinkCopied => 'Enlace al canal copiado';

  @override
  String get composeBoxBannerLabelDeactivatedDmRecipient =>
      'No puedes enviar mensajes a usuarios desactivados.';

  @override
  String get composeBoxBannerLabelUnknownDmRecipient =>
      'No puedes enviar mensajes a usuarios desconocidos .';

  @override
  String get composeBoxBannerLabelCannotSendUnspecifiedReason =>
      'No puedes enviar mensajes aquí.';

  @override
  String get composeBoxBannerLabelCannotSendInChannel =>
      'No tienes permiso para publicar en este canal.';

  @override
  String get composeBoxBannerLabelUnsubscribed =>
      'Las respuestas a tus mensajes no aparecerán automáticamente.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Los mensajes nuevos no aparecerán automáticamente.';

  @override
  String get composeBoxBannerButtonRefresh => 'Actualizar';

  @override
  String get composeBoxBannerButtonSubscribe => 'Suscribirse';

  @override
  String get composeBoxBannerLabelEditMessage => 'Editar mensaje';

  @override
  String get composeBoxBannerButtonCancel => 'Cancelar';

  @override
  String get composeBoxBannerButtonSave => 'Guardar';

  @override
  String get editAlreadyInProgressTitle => 'No se ha podido editar el mensaje';

  @override
  String get editAlreadyInProgressMessage =>
      'Ya hay una edición en curso. Por favor espere a que se complete.';

  @override
  String get savingMessageEditLabel => 'GUARDANDO EDICIÓN…';

  @override
  String get savingMessageEditFailedLabel => 'EDICIÓN NO GUARDADA';

  @override
  String get discardDraftConfirmationDialogTitle =>
      '¿Descartar el mensaje que estás escribiendo?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Al editar un mensaje, el contenido que estaba anteriormente en el cuadro de redacción es descartado.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Al restaurar un mensaje no enviado, el contenido que estaba anteriormente en la caja de redacción es descartado.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Descartar';

  @override
  String get composeBoxAttachFilesTooltip => 'Adjuntar archivos';

  @override
  String get composeBoxAttachMediaTooltip => 'Adjuntar imágenes o vídeos';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Toma una foto';

  @override
  String get composeBoxGenericContentHint => 'Escribir un mensaje';

  @override
  String get newDmSheetComposeButtonLabel => 'Redactar';

  @override
  String get newDmSheetScreenTitle => 'Nuevo mensaje directo';

  @override
  String get newDmFabButtonLabel => 'Nuevo mensaje directo';

  @override
  String get newDmSheetSearchHintEmpty => 'Agrega uno o más usuarios';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Agrega otro usuario…';

  @override
  String get newDmSheetNoUsersFound => 'No se encontraron usuarios';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Mensaje a @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Mensaje a grupo';

  @override
  String get composeBoxSelfDmContentHint => 'Escríbete una nota';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Mensaje $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Preparando…';

  @override
  String get composeBoxSendTooltip => 'Enviar';

  @override
  String get unknownChannelName => '(canal desconocido)';

  @override
  String get composeBoxTopicHintText => 'Tema';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Ingresa un tema (salta para «$defaultTopicName»)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Cargando $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(cargando mensaje $messageId)';
  }

  @override
  String get unknownUserName => '(usuario desconocido)';

  @override
  String get dmsWithYourselfPageTitle => 'Mensajes directos contigo mismo';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Tú y $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'Mensajes directos con $others';
  }

  @override
  String get emptyMessageList => 'No hay mensajes aquí.';

  @override
  String get emptyMessageListCombinedFeed =>
      'No hay mensajes en tu feed combinado.';

  @override
  String get emptyMessageListChannelWithoutContentAccess =>
      'No tienes <z-link>acceso de contenido</z-link> en este canal.';

  @override
  String get emptyMessageListChannelUnavailable =>
      'Este canal no existe o no tienes permiso para verlo.';

  @override
  String get emptyMessageListSelfDmHeader =>
      '¡Aún no te has enviado ningún mensaje directo!';

  @override
  String get emptyMessageListSelfDmMessage =>
      'Usa este espacio para notas personales o para probar las funciones de Zulip.';

  @override
  String emptyMessageListDm(String person) {
    return 'Aún no tienes mensajes directos con $person.';
  }

  @override
  String emptyMessageListDmDeactivatedUser(String person) {
    return 'No tienes mensajes directos con $person.';
  }

  @override
  String get emptyMessageListDmUnknownUser =>
      'No tienes mensajes directos con este usuario.';

  @override
  String get emptyMessageListGroupDm =>
      'Aún no tienes mensajes directos con estos usuarios.';

  @override
  String get emptyMessageListGroupDmDeactivatedUser =>
      'No tienes mensajes directos con estos usuarios.';

  @override
  String get emptyMessageListDmStartConversation =>
      '¿Por qué no iniciar la conversación?';

  @override
  String get emptyMessageListMentionsHeader =>
      'Esta vista mostrará los mensajes en los que se te <z-link>mencione</z-link>.';

  @override
  String get emptyMessageListMentionsMessage =>
      'Para llamar la atención sobre un mensaje, puedes mencionar a un usuario, a un grupo, a los participantes del tema o a todos los suscriptores de un canal. Escribe @ en el cuadro de redacción y elige a quién quieres mencionar en la lista de sugerencias.';

  @override
  String get emptyMessageListStarredHeader => 'No tienes mensajes destacados.';

  @override
  String emptyMessageListStarredMessage(String button) {
    return '<z-link>Destacar</z-link> es una buena forma de llevar un registro de los mensajes importantes, como las tareas a las que tienes que volver o las referencias útiles. Para destacar un mensaje, mantenlo pulsado durante un tiempo y pulsa “$button.”';
  }

  @override
  String get emptyMessageListSearch => 'Sin resultados de búsqueda.';

  @override
  String get messageListGroupYouWithYourself => 'Mensajes contigo mismo';

  @override
  String get contentValidationErrorTooLong =>
      'La longitud del mensaje no debe superar los 10 000 caracteres.';

  @override
  String get contentValidationErrorEmpty => '¡No tienes nada que enviar!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Por favor, espera a que se complete la cita.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Por favor espera a que se complete la carga.';

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get dialogContinue => 'Continuar';

  @override
  String get dialogClose => 'Cerrar';

  @override
  String get errorDialogLearnMore => 'Aprende más';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Error';

  @override
  String get snackBarDetails => 'Detalles';

  @override
  String get lightboxCopyLinkTooltip => 'Copiar enlace';

  @override
  String get lightboxVideoCurrentPosition => 'Posición actual';

  @override
  String get lightboxVideoDuration => 'Duración del vídeo';

  @override
  String get loginPageTitle => 'Iniciar sesión';

  @override
  String get loginFormSubmitLabel => 'Iniciar sesión';

  @override
  String get loginMethodDivider => 'O';

  @override
  String get loginMethodDividerSemanticLabel =>
      'Alternativas de Inicio de Sesión';

  @override
  String signInWithFoo(String method) {
    return 'Iniciar sesión con $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Añadir una cuenta';

  @override
  String get loginRealmUrlLabel => 'URL de tu organización de Zulip';

  @override
  String get loginHidePassword => 'Ocultar contraseña';

  @override
  String get loginEmailLabel => 'Dirección de correo electrónico';

  @override
  String get loginErrorMissingEmail =>
      'Por favor introduzca su correo electrónico.';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginErrorMissingPassword => 'Por favor ingresa tu contraseña.';

  @override
  String get loginUsernameLabel => 'Nombre de usuario';

  @override
  String get loginErrorMissingUsername => 'Por favor ingresa tu usuario.';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength caracteres',
      one: '1 caracter',
    );
    return 'La longitud del tema no debe ser superior a $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Los temas son obligatorios en esta organización.';

  @override
  String get errorContentNotInsertedTitle => 'Contenido no insertado';

  @override
  String get errorContentToInsertIsEmpty =>
      'El archivo a insertar está vacío o no se puede acceder a él.';

  @override
  String errorServerVersionNotAllowedMessage(
    String url,
    String zulipVersion,
    String minAllowedZulipVersion,
  ) {
    return '$url ejecuta Zulip Server $zulipVersion, una versión que ya no es compatible. La versión mínima compatible es Zulip Server $minAllowedZulipVersion.';
  }

  @override
  String serverCompatBannerAdminMessage(String url, String zulipVersion) {
    return '$url está ejecutando el servidor Zulip $zulipVersion, que ya no es compatible. Por favor, actualiza tu servidor lo antes posible.';
  }

  @override
  String serverCompatBannerUserMessage(String url, String zulipVersion) {
    return '$url está ejecutando Zulip Server $zulipVersion, que ya no es compatible. Por favor, ponte en contacto con el administrador del servidor para informarte sobre cómo actualizarla.';
  }

  @override
  String get serverCompatBannerDismissLabel => 'Cerrar';

  @override
  String get serverCompatBannerLearnMoreLabel => 'Más información';

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'No se pudo autenticar su cuenta en $url. Intenta iniciar sesión de nuevo o usa otra cuenta.';
  }

  @override
  String get errorInvalidResponse =>
      'El servidor envió una respuesta inválida.';

  @override
  String get errorNetworkRequestFailed => 'Error en la solicitud de red';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'El servidor ha devuelto una respuesta mal formada; estado HTTP $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'El servidor ha devuelto una respuesta mal formada; estado HTTP $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Error en la solicitud de red: estado HTTP $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'No se ha podido reproducir el video.';

  @override
  String get serverUrlValidationErrorEmpty => 'Por favor introduce una URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl =>
      'Por favor introduce una URL válida.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Por favor introduce la ULR del servidor, no tu correo electrónico.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'La URL del servidor debe empezar por http://o https://.';

  @override
  String get spoilerDefaultHeaderText => 'Espóiler';

  @override
  String get markAllAsReadLabel => 'Marcar todos los mensajes como leídos';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num mensajes',
      one: '1 mensaje',
    );
    return 'Marcado ${_temp0}como leídos.';
  }

  @override
  String get markAsReadInProgress => 'Marcando mensajes como leídos…';

  @override
  String get errorMarkAsReadFailedTitle => 'Falló marcar como leído';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num mensajes',
      one: '1 mensaje',
    );
    return 'Marcar $_temp0 como no leídos.';
  }

  @override
  String get markAsUnreadInProgress =>
      'Marcando todos los mensajes como no leído…';

  @override
  String get errorMarkAsUnreadFailedTitle => 'Falló marcar como no leído';

  @override
  String markAllAsReadConfirmationDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Marcar $count + mensajes como leídos?',
      one: '¿Marcar $count + mensaje como leído?',
    );
    return '$_temp0';
  }

  @override
  String get markAllAsReadConfirmationDialogTitleNoCount =>
      '¿Marcar mensajes como leídos?';

  @override
  String get markAllAsReadConfirmationDialogMessage =>
      'Los mensajes en múltiples conversaciones podrían verse afectados.';

  @override
  String get markAllAsReadConfirmationDialogConfirmButton =>
      'Marcar como leído';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get userActiveNow => 'Activo ahora';

  @override
  String get userIdle => 'Inactivo';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '1 minuto',
    );
    return 'Activo hace $_temp0';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hour',
    );
    return 'Active hace $_temp0';
  }

  @override
  String get userActiveYesterday => 'Activo ayer';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Activo hace $_temp0';
  }

  @override
  String userActiveDate(String date) {
    return 'Activo $date';
  }

  @override
  String get userNotActiveInYear => 'No estuvo activo en el último año';

  @override
  String get invisibleMode => 'Modo invisible';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Error al activar el modo invisible. Por favor, inténtalo de nuevo.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Error al desactivar el modo invisible. Por favor, inténtalo de nuevo.';

  @override
  String get userRoleOwner => 'Propietario';

  @override
  String get userRoleAdministrator => 'Administrador';

  @override
  String get userRoleModerator => 'Moderador';

  @override
  String get userRoleMember => 'Miembro';

  @override
  String get userRoleGuest => 'Invitado';

  @override
  String get userRoleUnknown => 'Desconocido';

  @override
  String get statusButtonLabelStatusSet => 'Estado';

  @override
  String get statusButtonLabelStatusUnset => 'Establecer estado';

  @override
  String get noStatusText => 'Sin texto de estado';

  @override
  String get setStatusPageTitle => 'Establecer estado';

  @override
  String get statusClearButtonLabel => 'Borrar';

  @override
  String get statusSaveButtonLabel => 'Guardar';

  @override
  String get statusTextHint => 'Tu estado';

  @override
  String get userStatusBusy => 'Ocupado';

  @override
  String get userStatusInAMeeting => 'En una reunión';

  @override
  String get userStatusCommuting => 'En trayecto';

  @override
  String get userStatusOutSick => 'Enfermo';

  @override
  String get userStatusVacationing => 'De vacaciones';

  @override
  String get userStatusWorkingRemotely => 'Trabajando en remoto';

  @override
  String get userStatusAtTheOffice => 'En la oficina';

  @override
  String get updateStatusErrorTitle =>
      'Error al actualizar el estado del usuario. Por favor, vuelve a intentarlo.';

  @override
  String get searchMessagesPageTitle => 'Buscar';

  @override
  String get searchMessagesHintText => 'Buscar';

  @override
  String get searchMessagesClearButtonTooltip => 'Eliminar';

  @override
  String get inboxPageTitle => 'Bandeja de entrada';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'No hay mensajes sin leer en tu bandeja de entrada.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Usa los botones de abajo para ver el feed combinado o la lista de canales.';

  @override
  String get pinnedChannelsFolderName => 'Canales fijados';

  @override
  String get otherChannelsFolderName => 'Otros canales';

  @override
  String get recentDmConversationsPageTitle => 'Mensajes directos';

  @override
  String get recentDmConversationsPageShortLabel => 'Mensajes directos';

  @override
  String get recentDmConversationsSectionHeader => 'Mensajes directos';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      '¡Aún no tienes mensajes directos!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      '¿Por qué no iniciar una conversación?';

  @override
  String get combinedFeedPageTitle => 'Feed combinado';

  @override
  String get mentionsPageTitle => 'Menciones';

  @override
  String get starredMessagesPageTitle => 'Mensajes destacados';

  @override
  String get channelsPageTitle => 'Canales';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Aún no estás suscrito a ningún canal.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Intenta ir a <z-link>$allChannelsPageTitle</z-link> y unirte a algunos de ellos.';
  }

  @override
  String get shareChooseAccountModalTitle => 'Elige una cuenta';

  @override
  String get mainMenuMyProfile => 'Mi perfil';

  @override
  String get topicsButtonTooltip => 'Temas';

  @override
  String get channelFeedButtonTooltip => 'Feed del canal';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers otros',
      one: '1 otro',
    );
    return '$senderFullName para ti y $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Fijado';

  @override
  String get unpinnedSubscriptionsLabel => 'No fijado';

  @override
  String get notifSelfUser => 'Tú';

  @override
  String get reactedEmojiSelfUser => 'Tú';

  @override
  String get reactionChipsLabel => 'Reacciones';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Tú y $otherUsersCount otros',
      one: 'Tú y otra persona',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist está escribiendo…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist y $otherTypist están escribiendo…';
  }

  @override
  String get manyPeopleTyping => 'Varias personas están escribiendo…';

  @override
  String get wildcardMentionAll => 'todo';

  @override
  String get wildcardMentionEveryone => 'todos';

  @override
  String get wildcardMentionChannel => 'canal';

  @override
  String get wildcardMentionStream => 'canal';

  @override
  String get wildcardMentionTopic => 'tema';

  @override
  String get wildcardMentionChannelDescription => 'Notificar canal';

  @override
  String get wildcardMentionStreamDescription => 'Notificar canal';

  @override
  String get wildcardMentionAllDmDescription => 'Notificar destinatarios';

  @override
  String get wildcardMentionTopicDescription => 'Notificar tema';

  @override
  String get systemGroupNameEveryoneOnInternet => 'Todo el mundo en Internet';

  @override
  String get systemGroupNameEveryone => 'Todos, incluidos los invitados';

  @override
  String get systemGroupNameMembers => 'Todos, excepto los invitados';

  @override
  String get systemGroupNameFullMembers => 'Miembros completos';

  @override
  String get systemGroupNameModerators => 'Moderadores';

  @override
  String get systemGroupNameAdministrators => 'Administradores';

  @override
  String get systemGroupNameOwners => 'Propietarios';

  @override
  String get systemGroupNameNobody => 'Nadie';

  @override
  String get navBarFeedLabel => 'Feed';

  @override
  String get navBarMenuLabel => 'Menú';

  @override
  String get messageIsEditedLabel => 'EDITADO';

  @override
  String get messageIsMovedLabel => 'MOVIDO';

  @override
  String get messageNotSentLabel => 'MENSAJE NO ENVIADO';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'TEMA';

  @override
  String get themeSettingDark => 'Oscuro';

  @override
  String get themeSettingLight => 'Claro';

  @override
  String get themeSettingSystem => 'Sistema';

  @override
  String get openLinksWithInAppBrowser =>
      'Abrir enlaces con el navegador in-app';

  @override
  String get pollWidgetQuestionMissing => 'No hay pregunta.';

  @override
  String get pollWidgetOptionsMissing => 'Esta encuesta aún no tiene opciones.';

  @override
  String get initialAnchorSettingTitle => 'Abre los feeds de mensajes en';

  @override
  String get initialAnchorSettingDescription =>
      'Puedes elegir si los feeds de mensajes se abren en el primer mensaje no leído o en los mensajes más recientes.';

  @override
  String get initialAnchorSettingFirstUnreadAlways => 'Primer mensaje no leído';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'El primer mensaje no leído en las vistas de conversación, el mensaje más reciente en cualquier otro lugar';

  @override
  String get initialAnchorSettingNewestAlways => 'Mensaje más reciente';

  @override
  String get markReadOnScrollSettingTitle =>
      'Marcar todos los mensajes como leídos';

  @override
  String get markReadOnScrollSettingDescription =>
      'Al desplazarse por los mensajes, ¿deberían marcarse automáticamente como leídos?';

  @override
  String get markReadOnScrollSettingAlways => 'Siempre';

  @override
  String get markReadOnScrollSettingNever => 'Nunca';

  @override
  String get markReadOnScrollSettingConversations =>
      'Solo en vistas de conversación';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Los mensajes se marcarán automáticamente como solo lectura al ver un solo tema o una conversación por mensaje directo.';

  @override
  String get experimentalFeatureSettingsPageTitle =>
      'Funcionalidades experimentales';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Estas opciones habilitan funciones que aún están en desarrollo y no están listas. Es posible que no funcionen y que provoquen problemas en otras áreas de la aplicación.\n\nEl propósito de estos ajustes es que las personas que trabajan en el desarrollo de Zulip experimenten.';

  @override
  String get errorNotificationOpenTitle => 'No se pudo abrir la notificación';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'No se encontró la cuenta asociada a esta notificación.';

  @override
  String get errorReactionAddingFailedTitle => 'No se pudo agregar la reacción';

  @override
  String get errorReactionRemovingFailedTitle =>
      'Falló la eliminación de la reacción';

  @override
  String get errorSharingTitle => 'Falló compartir contenido';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'No hay ninguna cuenta. Inicia sesión en una cuenta e inténtalo de nuevo.';

  @override
  String get emojiReactionsMore => 'más';

  @override
  String get emojiPickerSearchEmoji => 'Buscar emoji';

  @override
  String get noEarlierMessages => 'No hay mensajes anteriores';

  @override
  String get revealButtonLabel => 'Revelar mensaje';

  @override
  String get mutedUser => 'Usuario silenciado';

  @override
  String get scrollToBottomTooltip => 'Deslizar hasta abajo';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';

  @override
  String get topicListEmptyPlaceholderHeader => 'Aún no hay temas aquí.';
}
