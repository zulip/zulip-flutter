// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ZulipLocalizationsFr extends ZulipLocalizations {
  ZulipLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get aboutPageTitle => 'À propos de Zulip';

  @override
  String get aboutPageAppVersion => 'Version de l\'application';

  @override
  String get aboutPageOpenSourceLicenses => 'Licences de logiciel libre';

  @override
  String get aboutPageTapToView => 'Toucher pour voir';

  @override
  String get upgradeWelcomeDialogTitle =>
      'Bienvenue dans la nouvelle application Zulip !';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Vous retrouverez une expérience familière dans un logiciel plus rapide et plus élégant.';

  @override
  String get upgradeWelcomeDialogLinkText =>
      'Allez voir les articles sur le blog des annonces !';

  @override
  String get upgradeWelcomeDialogDismiss => 'Allons-y';

  @override
  String get chooseAccountPageTitle => 'Choisir un compte';

  @override
  String get settingsPageTitle => 'Paramètres';

  @override
  String get switchAccountButton => 'Changer de compte';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Votre compte à $url prend du temps à se charger.';
  }

  @override
  String get tryAnotherAccountButton => 'Essayer un autre compte';

  @override
  String get chooseAccountPageLogOutButton => 'Déconnexion';

  @override
  String get logOutConfirmationDialogTitle => 'Se déconnecter?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Pour utiliser ce compte à l\'avenir, vous devrez ré-entrer l\'adresse pour votre organisation et les informations de votre compte.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Déconnexion';

  @override
  String get chooseAccountButtonAddAnAccount => 'Ajouter un compte';

  @override
  String get navButtonAllChannels => 'All channels';

  @override
  String get allChannelsPageTitle => 'All channels';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'Il n\'y a pas de canal que vous pouvez visualiser dans cette organisation.';

  @override
  String get profileButtonSendDirectMessage => 'Envoyer un message direct';

  @override
  String get errorCouldNotShowUserProfile =>
      'Impossible de montrer le profil de l\'utilisateur.';

  @override
  String get permissionsNeededTitle => 'Permissions requises';

  @override
  String get permissionsNeededOpenSettings => 'Ouvrir les préférences';

  @override
  String get permissionsDeniedCameraAccess =>
      'Pour charger une image, merci d\'accorder des autorisations supplémentaires à Zulip, dans les préférences.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Pour charger des fichiers, merci d\'accorder des autorisations supplémentaires à Zulip, dans les préférences.';

  @override
  String get actionSheetOptionSubscribe => 'S\'abonner';

  @override
  String get subscribeFailedTitle => 'Failed to subscribe';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Marquer le canal comme lu';

  @override
  String get actionSheetOptionCopyChannelLink => 'Copier le lien du canal';

  @override
  String get actionSheetOptionListOfTopics => 'Liste des sujets';

  @override
  String get actionSheetOptionChannelFeed => 'Channel feed';

  @override
  String get actionSheetOptionUnsubscribe => 'Unsubscribe';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Se désinscrire de $channelName?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Once you leave this channel, you will not be able to rejoin.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Se désinscrire';

  @override
  String get unsubscribeFailedTitle => 'Failed to unsubscribe';

  @override
  String get actionSheetOptionMuteTopic => 'Rendre le sujet silencieux';

  @override
  String get actionSheetOptionUnmuteTopic => 'Rendre le sujet non silencieux';

  @override
  String get actionSheetOptionFollowTopic => 'Suivre le sujet';

  @override
  String get actionSheetOptionUnfollowTopic => 'Ne plus suivre le sujet';

  @override
  String get actionSheetOptionResolveTopic => 'Marquer comme résolu';

  @override
  String get actionSheetOptionUnresolveTopic => 'Marquer comme non résolu';

  @override
  String get errorResolveTopicFailedTitle =>
      'Impossible de marquer le sujet comme résolu';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'Impossible de marquer le sujet comme non résolu';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Voir qui a réagi';

  @override
  String get seeWhoReactedSheetNoReactions =>
      'Aucune réaction associée à ce message.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Réactions emoji ($num total)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num votes',
      one: '1 vote',
    );
    return '$emojiName : $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Votes pour $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts => 'Voir accusés de réception';

  @override
  String get actionSheetReadReceipts => 'Accusés de réception';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ce message a été <z-link>lu</z-link> par $count personnes :',
      one: 'Ce message a été <z-link>lu</z-link> par $count personne:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Personne n\'a encore lu ce message.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Échec du chargement des accusés de réception.';

  @override
  String get actionSheetOptionCopyMessageText => 'Copier le contenu du message';

  @override
  String get actionSheetOptionCopyMessageLink => 'Copier le lien au message';

  @override
  String get actionSheetOptionMarkAsUnread => 'Marquer non lu à partir d\'ici';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Cacher à nouveau le message silencieux';

  @override
  String get actionSheetOptionShare => 'Partager';

  @override
  String get actionSheetOptionQuoteMessage => 'Citer le message';

  @override
  String get actionSheetOptionStarMessage => 'Mettre le message en favori';

  @override
  String get actionSheetOptionUnstarMessage =>
      'Retirer ce message de la liste des favoris';

  @override
  String get actionSheetOptionEditMessage => 'Modifier le message';

  @override
  String get actionSheetOptionDeleteMessage => 'Supprimer message';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Supprimer message ?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Supprimer un message de façon permanente le supprime pour tout le monde.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Supprimer';

  @override
  String get errorDeleteMessageFailedTitle =>
      'Échec de la suppression du message';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'Marquer le sujet comme lu';

  @override
  String get actionSheetOptionCopyTopicLink => 'Copier le lien sur le sujet';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Une erreur s\'est produite';

  @override
  String get errorWebAuthOperationalError =>
      'Oups, une erreur s\'est produite.';

  @override
  String get errorAccountLoggedInTitle =>
      'Vous êtes déjà connecté à ce compte.';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Le compte $email at $server figure déjà dans votre liste de comptes.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Impossible d\'atteindre le message source.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Could not access uploaded file';

  @override
  String get errorCopyingFailed => 'Échec de la copie';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Impossible de charger le fichier $filename';
  }

  @override
  String filenameAndSizeInMiB(String filename, String size) {
    return '$filename : $size MiB';
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
      other: '$num fichiers sont',
      one: 'Fichier est',
    );
    return '$_temp0 plus gros que la limite de capacité du serveur ($maxFileUploadSizeMib MO) et ne peu(ven)t pas être chargé(s) :\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Les fichier sont trop lourds',
      one: 'Le fichier est trop lourd',
    );
    return '$_temp0';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Identifiant incorrect';

  @override
  String get errorLoginFailedTitle => 'La connexion a échoué.';

  @override
  String get errorMessageNotSent => 'Le message n\'a pas pu être envoyé.';

  @override
  String get errorMessageEditNotSaved =>
      'Le message n\'a pas pu être sauvegardé.';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'La connexion au serveur a échoué :\n$url';
  }

  @override
  String get errorCouldNotConnectTitle =>
      'Impossible de se connecter au serveur';

  @override
  String get errorMessageDoesNotSeemToExist => 'Ce message est introuvable.';

  @override
  String get errorQuotationFailed => 'Échec de la citation';

  @override
  String errorServerMessage(String message) {
    return 'Message d\'erreur du serveur :\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Une erreur s\'est produite lors de la connexion au serveur. Nouvelle tentative en cours…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Une erreur s\'est produite lors de la connexion à Zulip sur $serverUrl. Nouvelle tentative imminente :\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Une erreur s\'est produite sur le serveur. Reconnexion en cours…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Une erreur s\'est produite sur le serveur $serverUrl ; tentative de reconnexion imminente.\n\nErreur : $error\n\nÉvénement : $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Impossible d\'ouvrir le lien';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Le lien suivant n\'a pas pu être ouvert : $url';
  }

  @override
  String get errorMuteTopicFailed =>
      'Le sujet n\'a pas pu être rendu silencieux';

  @override
  String get errorUnmuteTopicFailed =>
      'Impossible de ne plus mettre le sujet en sourdine';

  @override
  String get errorFollowTopicFailed => 'Échec du suivi du sujet';

  @override
  String get errorUnfollowTopicFailed =>
      'Échec de la tentative de ne plus suivre le sujet';

  @override
  String get errorSharingFailed => 'Échec du partage';

  @override
  String get errorStarMessageFailedTitle =>
      'Échec de marquage du message en favori';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Échec de la tentative d\'enlever le message des favoris';

  @override
  String get errorCouldNotEditMessageTitle =>
      'Le message n\'a pas pu être modifié';

  @override
  String get successLinkCopied => 'Lien copié';

  @override
  String get successMessageTextCopied => 'Texte du message copié';

  @override
  String get successMessageLinkCopied => 'Lien sur le message copié';

  @override
  String get successTopicLinkCopied => 'Lien sur le sujet copié';

  @override
  String get successChannelLinkCopied => 'Lien sur le canal copié';

  @override
  String get errorBannerDeactivatedDmLabel =>
      'Vous ne pouvez pas envoyer de messages aux utilisateurs désactivés.';

  @override
  String get errorBannerCannotPostInChannelLabel =>
      'Vous n\'avez pas l\'autorisation de poster sur ce canal.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'New messages will not appear automatically.';

  @override
  String get composeBoxBannerButtonRefresh => 'Refresh';

  @override
  String get composeBoxBannerButtonSubscribe => 'S\'abonner';

  @override
  String get composeBoxBannerLabelEditMessage => 'Editer le message';

  @override
  String get composeBoxBannerButtonCancel => 'Annuler';

  @override
  String get composeBoxBannerButtonSave => 'Sauvegarder';

  @override
  String get editAlreadyInProgressTitle => 'Impossible de modifier le message';

  @override
  String get editAlreadyInProgressMessage =>
      'Une modification est déjà en cours. Merci d\'attendre qu\'elle soit terminée.';

  @override
  String get savingMessageEditLabel => 'SAVING EDIT…';

  @override
  String get savingMessageEditFailedLabel => 'EDIT NOT SAVED';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Discard the message you’re writing?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'When you edit a message, the content that was previously in the compose box is discarded.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'When you restore an unsent message, the content that was previously in the compose box is discarded.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Discard';

  @override
  String get composeBoxAttachFilesTooltip => 'Attach files';

  @override
  String get composeBoxAttachMediaTooltip => 'Attach images or videos';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Take a photo';

  @override
  String get composeBoxGenericContentHint => 'Type a message';

  @override
  String get newDmSheetComposeButtonLabel => 'Rédiger';

  @override
  String get newDmSheetScreenTitle => 'New DM';

  @override
  String get newDmFabButtonLabel => 'New DM';

  @override
  String get newDmSheetSearchHintEmpty => 'Add one or more users';

  @override
  String get newDmSheetSearchHintSomeSelected => 'Add another user…';

  @override
  String get newDmSheetNoUsersFound => 'No users found';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Message @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Message group';

  @override
  String get composeBoxSelfDmContentHint => 'Write yourself a note';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Message $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'Preparing…';

  @override
  String get composeBoxSendTooltip => 'Envoyer';

  @override
  String get unknownChannelName => '(unknown channel)';

  @override
  String get composeBoxTopicHintText => 'Sujet';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Enter a topic (skip for “$defaultTopicName”)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Uploading $filename…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(loading message $messageId)';
  }

  @override
  String get unknownUserName => '(utilisateur inconnu)';

  @override
  String get dmsWithYourselfPageTitle => 'DMs with yourself';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'You and $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'DMs with $others';
  }

  @override
  String get emptyMessageList => 'There are no messages here.';

  @override
  String get emptyMessageListSearch => 'No search results.';

  @override
  String get messageListGroupYouWithYourself => 'Messages with yourself';

  @override
  String get contentValidationErrorTooLong =>
      'Message length shouldn\'t be greater than 10000 characters.';

  @override
  String get contentValidationErrorEmpty => 'You have nothing to send!';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Please wait for the quotation to complete.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Please wait for the upload to complete.';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogContinue => 'Continue';

  @override
  String get dialogClose => 'Close';

  @override
  String get errorDialogLearnMore => 'Learn more';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Error';

  @override
  String get snackBarDetails => 'Details';

  @override
  String get lightboxCopyLinkTooltip => 'Copy link';

  @override
  String get lightboxVideoCurrentPosition => 'Current position';

  @override
  String get lightboxVideoDuration => 'Video duration';

  @override
  String get loginPageTitle => 'Log in';

  @override
  String get loginFormSubmitLabel => 'Log in';

  @override
  String get loginMethodDivider => 'OR';

  @override
  String signInWithFoo(String method) {
    return 'Sign in with $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Add an account';

  @override
  String get loginServerUrlLabel => 'Your Zulip server URL';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginErrorMissingEmail => 'Please enter your email.';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginErrorMissingPassword => 'Please enter your password.';

  @override
  String get loginUsernameLabel => 'Username';

  @override
  String get loginErrorMissingUsername => 'Please enter your username.';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength characters',
      one: '1 character',
    );
    return 'Topic length shouldn\'t be greater than $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Topics are required in this organization.';

  @override
  String get errorContentNotInsertedTitle => 'Content not inserted';

  @override
  String get errorContentToInsertIsEmpty =>
      'The file to be inserted is empty or cannot be accessed.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url is running Zulip Server $zulipVersion, which is unsupported. The minimum supported version is Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Your account at $url could not be authenticated. Please try logging in again or use another account.';
  }

  @override
  String get errorInvalidResponse => 'The server sent an invalid response.';

  @override
  String get errorNetworkRequestFailed => 'Network request failed';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Server gave malformed response; HTTP status $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Server gave malformed response; HTTP status $httpStatus; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Network request failed: HTTP status $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Unable to play the video.';

  @override
  String get serverUrlValidationErrorEmpty => 'Please enter a URL.';

  @override
  String get serverUrlValidationErrorInvalidUrl => 'Please enter a valid URL.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Please enter the server URL, not your email.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'The server URL must start with http:// or https://.';

  @override
  String get spoilerDefaultHeaderText => 'Spoiler';

  @override
  String get markAllAsReadLabel => 'Mark all messages as read';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messages',
      one: '1 message',
    );
    return 'Marked $_temp0 as read.';
  }

  @override
  String get markAsReadInProgress => 'Marking messages as read…';

  @override
  String get errorMarkAsReadFailedTitle => 'Mark as read failed';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messages',
      one: '1 message',
    );
    return 'Marked $_temp0 as unread.';
  }

  @override
  String get markAsUnreadInProgress => 'Marking messages as unread…';

  @override
  String get errorMarkAsUnreadFailedTitle => 'Mark as unread failed';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get userActiveNow => 'Active now';

  @override
  String get userIdle => 'Idle';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Active $_temp0 ago';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return 'Active $_temp0 ago';
  }

  @override
  String get userActiveYesterday => 'Active yesterday';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Active $_temp0 ago';
  }

  @override
  String userActiveDate(String date) {
    return 'Active $date';
  }

  @override
  String get userNotActiveInYear => 'Not active in the last year';

  @override
  String get invisibleMode => 'Invisible mode';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Error turning on invisible mode. Please try again.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Error turning off invisible mode. Please try again.';

  @override
  String get userRoleOwner => 'Owner';

  @override
  String get userRoleAdministrator => 'Administrator';

  @override
  String get userRoleModerator => 'Moderator';

  @override
  String get userRoleMember => 'Membre';

  @override
  String get userRoleGuest => 'Invité.e';

  @override
  String get userRoleUnknown => 'Inconnu';

  @override
  String get statusButtonLabelStatusSet => 'Statut';

  @override
  String get statusButtonLabelStatusUnset => 'Définir mon statut';

  @override
  String get noStatusText => 'Statut sans texte';

  @override
  String get setStatusPageTitle => 'Définir statut';

  @override
  String get statusClearButtonLabel => 'Effacer';

  @override
  String get statusSaveButtonLabel => 'Sauvegarder';

  @override
  String get statusTextHint => 'Votre statut';

  @override
  String get userStatusBusy => 'Occupé';

  @override
  String get userStatusInAMeeting => 'En réunion';

  @override
  String get userStatusCommuting => 'En déplacement';

  @override
  String get userStatusOutSick => 'Malade';

  @override
  String get userStatusVacationing => 'En vacances';

  @override
  String get userStatusWorkingRemotely => 'En télétravail';

  @override
  String get userStatusAtTheOffice => 'Au bureau';

  @override
  String get updateStatusErrorTitle =>
      'Erreur lors de la mise à jour du statut de l\'utilisateur. Merci de réessayer.';

  @override
  String get searchMessagesPageTitle => 'Recherche';

  @override
  String get searchMessagesHintText => 'Recherche';

  @override
  String get searchMessagesClearButtonTooltip => 'Effacer';

  @override
  String get inboxPageTitle => 'Boîte de réception';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'There are no unread messages in your inbox.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Use the buttons below to view the combined feed or list of channels.';

  @override
  String get recentDmConversationsPageTitle => 'Messages directs';

  @override
  String get recentDmConversationsSectionHeader => 'Messages directs';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'You have no direct messages yet!';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Why not start a conversation?';

  @override
  String get combinedFeedPageTitle => 'Fil groupé';

  @override
  String get mentionsPageTitle => 'Mentions';

  @override
  String get starredMessagesPageTitle => 'Messages favoris';

  @override
  String get channelsPageTitle => 'Chaînes';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'You’re not subscribed to any channels yet.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Try going to <z-link>$allChannelsPageTitle</z-link> and joining some of them.';
  }

  @override
  String get sharePageTitle => 'Partager';

  @override
  String get mainMenuMyProfile => 'Mon profil';

  @override
  String get topicsButtonTooltip => 'Sujets';

  @override
  String get channelFeedButtonTooltip => 'Fil de la chaîne';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers others',
      one: '1 other',
    );
    return '$senderFullName à vous et $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Épinglé';

  @override
  String get unpinnedSubscriptionsLabel => 'Désépingler';

  @override
  String get notifSelfUser => 'Vous';

  @override
  String get reactedEmojiSelfUser => 'Vous';

  @override
  String get reactionChipsLabel => 'Réactions';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName : $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'You and $otherUsersCount others',
      one: 'You and 1 other',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist est en train d\'écrire…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist et $otherTypist sont en train d\'écrire…';
  }

  @override
  String get manyPeopleTyping => 'Plusieurs personnes sont en train d\'écrire…';

  @override
  String get wildcardMentionAll => 'all';

  @override
  String get wildcardMentionEveryone => 'everyone';

  @override
  String get wildcardMentionChannel => 'channel';

  @override
  String get wildcardMentionStream => 'stream';

  @override
  String get wildcardMentionTopic => 'topic';

  @override
  String get wildcardMentionChannelDescription => 'Notify channel';

  @override
  String get wildcardMentionStreamDescription => 'Notify stream';

  @override
  String get wildcardMentionAllDmDescription => 'Notify recipients';

  @override
  String get wildcardMentionTopicDescription => 'Notify topic';

  @override
  String get messageIsEditedLabel => 'EDITED';

  @override
  String get messageIsMovedLabel => 'MOVED';

  @override
  String get messageNotSentLabel => 'MESSAGE NOT SENT';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'THEME';

  @override
  String get themeSettingDark => 'Dark';

  @override
  String get themeSettingLight => 'Light';

  @override
  String get themeSettingSystem => 'System';

  @override
  String get openLinksWithInAppBrowser => 'Open links with in-app browser';

  @override
  String get pollWidgetQuestionMissing => 'No question.';

  @override
  String get pollWidgetOptionsMissing => 'This poll has no options yet.';

  @override
  String get initialAnchorSettingTitle => 'Open message feeds at';

  @override
  String get initialAnchorSettingDescription =>
      'You can choose whether message feeds open at your first unread message or at the newest messages.';

  @override
  String get initialAnchorSettingFirstUnreadAlways => 'First unread message';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'First unread message in conversation views, newest message elsewhere';

  @override
  String get initialAnchorSettingNewestAlways => 'Newest message';

  @override
  String get markReadOnScrollSettingTitle => 'Mark messages as read on scroll';

  @override
  String get markReadOnScrollSettingDescription =>
      'When scrolling through messages, should they automatically be marked as read?';

  @override
  String get markReadOnScrollSettingAlways => 'Always';

  @override
  String get markReadOnScrollSettingNever => 'Never';

  @override
  String get markReadOnScrollSettingConversations =>
      'Only in conversation views';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Messages will be automatically marked as read only when viewing a single topic or direct message conversation.';

  @override
  String get experimentalFeatureSettingsPageTitle => 'Experimental features';

  @override
  String get experimentalFeatureSettingsWarning =>
      'These options enable features which are still under development and not ready. They may not work, and may cause issues in other areas of the app.\n\nThe purpose of these settings is for experimentation by people working on developing Zulip.';

  @override
  String get errorNotificationOpenTitle => 'Failed to open notification';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'The account associated with this notification could not be found.';

  @override
  String get errorReactionAddingFailedTitle => 'Adding reaction failed';

  @override
  String get errorReactionRemovingFailedTitle => 'Removing reaction failed';

  @override
  String get errorSharingTitle => 'Failed to share content';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'There is no account logged in. Please log in to an account and try again.';

  @override
  String get emojiReactionsMore => 'more';

  @override
  String get emojiPickerSearchEmoji => 'Search emoji';

  @override
  String get noEarlierMessages => 'No earlier messages';

  @override
  String get revealButtonLabel => 'Reveal message';

  @override
  String get mutedUser => 'Muted user';

  @override
  String get scrollToBottomTooltip => 'Scroll to bottom';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';
}
